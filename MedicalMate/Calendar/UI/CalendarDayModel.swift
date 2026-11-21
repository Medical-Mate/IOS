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
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 편집 사본. 있으면 편집 모드다.
    private(set) var draft: [AppointmentTodo]?
    private(set) var isSaving = false
    var isDeleteRequested = false

    private let repository: AppointmentRepository
    private let calendar: Calendar
    private let today: @Sendable () -> Date

    init(
        date: Date,
        repository: AppointmentRepository,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.date = date
        self.repository = repository
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

    /// 일정 카드 머리의 "D-5". **지난 일정은 "진료 완료"다.**
    var dayLabel: String {
        guard let appointment else { return "" }
        if appointment.status == .done { return "진료 완료" }
        let start = calendar.startOfDay(for: today())
        let target = calendar.startOfDay(for: appointment.on)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        if days == 0 { return "D-DAY" }
        return days > 0 ? "D-\(days)" : "D+\(-days)"
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
            cards = appointment?.cards.map {
                BriefCardLink(id: $0.id, title: $0.title ?? "")
            } ?? []
        case .rejected(let error):
            errorMessage = error.message ?? "일정을 불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
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
}
