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

    init(
        initialDate: Date?,
        repository: AppointmentRepository,
        cards cardsRepository: CardRepository,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
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

    /// **날짜만 있으면 저장할 수 있다.** 시각과 카드는 선택이다 — 카드 없이
    /// "다음 주 치과"만 적을 수 있어야 한다.
    var canSave: Bool { on != nil && !isSaving }

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
            cardIds: Array(pickedCardIds).sorted(),
            origin: AppointmentOrigin.manual.wire,
            // 빈 줄은 보내지 않는다. 추가만 하고 안 적은 칸이다.
            todos: AppointmentMapping.cleaned(todos)
        )

        switch await repository.create(request) {
        case .success(let response):
            return response.appointmentId
        case .rejected(let error):
            errorMessage = error.message ?? "일정을 저장하지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        return nil
    }
}
