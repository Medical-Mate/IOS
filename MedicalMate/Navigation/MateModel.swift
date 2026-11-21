import Foundation
import Observation

/// J 섹션 — 떠 있는 메이트 카드의 상태.
///
/// `1n-1-M2`(말하는 중 `3671:11370`) · `1n-1-M3`(답 `3671:11557`) ·
/// `1r-1-M4`(화면 이동 `3671:11741`). 세 장이 한 레이어의 세 상태다. 딤 없이 탭바 위
/// 12에 뜨고, 아래 화면은 그대로 쓸 수 있다.
///
/// **여는 길은 아직 닫혀 있다.** 호출어가 미정이라(`docs/AOS-IOS-DIFF.md` D1)
/// ``open()``을 부르는 자리가 앱에 없다. 호출어가 정해지면 듣는 쪽이 이것을 부른다.
///
/// **되돌릴 수 없는 동작은 말로 하지 않는다.** 옮기는 것과 묻는 것뿐이다.
@MainActor
@Observable
final class MateModel {
    /// 카드가 말을 끝낸 뒤 화면이 할 일.
    enum Action: Equatable {
        case tab(Tab)
        case route(Route)
        case back
    }

    private(set) var state: MMMateCard.State?
    /// 화면이 집어 가는 일. 가져간 쪽이 `nil`로 되돌린다.
    var pending: Action?

    let dictation = DictationController()
    private let appointments: AppointmentRepository
    private let calendar: Calendar

    init(appointments: AppointmentRepository, calendar: Calendar = .current) {
        self.appointments = appointments
        self.calendar = calendar
        dictation.onAutoSend = { [weak self] text in
            Task { await self?.heard(text) }
        }
        dictation.onSilentClose = { [weak self] in self?.close() }
    }

    var isOpen: Bool { state != nil }

    /// 가이드. 할 수 있는 말을 세 줄로 보인다.
    static let guides: [MMMateCard.Guide] = [
        .init(icon: .note, phrase: "배가 아파서 정리할래", meaning: "증상 정리"),
        .init(icon: .edit, phrase: "진료 끝났어", meaning: "진료 후 기록"),
        .init(icon: .calendar, phrase: "다음 진료 언제야", meaning: "일정 찾기"),
    ]

    func open() async {
        state = .listening(guides: Self.guides)
        await dictation.start()
    }

    func close() {
        dictation.stop()
        state = nil
    }

    /// 받아쓰는 동안 제목이 따라 바뀐다(`1n-1-M2`).
    func typing(_ text: String) {
        guard isOpen else { return }
        state = .speaking(text: MateCommandParser.withoutWakeEcho(text))
    }

    /// 한 마디가 끝났다.
    private func heard(_ text: String) async {
        let said = MateCommandParser.withoutWakeEcho(text)
        guard let command = MateCommandParser.command(from: said) else {
            // **못 알아들은 것을 아무 데로나 옮기지 않는다.** 들은 말을 그대로 되돌려 준다.
            state = .answer(MateModel.missed(said))
            return
        }

        if command == .nextVisit {
            state = .answer(await nextVisitAnswer())
            return
        }

        guard let action = MateModel.action(for: command) else { return }
        state = .navigated(title: MateModel.movedTitle(command), hint: MateModel.movedHint(command))
        pending = action
    }

    /// 다음 진료 답. "9월 25일 (금) 오전 10:30,\n서울OO병원 내과 재진이에요".
    private func nextVisitAnswer() async -> String {
        guard case .success(let list) = await appointments.upcoming(),
              let next = list.compactMap(AppointmentMapping.appointment(from:))
                  .sorted(by: { $0.on < $1.on })
                  .first
        else {
            return MateModel.noNextVisit
        }
        return MateModel.answer(for: next, calendar: calendar)
    }

    // MARK: - 문구

    static let noNextVisit = "잡아 둔 진료가 없어요"

    nonisolated static func missed(_ said: String) -> String {
        said.isEmpty ? "잘 못 알아들었어요" : "\"\(said)\", 잘 못 알아들었어요"
    }

    nonisolated static func answer(for appointment: Appointment, calendar: Calendar) -> String {
        let day = CalendarMonth.dayTitle(appointment.on, calendar: calendar)
        let time = appointment.time?.label
        let head = [day, time].compactMap(\.self).joined(separator: " ")
        let title = appointment.title
        // 제목이 비면 날짜만 적는다. 지어내지 않는다.
        return title.isEmpty ? "\(head)예요" : "\(head),\n\(title)이에요"
    }

    /// 어디로 갈지. **묻는 말(`nextVisit`)은 옮기지 않는다.**
    nonisolated static func action(for command: MateCommand) -> Action? {
        switch command {
        case .home: .tab(.home)
        case .calendar: .tab(.calendar)
        case .record: .tab(.record)
        case .profile: .route(.myProfile)
        case .back: .back
        case .intake: .route(.intake(sessionId: nil))
        case .visitRecord: .route(.hospitalPick)
        case .briefCards: .route(.briefCardList)
        case .scheduleAdd: .route(.scheduleAdd(date: nil))
        case .resume: .tab(.home)
        case .nextVisit: nil
        }
    }

    /// 옮긴 뒤의 제목. **캘린더만 시안에 있고**(`1r-1-M4`) 나머지는 Android 문구를 따랐다
    /// (COMPONENT-MAP 3장 #26).
    nonisolated static func movedTitle(_ command: MateCommand) -> String {
        switch command {
        case .calendar: "캘린더로 옮겼어요"
        case .home: "홈으로 왔어요"
        case .record: "기록을 열었어요"
        case .profile: "내 정보를 열었어요"
        case .back: "앞 화면으로 돌아갔어요"
        case .intake: "증상 정리를 시작할게요"
        case .visitRecord: "진료 후 기록을 시작할게요"
        case .briefCards: "브리핑 카드 목록을 열었어요"
        case .scheduleAdd: "일정 추가를 열었어요"
        case .resume: "하던 정리를 이어서 할게요"
        case .nextVisit: ""
        }
    }

    /// 둘째 줄. **시안이 적어 둔 것은 캘린더 하나뿐이라** 나머지는 비운다.
    nonisolated static func movedHint(_ command: MateCommand) -> String? {
        command == .calendar ? "날짜를 말하면 그 날을 열어드려요" : nil
    }
}
