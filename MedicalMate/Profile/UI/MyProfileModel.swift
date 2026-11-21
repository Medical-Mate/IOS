import Foundation
import Observation
import UserNotifications

/// `1s-1 · 내 정보 · 알림 설정`(Figma `3663:15766`)의 상태.
///
/// 프로필 · 건강 정보 요약 · 알림 · 메이트 · 계정 · 앱 정보 여섯 덩이다.
/// `GET /api/me/health-profile` 한 번으로 앞의 둘이 채워지고 알림은
/// `GET /api/me/settings`에서 온다.
@MainActor
@Observable
final class MyProfileModel {
    private(set) var profile = HealthProfile()
    private(set) var reminders = ReminderSettings()
    /// **휴대폰 알림이 꺼져 있으면** 카드 아래에 Notice가 선다.
    private(set) var isSystemNotificationOff = false
    private(set) var isWorking = false
    private(set) var errorMessage: String?

    /// "헤이 메이트로 부르기". **기기 기능이라 서버에 두지 않는다.**
    /// 호출어 자체는 아직 미정이라(D1) 값만 기억한다.
    var isWakeWordOn: Bool {
        didSet { WakeWordSetting.isOn = isWakeWordOn }
    }

    private let health: HealthProfileRepository
    private let settings: SettingsRepository

    /// 설정이 바뀌면 걸린 알림을 다시 맞추는 쪽.
    private let reminderScheduling: VisitReminders?

    init(
        health: HealthProfileRepository,
        settings: SettingsRepository,
        reminderScheduling: VisitReminders? = nil
    ) {
        self.health = health
        self.settings = settings
        self.reminderScheduling = reminderScheduling
        self.isWakeWordOn = WakeWordSetting.isOn
    }

    func load() async {
        if case .success(let profile) = await health.profile() { self.profile = profile }
        if case .success(let reminders) = await settings.reminders() { self.reminders = reminders }
        isSystemNotificationOff = await Self.isSystemNotificationOff()
    }

    /// 토글은 누르는 순간 반영된다. **실패하면 되돌린다** — 꺼진 줄 알고 나갔는데
    /// 서버가 켜진 채라면 알림이 간다.
    func setBeforeVisit(_ isOn: Bool) async {
        if isOn { await askNotificationPermission() }
        let previous = reminders.beforeVisit
        reminders.beforeVisit = isOn
        await apply { await settings.update(beforeVisit: isOn) } revert: {
            self.reminders.beforeVisit = previous
        }
    }

    func setAfterVisit(_ isOn: Bool) async {
        if isOn { await askNotificationPermission() }
        let previous = reminders.afterVisit
        reminders.afterVisit = isOn
        await apply { await settings.update(afterVisit: isOn) } revert: {
            self.reminders.afterVisit = previous
        }
    }

    private func apply(
        _ call: () async -> ApiResult<ReminderSettings>,
        revert: @escaping () -> Void
    ) async {
        isWorking = true
        defer { isWorking = false }
        switch await call() {
        case .success(let settings):
            reminders = settings
            errorMessage = nil
            // **저장이 끝나야 다시 건다.** 끄면 걸린 것이 지워지고 켜면 다가오는
            // 일정으로 다시 걸린다.
            await reminderScheduling?.refresh()
        case .rejected, .networkUnavailable:
            revert()
            errorMessage = "설정을 바꾸지 못했어요."
            // **실패하면 예약을 건드리지 않는다.** 서버 값이 그대로이므로 걸린 것도
            // 그대로가 맞다.
        }
    }

    // MARK: - 화면 값

    /// 아바타의 한 글자. **서버가 "김OO"처럼 가려서 준다.**
    ///
    /// **이름이 없으면 글자도 없다.** 카카오 동의를 거부한 계정이 그렇고 빈 동그라미가
    /// 그려진다 — 아무 글자나 채우면 그것이 이름의 첫 자로 읽힌다.
    nonisolated static func initial(_ name: String?) -> String {
        guard let first = name?.trimmingCharacters(in: .whitespaces).first else { return "" }
        return String(first)
    }

    /// "1994년생 · 여". **없는 것은 적지 않는다** — 카카오 동의를 거부한 계정은 빈 채로 온다.
    nonisolated static func birthLine(year: Int?, sex: String?) -> String {
        [year.map { "\($0)년생" }, sexLabel(sex)]
            .compactMap(\.self)
            .joined(separator: " · ")
    }

    /// 서버의 `UNSPECIFIED`는 적지 않는다. "밝히지 않음"을 적을 자리가 시안에 없다.
    nonisolated static func sexLabel(_ sex: String?) -> String? {
        switch sex {
        case "FEMALE": "여"
        case "MALE": "남"
        default: nil
        }
    }

    /// 건강 정보 요약 한 줄. **비어 있는 까닭을 그대로 적는다** —
    /// "없어요"와 "잘 모르겠어요"는 처방이 달라지는 값이다.
    nonisolated static func summary(_ field: HealthField) -> String {
        if !field.items.isEmpty { return field.items.joined(separator: " · ") }
        return field.status == .absent ? "없어요" : "잘 모르겠어요"
    }

    /// "확정시 24시간 전, 미정이면 전날 오후 7시".
    nonisolated static func beforeVisitDescription(_ time: ReminderTime) -> String {
        "확정시 24시간 전, 미정이면 전날 \(time.words)"
    }

    /// "진료 2시간 뒤, 미정이면 당일 오후 7시".
    nonisolated static func afterVisitDescription(_ time: ReminderTime) -> String {
        "진료 2시간 뒤, 미정이면 당일 \(time.words)"
    }

    /// 켤 때 한 번 묻는다.
    ///
    /// **앱을 열자마자 묻지 않는다.** 왜 필요한지 모르는 채로 보는 권한 창은 거절되기
    /// 쉽고, 한 번 거절하면 설정에서 직접 켜야 한다. 토글을 켜는 순간이 그 까닭이 가장
    /// 분명한 자리다. 이미 정해진 뒤에는 시스템이 창을 띄우지 않는다.
    private func askNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
        isSystemNotificationOff = await Self.isSystemNotificationOff()
    }

    private static func isSystemNotificationOff() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings()
            .authorizationStatus
        return status == .denied
    }
}

/// "헤이 메이트로 부르기"의 값. **기기 설정이라 서버에 두지 않는다.**
enum WakeWordSetting {
    private static let key = "wakeWordEnabled"

    static var isOn: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
