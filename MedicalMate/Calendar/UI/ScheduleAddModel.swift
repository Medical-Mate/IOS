import Foundation
import SwiftUI
import Observation

/// `1r-4` 일정 추가의 상태.
@MainActor
@Observable
final class ScheduleAddModel {
    enum Sheet: Equatable {
        /// 1r-4-D 날짜 선택.
        case date
        /// 1r-4-T 시간 선택.
        case time
        /// 1r-4-S 예약 문자 방법 안내.
        case shareGuide
    }

    private(set) var clinic: BriefCardHospital?
    private(set) var on: Date?
    private(set) var time: AppointmentTime?
    private(set) var cards: [CardListItem] = []
    private(set) var pickedCardIds: Set<Int64> = []
    private(set) var todos: [AppointmentTodo] = []

    var sheet: Sheet?
    /// 날짜 시트가 보고 있는 달. 고른 날과 따로 둔다 — 달을 넘겨도 고른 날은 남아야 한다.
    private(set) var sheetMonth: CalendarMonth
    private(set) var sheetDay: Int?
    var sheetIsMorning = true
    var sheetHour = 10
    var sheetMinute = 0

    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let repository: AppointmentRepository
    private let cardsRepository: CardRepository
    private let calendar: Calendar
    private let today: @Sendable () -> Date

    /// 미리 골라 둘 카드. **카드를 정해 놓고 들어오는 길**이 넷이다 — 카드만 있는 날
    /// 시트의 "이 카드로 일정 만들기" · 홈 배너의 "진료 일정 잡기" · 브리핑 카드의
    /// "진료 일정 잡기" · 재방문 확정. 화면에서 다시 고르게 하면 두 번 고르는 꼴이다
    /// (Android `#239`).
    private let cardId: Int64?
    /// 재방문을 확정하러 들어온 것인지. **출처와 카드는 다른 값이다** — 카드를 들고
    /// 들어왔다고 다 재방문은 아니다. 이 값이 참일 때만 `visitFollowUp`으로 만든다
    /// (Android `#245`).
    private let isFollowUp: Bool
    /// 고치러 들어온 일정. **시간 미정으로 저장하고 나면 그 값을 채울 자리가 여기뿐이다**
    /// (Android `#230`). 새로 만들면 같은 일정이 둘이 된다.
    private let appointmentId: Int64?

    init(
        initialDate: Date?,
        cardId: Int64? = nil,
        isFollowUp: Bool = false,
        appointmentId: Int64? = nil,
        repository: AppointmentRepository,
        cards cardsRepository: CardRepository,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.cardId = cardId
        self.isFollowUp = isFollowUp
        self.appointmentId = appointmentId
        self.repository = repository
        self.cardsRepository = cardsRepository
        self.calendar = calendar
        self.today = today
        on = initialDate
        sheetMonth = CalendarMonth.of(initialDate ?? today(), calendar: calendar)
        sheetDay = initialDate.map { calendar.component(.day, from: $0) }
    }

    // MARK: - 읽는 값

    /// 병원 칸의 글. 고르지 않았으면 안내가 선다.
    var clinicLabel: String { clinic?.name ?? "진료받을 병원을 찾아주세요" }
    var hasClinic: Bool { clinic != nil }

    /// "9월 26일 (토)".
    var dateLabel: String {
        on.map { CalendarMonth.dayTitle($0, calendar: calendar) } ?? "날짜"
    }

    var timeLabel: String { time?.label ?? "시간" }

    /// 구간 머리 오른쪽. 고른 것이 없으면 "선택 안 함"이다.
    var pickedLabel: String {
        pickedCardIds.isEmpty ? "선택 안 함" : "\(pickedCardIds.count)개"
    }

    /// **병원과 날짜가 차야 저장할 수 있다.** 시각은 선택이다(`1r-4`).
    ///
    /// 시안이 저장하기를 **병원이 차는 순간** 켠다 — `1r-4`(병원 · 날짜 둘 다 빔)는
    /// 꺼져 있고 `1r-4-B`(병원만 참)는 켜져 있다. 날짜는 서버가 요구해서 함께 본다.
    /// Android도 `hospital != null && date != null`이다.
    ///
    /// 병원 없이 저장하면 **일자 화면의 일정 제목이 빈 줄로 선다** — 제목을 병원 ·
    /// 진료과 · 목적으로 짓기 때문이다.
    ///
    /// **카드는 여기서 묻지 않는다.** Android는 하나 이상을 요구하지만(`#312`) 그쪽은
    /// 사람이 정한 값이고, 이 저장소에는 "카드 없이 다음 주 치과만 적을 수 있어야
    /// 한다"가 적혀 있다 — 두 저장소가 갈린 채로 두고 COMPONENT-MAP 3장에 올린다.
    var canSave: Bool { clinic != nil && on != nil && !isSaving }

    var sheetDays: [MMCalendarGrid.Day] {
        sheetMonth.days(
            calendar: calendar,
            selected: sheetDay,
            today: nil,
            scheduled: [],
            records: []
        )
    }

    func isPicked(_ id: Int64) -> Bool { pickedCardIds.contains(id) }

    /// 이미 있는 일정을 고치는 중인지.
    var isEditing: Bool { appointmentId != nil }

    /// 재진인 일정인지. **재방문을 확정하러 들어왔거나, 이미 진료를 마친 카드를
    /// 골랐으면** 재진이다(Android `#245` · `#272`).
    ///
    /// 뒤의 것이 없으면 같은 카드로 다시 잡은 일정이 일자 화면과 홈에서 "초진"으로
    /// 뜨고, 기록 상세(`1j-3`)는 같은 진료를 재방문으로 적어 **두 화면이 어긋난다.**
    ///
    /// 서버의 `origin`은 원래 일정이 어디서 왔는지인데 화면이 그 값 하나로 초진·재진을
    /// 가르므로 여기에 싣는다. 서버가 둘을 따로 내려 주면 그 값을 쓴다.
    var isRevisit: Bool {
        isFollowUp || cards.contains { ScheduleAddModel.isVisitedAndPicked($0, picked: pickedCardIds) }
    }

    nonisolated static func isVisitedAndPicked(_ item: CardListItem, picked: Set<Int64>) -> Bool {
        guard case .card(let id, let visited) = item.kind else { return false }
        return visited && picked.contains(id)
    }

    // MARK: - 들어오기

    func load() async {
        switch await cardsRepository.cards() {
        case .success(let list):
            cards = cardsRepository.sections(cards: list, openIntake: nil)
                .flatMap(\.items)
                .filter(\.isCard)
        case .rejected, .networkUnavailable:
            // 카드를 못 받아도 일정은 만들 수 있다. 카드는 선택이다.
            cards = []
        }
        // **들고 온 카드는 체크된 채로 선다.** 저장할 때만 끼워 넣으면 화면에는 안
        // 골라진 것으로 보여서, 정해 놓고 들어온 사람이 같은 카드를 다시 찾아 누른다.
        // Android `load()`도 받은 `cardId`를 고른 것에 더한다(#239).
        if let cardId { pickedCardIds.insert(cardId) }
        await loadAppointment()
    }

    /// 고치러 들어왔으면 그 일정의 값을 채운다.
    ///
    /// **서버에 일정 하나를 id로 읽는 경로가 없어 그 날의 목록에서 찾는다**(Android도
    /// 같다). 못 찾으면 값을 비운 채로 둔다 — 빈 화면이 뜨는 것보다 낫고, 저장은
    /// 그래도 그 일정으로 나간다.
    private func loadAppointment() async {
        guard let appointmentId, let on else { return }
        let day = VisitMapping.day(on, calendar: calendar)
        guard case .success(let list) = await repository.appointments(date: day),
              let found = list.compactMap(AppointmentMapping.appointment(from:))
                  .first(where: { $0.id == appointmentId })
        else { return }
        time = found.time
        todos = found.todos
        pickedCardIds.formUnion(found.cards.map(\.id))
        if let name = found.clinic, !name.isEmpty {
            clinic = BriefCardHospital(name: name, address: nil)
        }
    }

    // MARK: - 고르기

    func pick(clinic hospital: Hospital?) {
        guard let hospital else { return }
        clinic = BriefCardHospital(name: hospital.name, address: hospital.address)
    }

    func toggleCard(_ item: CardListItem) {
        guard case .card(let id, _) = item.kind else { return }
        if pickedCardIds.contains(id) {
            pickedCardIds.remove(id)
        } else {
            pickedCardIds.insert(id)
        }
    }

    // MARK: - 날짜 · 시간 시트

    func openDateSheet() {
        sheetMonth = CalendarMonth.of(on ?? today(), calendar: calendar)
        sheetDay = on.map { calendar.component(.day, from: $0) }
        sheet = .date
    }

    func openTimeSheet() {
        if let time {
            sheetIsMorning = time.hour < 12
            sheetHour = time.hour % 12 == 0 ? 12 : time.hour % 12
            sheetMinute = time.minute
        }
        sheet = .time
    }

    func sheetGoToPreviousMonth() { sheetMonth = sheetMonth.advanced(by: -1, calendar: calendar) }
    func sheetGoToNextMonth() { sheetMonth = sheetMonth.advanced(by: 1, calendar: calendar) }
    func sheetSelect(day: Int) { sheetDay = day }

    func confirmDate() {
        if let day = sheetDay { on = sheetMonth.date(day: day, calendar: calendar) }
        sheet = nil
    }

    func confirmTime() {
        time = AppointmentMapping.time(isMorning: sheetIsMorning, hour: sheetHour, minute: sheetMinute)
        sheet = nil
    }

    // MARK: - 할 일

    func addTodo() {
        todos.append(AppointmentTodo(text: ""))
    }

    func todo(at index: Int) -> Binding<String> {
        Binding(
            get: { [weak self] in
                guard let todos = self?.todos, todos.indices.contains(index) else { return "" }
                return todos[index].text
            },
            set: { [weak self] newValue in
                guard self?.todos.indices.contains(index) == true else { return }
                self?.todos[index].text = newValue
            }
        )
    }

    func toggleTodo(_ todo: AppointmentTodo) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isDone.toggle()
    }

    func deleteTodo(_ todo: AppointmentTodo) {
        todos.removeAll { $0.id == todo.id }
    }

    // MARK: - 저장

    /// 보낼 카드. **확정하러 들고 온 카드는 고르지 않았어도 함께 간다.**
    nonisolated static func cardIds(picked: Set<Int64>, followUp: Int64?) -> [Int64] {
        var ids = picked
        if let followUp { ids.insert(followUp) }
        return ids.sorted()
    }

    func save() async -> Int64? {
        guard let on, !isSaving else { return nil }
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let request = CreateAppointmentRequest(
            clinicName: clinic?.name,
            department: nil,
            purpose: nil,
            scheduledOn: VisitMapping.day(on, calendar: calendar),
            scheduledTime: time?.wire,
            cardIds: ScheduleAddModel.cardIds(picked: pickedCardIds, followUp: cardId),
            // **손으로 만든 일정은 출처가 없다.** 재방문을 확정하러 들어왔을 때만 적는다.
            origin: (isRevisit ? AppointmentOrigin.visitFollowUp : .manual).wire,
            // 빈 줄은 보내지 않는다. 추가만 하고 안 적은 칸이다.
            todos: AppointmentMapping.cleaned(todos)
        )

        // **고치러 들어왔으면 새로 만들지 않는다.** 새로 만들면 같은 일정이 둘이 된다
        // (Android `#230`).
        let result: ApiResult<AppointmentResponse>
        if let appointmentId {
            result = await repository.update(id: appointmentId, ScheduleAddModel.updateRequest(from: request))
        } else {
            result = await repository.create(request)
        }
        switch result {
        case .success(let response):
            return appointmentId ?? response.appointmentId
        case .rejected(let error):
            errorMessage = error.message ?? "일정을 저장하지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        return nil
    }

    /// 만들 때 쓰는 요청을 고칠 때 쓰는 요청으로 옮긴다.
    ///
    /// **출처(`origin`)는 보내지 않는다** — 이미 저장된 일정이 어디서 왔는지는 고친다고
    /// 바뀌지 않는다. 카드와 할 일은 통째로 갈아끼운다(지운 줄이 남지 않게).
    nonisolated static func updateRequest(from request: CreateAppointmentRequest) -> UpdateAppointmentRequest {
        UpdateAppointmentRequest(
            clinicName: request.clinicName,
            scheduledOn: request.scheduledOn,
            scheduledTime: request.scheduledTime,
            cardIds: request.cardIds,
            todos: request.todos
        )
    }
}
