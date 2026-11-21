import Foundation
import Observation

/// `1r-2` 캘린더 일자 상세의 상태.
///
/// **읽기와 편집을 사본의 유무로 가른다** — 1e-1 · 1q-1과 같은 규칙이다.
@MainActor
@Observable
final class CalendarDayModel {
    let date: Date
    private(set) var appointment: Appointment?
    private(set) var cards: [BriefCardLink] = []
    /// 이 날 남긴 진료 후 기록.
    private(set) var record: VisitListItem?
    /// 이 진료에서 나온 재방문 일정(`1r-2-A` · `1r-2-A2`).
    private(set) var nextEvent: Appointment?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 편집 사본. 있으면 편집 모드다.
    private(set) var draft: [AppointmentTodo]?
    private(set) var isSaving = false
    var isDeleteRequested = false

    private let repository: AppointmentRepository
    private let cardsRepository: CardRepository
    private let visitsRepository: VisitRepository
    private let calendar: Calendar
    private let today: @Sendable () -> Date

    init(
        date: Date,
        repository: AppointmentRepository,
        cards cardsRepository: CardRepository,
        visits visitsRepository: VisitRepository,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.date = date
        self.repository = repository
        self.cardsRepository = cardsRepository
        self.visitsRepository = visitsRepository
        self.calendar = calendar
        self.today = today
    }

    // MARK: - 읽는 값

    var title: String { CalendarMonth.dayTitle(date, calendar: calendar) }

    var isEditing: Bool { draft != nil }

    var hasChanges: Bool {
        guard let draft, let appointment else { return false }
        return draft != appointment.todos
    }

    var actionTitle: String {
        guard isEditing else { return "편집" }
        return hasChanges ? "확인" : "취소"
    }

    var actionTone: MMNavBar.ActionTone {
        isEditing && !hasChanges ? .subtle : .primary
    }

    var todos: [AppointmentTodo] { draft ?? appointment?.todos ?? [] }

    /// 진료를 마쳤는지. 구간 제목과 보이는 것이 갈린다.
    var isVisited: Bool { appointment?.status == .done || record != nil }

    /// 카드 구간의 제목. 진료 전에는 "가져갈", 끝난 뒤에는 그냥 "브리핑 카드"다.
    var cardSectionTitle: String { isVisited ? "브리핑 카드" : "가져갈 브리핑 카드" }

    /// 재방문 칸에 보일 날짜. "9월 26일 (토)".
    var nextEventDateLabel: String {
        nextEvent.map { CalendarMonth.dayTitle($0.on, calendar: calendar) } ?? ""
    }

    /// 확정된 재방문의 D-day.
    var nextEventDayLabel: String {
        guard let next = nextEvent else { return "" }
        let start = calendar.startOfDay(for: today())
        let target = calendar.startOfDay(for: next.on)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        return HomeRepository.dday(days: days) ?? ""
    }

    /// 확정된 재방문의 둘째 줄. "9월 26일 (토) 오전 10:30".
    var nextEventMeta: String {
        guard let next = nextEvent else { return "" }
        return [nextEventDateLabel, next.time?.label].compactMap(\.self).joined(separator: " ")
    }

    /// 시각이 정해졌는지. **안 정했으면 "시간 정하고 확정하기"가 선다** — 기록에서 나온
    /// 날짜는 "2주 뒤"처럼 날짜까지라 시각이 비어 있다.
    var isNextEventConfirmed: Bool { nextEvent?.time != nil }

    /// 일정 카드 머리의 "D-5". **진료를 마쳤으면 "진료 완료"다.**
    var dayLabel: String {
        guard let appointment else { return "" }
        if isVisited { return "진료 완료" }
        let start = calendar.startOfDay(for: today())
        let target = calendar.startOfDay(for: appointment.on)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        // **지난 날은 배지를 비운다.** 진료를 마쳤으면 위에서 "진료 완료"가 서고, 아직
        // 기록이 없으면 셀 남은 날이 없다.
        return HomeRepository.dday(days: days) ?? ""
    }

    /// 일정 카드의 둘째 줄과 셋째 줄.
    var scheduleDetail: String {
        guard let appointment else { return "" }
        let time = appointment.time?.label ?? "시간 미정"
        guard let card = appointment.cards.first?.title else { return time }
        return "\(time)\n\(card) 브리핑 카드를 가져가요"
    }

    // MARK: - 들어오기

    func load() async {
        errorMessage = nil
        let day = VisitMapping.day(date, calendar: calendar)
        switch await repository.appointments(date: day) {
        case .success(let list):
            // 하루에 일정이 여럿일 수 있지만 시안은 한 건을 그린다. 가장 이른 것을 든다.
            appointment = list
                .compactMap(AppointmentMapping.appointment(from:))
                .filter { $0.status != .canceled }
                .min { AppointmentMapping.isEarlier($0, than: $1) }
            await loadCards()
            await loadRecord()
            await loadNextEvent()
        case .rejected(let error):
            errorMessage = error.message ?? "일정을 불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
    }

    /// 카드 줄의 둘째 줄("2026.09.04 · 5항목")은 일정 응답에 없다. 카드 목록에서
    /// 짝을 지어 채운다.
    private func loadCards() async {
        let links = appointment?.cards ?? []
        guard !links.isEmpty else {
            cards = []
            return
        }

        var summaries: [Int64: CardSummaryResponse] = [:]
        if case .success(let list) = await cardsRepository.cards() {
            summaries = Dictionary(uniqueKeysWithValues: list.map { ($0.cardId, $0) })
        }

        cards = links.map { link in
            BriefCardLink(
                id: link.id,
                title: link.title ?? summaries[link.id]?.chiefComplaint ?? "",
                meta: CalendarDayModel.cardMeta(summaries[link.id], isVisited: isVisited, calendar: calendar)
            )
        }
    }

    /// 진료를 마친 뒤에는 날짜·항목 수 대신 무엇에 쓰는 카드인지를 적는다(`1r-2-A2`).
    static func cardMeta(_ summary: CardSummaryResponse?, isVisited: Bool, calendar: Calendar) -> String {
        if isVisited { return "브리핑 카드 · 진료실에서 보여줌" }
        guard let summary else { return "" }
        let day = summary.createdAt.flatMap(HomeRepository.date(from:)).map { date -> String in
            let parts = calendar.dateComponents([.year, .month, .day], from: date)
            return String(format: "%d.%02d.%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        }
        let count = (summary.axes?.count).map { "\($0)항목" }
        return [day, count].compactMap(\.self).joined(separator: " · ")
    }

    private func loadRecord() async {
        guard case .success(let list) = await visitsRepository.visits() else { return }
        record = list
            .compactMap(VisitMapping.listItem(from:))
            .first { calendar.isDate($0.visitedOn, inSameDayAs: date) }
    }

    /// 이 진료에서 나온 재방문. **출처가 `VISIT_FOLLOW_UP`인 것만** 본다.
    private func loadNextEvent() async {
        guard record != nil || appointment?.status == .done else { return }
        guard case .success(let list) = await repository.upcoming() else { return }
        let linked = Set((appointment?.cards ?? []).map(\.id))
        nextEvent = list
            .compactMap(AppointmentMapping.appointment(from:))
            .first { next in
                next.origin == .visitFollowUp && next.on > date
                    && (linked.isEmpty || next.cards.contains { linked.contains($0.id) })
            }
    }

    // MARK: - 할 일

    /// 읽기 모드에서도 체크는 된다. **진료 전에 하나씩 지워 가는 목록이라 편집을 거쳐야
    /// 체크할 수 있으면 쓸모가 없다.**
    func toggle(_ todo: AppointmentTodo) async {
        guard let appointment else { return }
        if draft != nil {
            guard let index = draft?.firstIndex(where: { $0.id == todo.id }) else { return }
            draft?[index].isDone.toggle()
            return
        }

        var updated = appointment.todos
        guard let index = updated.firstIndex(where: { $0.id == todo.id }) else { return }
        updated[index].isDone.toggle()
        await push(todos: updated)
    }

    func deleteTodo(_ todo: AppointmentTodo) {
        draft?.removeAll { $0.id == todo.id }
    }

    // MARK: - 편집

    func beginEditing() {
        draft = appointment?.todos
    }

    func cancelEditing() {
        draft = nil
    }

    func commitAction() async {
        guard isEditing else { return beginEditing() }
        guard hasChanges, let draft else {
            cancelEditing()
            return
        }
        await push(todos: draft)
        self.draft = nil
    }

    private func push(todos: [AppointmentTodo]) async {
        guard let appointment, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        var request = UpdateAppointmentRequest()
        // 통째로 갈아끼운다. 지운 줄이 남지 않으려면 화면에 있는 것을 전부 보낸다.
        request.todos = AppointmentMapping.cleaned(todos)

        switch await repository.update(id: appointment.id, request) {
        case .success(let response):
            self.appointment = AppointmentMapping.appointment(from: response)
        case .rejected(let error):
            errorMessage = error.message ?? "할 일을 저장하지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
    }

    // MARK: - 삭제

    func delete() async -> Bool {
        guard let appointment, !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        isDeleteRequested = false

        switch await repository.delete(id: appointment.id) {
        case .success:
            return true
        case .rejected(let error):
            errorMessage = error.message ?? "일정을 지우지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        return false
    }
}

/// 일정에 붙은 카드 줄.
struct BriefCardLink: Sendable, Equatable, Identifiable {
    let id: Int64
    let title: String
    var meta: String = ""
}
