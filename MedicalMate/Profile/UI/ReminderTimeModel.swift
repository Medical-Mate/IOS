import Foundation
import Observation

/// `1s-3 · 알림 시간`(Figma `3663:15830`)의 상태.
///
/// **휠 하나가 전날·당일 두 시각을 함께 정한다.** 서버에는 두 값이 따로 있지만 화면이
/// 하나라서다(Android도 같다). 위 카드의 두 줄은 **읽기 전용**이다 — 시간이 확정된
/// 일정의 알림 시점은 사용자가 고를 수 없다.
@MainActor
@Observable
final class ReminderTimeModel {
    var isMorning = false
    var hour = 7
    var minute = 0

    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
    }

    var picked: ReminderTime {
        ReminderTime(hour: isMorning ? hour % 12 : (hour % 12) + 12, minute: minute)
    }

    func load() async {
        guard case .success(let settings) = await repository.reminders() else { return }
        apply(settings.beforeVisitTime)
    }

    func apply(_ time: ReminderTime) {
        isMorning = time.isMorning
        hour = time.hour12
        minute = time.minute
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }
        switch await repository.update(untimedTime: picked) {
        case .success:
            errorMessage = nil
            return true
        case .rejected, .networkUnavailable:
            errorMessage = "알림 시간을 바꾸지 못했어요."
            return false
        }
    }

    /// 아래 한 줄. "5일 진료라면 4일 · 5일 오후 7:00에 알려요".
    ///
    /// **날짜를 예로 든다** — 전날과 당일 둘 다에 걸린다는 것이 말로만은 잘 읽히지 않는다.
    nonisolated static func hint(_ time: ReminderTime, day: Int) -> String {
        "\(day)일 진료라면 \(max(day - 1, 1))일 · \(day)일 \(time.value)에 알려요"
    }
}
