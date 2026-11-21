import Foundation
import Observation

/// `1r-1` 캘린더 월 화면의 상태.
@MainActor
@Observable
final class CalendarModel {
    private(set) var month: CalendarMonth
    private(set) var appointments: [Appointment] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 고른 날. 달을 넘기면 비운다 — 다른 달의 날을 고른 채로 두면 아래 목록과
    /// 그리드가 어긋난다.
    private(set) var selectedDay: Int?

    private let repository: AppointmentRepository
    private let calendar: Calendar
    private let today: @Sendable () -> Date

    init(
        repository: AppointmentRepository,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.today = today
        month = CalendarMonth.of(today(), calendar: calendar)
        selectedDay = calendar.component(.day, from: today())
    }

    // MARK: - 읽는 값

    /// 이 달에 오늘이 있으면 그 날짜.
    var todayDay: Int? {
        let now = CalendarMonth.of(today(), calendar: calendar)
        guard now == month else { return nil }
        return calendar.component(.day, from: today())
    }

    var scheduledDays: Set<Int> {
        Set(appointments.filter { $0.status != .canceled }.map { calendar.component(.day, from: $0.on) })
    }

    var days: [MMCalendarGrid.Day] {
        month.days(
            calendar: calendar,
            selected: selectedDay,
            today: todayDay,
            scheduled: scheduledDays,
            // 기록 점은 H 섹션의 기록 목록이 들어온 뒤에 켠다. 지금은 일정만 안다.
            records: []
        )
    }

    var selectedDate: Date? {
        selectedDay.flatMap { month.date(day: $0, calendar: calendar) }
    }

    /// 아래 구간 제목. "9월 12일 (토)".
    var selectedTitle: String {
        selectedDate.map { CalendarMonth.dayTitle($0, calendar: calendar) } ?? ""
    }

    /// 고른 날의 일정. 시간이 이른 것부터이고 **미정은 뒤로 간다.**
    var selectedAppointments: [Appointment] {
        guard let day = selectedDay else { return [] }
        return appointments
            .filter { calendar.component(.day, from: $0.on) == day && $0.status != .canceled }
            .sorted { lhs, rhs in
                switch (lhs.time, rhs.time) {
                case let (left?, right?): left < right
                case (nil, _?): false
                case (_?, nil): true
                default: lhs.id < rhs.id
                }
            }
    }

    // MARK: - 움직임

    func load() async {
        errorMessage = nil
        switch await repository.appointments(year: month.year, month: month.month) {
        case .success(let list):
            appointments = list.compactMap(AppointmentMapping.appointment(from:))
        case .rejected(let error):
            errorMessage = error.message ?? "일정을 불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
    }

    func goToPreviousMonth() async {
        await move(by: -1)
    }

    func goToNextMonth() async {
        await move(by: 1)
    }

    func select(day: Int) {
        selectedDay = day
    }

    private func move(by months: Int) async {
        month = month.advanced(by: months, calendar: calendar)
        // 달을 넘기면 고른 날을 1일로 둔다. 비워 두면 아래 구간이 사라져 화면이 흔들린다.
        selectedDay = todayDay ?? 1
        appointments = []
        isLoading = true
        await load()
    }
}
