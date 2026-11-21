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
        // 받아쓰기가 스스로 끝나도 카드는 닫지 않는다. 대화가 이어지는 자리라
        // 다시 열고, **들린 것이 없이 `idleTimeout`이 지났을 때만** 닫는다.
        dictation.onSilentClose = { [weak self] in
            Task { await self?.silence() }
        }
    }

    var isOpen: Bool { state != nil }

    /// 이만큼 아무것도 들리지 않으면 닫는다. **말하는 중의 글도 들린 것으로 친다.**
    static let idleTimeout: Double = 12

    /// 가이드. 할 수 있는 말을 세 줄로 보인다.
    static let guides: [MMMateCard.Guide] = [
        .init(icon: .note, phrase: "배가 아파서 정리할래", meaning: "증상 정리"),
        .init(icon: .edit, phrase: "진료 끝났어", meaning: "진료 후 기록"),
        .init(icon: .calendar, phrase: "다음 진료 언제야", meaning: "일정 찾기")
    ]

    /// 마지막으로 들린 때. 말하는 중의 글도 들린 것으로 친다.
    private var lastHeard = Date.distantPast

    func open() async {
        state = .listening(guides: Self.guides)
        lastHeard = Date()
        await dictation.start()
    }

    /// 받아쓰기가 조용히 끝났다.
    private func silence() async {
        guard isOpen else { return }
        if Date().timeIntervalSince(lastHeard) >= Self.idleTimeout {
            close()
            return
        }
        await dictation.start()
    }

    func close() {
        dictation.stop()
        state = nil
    }

    /// 받아쓰는 동안 제목이 따라 바뀐다(`1n-1-M2`).
    func typing(_ text: String) {
        guard isOpen else { return }
        lastHeard = Date()
        state = .speaking(text: MateCommandParser.withoutWakeEcho(text))
    }

    /// 한 마디가 끝났다.
    ///
    /// **한 마디를 처리해도 닫지 않는다.** 한 흐름을 말로 끝까지 하려면 단계마다 다시
    /// 부르지 않아야 한다. 닫히는 것은 정해진 경우뿐이다 — "그만"이라고 하거나, 닫기를
    /// 누르거나, ``idleTimeout`` 동안 아무것도 들리지 않을 때다.
    private func heard(_ text: String) async {
        lastHeard = Date()
        let said = MateCommandParser.withoutWakeEcho(text)
        // 묻는 말 속의 "그만"은 닫자는 말이 아니다.
        if MateWords.isStop(said) {
            close()
            return
        }
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
                  .min(by: { $0.on < $1.on })
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
        // 표의 값이 `Action?`이라 꺼내면 두 겹이다. 한 겹을 벗겨 돌려준다.
        guard let action = actions[command] else { return nil }
        return action
    }

    /// 명령이 가리키는 곳. **묻는 말은 없다** — `switch`가 아니라 표로 둔다.
    private nonisolated static let actions: [MateCommand: Action?] = [
        .home: .tab(.home),
        .calendar: .tab(.calendar),
        .record: .tab(.record),
        .profile: .route(.myProfile),
        .back: .back,
        .intake: .route(.intake(sessionId: nil)),
        .visitRecord: .route(.hospitalPick),
        .briefCards: .route(.briefCardList),
        .scheduleAdd: .route(.scheduleAdd(date: nil)),
        .resume: .tab(.home),
        .nextVisit: Action?.none
    ]

    /// 옮긴 뒤의 제목. **캘린더만 시안에 있고**(`1r-1-M4`) 나머지는 Android 문구를 따랐다
    /// (COMPONENT-MAP 3장 #26).
    nonisolated static func movedTitle(_ command: MateCommand) -> String { movedTitles[command] ?? "" }

    private nonisolated static let movedTitles: [MateCommand: String] = [
        .calendar: "캘린더로 옮겼어요",
        .home: "홈으로 왔어요",
        .record: "기록을 열었어요",
        .profile: "내 정보를 열었어요",
        .back: "앞 화면으로 돌아갔어요",
        .intake: "증상 정리를 시작할게요",
        .visitRecord: "진료 후 기록을 시작할게요",
        .briefCards: "브리핑 카드 목록을 열었어요",
        .scheduleAdd: "일정 추가를 열었어요",
        .resume: "하던 정리를 이어서 할게요"
    ]

    /// 둘째 줄. **시안이 적어 둔 것은 캘린더 하나뿐이라** 나머지는 비운다.
    nonisolated static func movedHint(_ command: MateCommand) -> String? {
        command == .calendar ? "날짜를 말하면 그 날을 열어드려요" : nil
    }
}
