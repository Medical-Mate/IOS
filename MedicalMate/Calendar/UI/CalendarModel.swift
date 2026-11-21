import Foundation
import Observation

/// `1r-1` 캘린더 월 화면의 상태.
@MainActor
@Observable
final class CalendarModel {
    private(set) var month: CalendarMonth
    private(set) var appointments: [Appointment] = []
    /// 이 달에 쓴 카드. 기록 점과 카드만 있는 날 시트가 읽는다.
    private(set) var monthCards: [CalendarDayCard] = []
    /// 진료 후 기록 전부. 기록 점과 아직 확정하지 않은 재방문이 여기서 온다.
    private(set) var visitDays: [CalendarVisitDay] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 카드만 있는 날 시트(`1r-1-S` `3663:14570`). **날을 눌렀을 때만 뜬다** — 달을 다시
    /// 읽을 때 새로 띄우면 시트에서 카드로 갔다 돌아올 때마다 또 떠서 지나온 화면으로
    /// 다시 보내려는 것처럼 보인다.
    private(set) var cardSheet: CalendarDayCard?

    /// 고른 날. 달을 넘기면 비운다 — 다른 달의 날을 고른 채로 두면 아래 목록과
    /// 그리드가 어긋난다.
    private(set) var selectedDay: Int?

    private let repository: AppointmentRepository
    private let cards: CardRepository?
    private let visits: VisitRepository?
    private let calendar: Calendar
    private let today: @Sendable () -> Date

    init(
        repository: AppointmentRepository,
        cards: CardRepository? = nil,
        visits: VisitRepository? = nil,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.cards = cards
        self.visits = visits
        self.calendar = calendar
        self.today = today
        month = CalendarMonth.of(today(), calendar: calendar)
        selectedDay = calendar.component(.day, from: today())
    }

    // MARK: - 읽는 값

    /// 화면이 날짜를 적을 때 쓰는 달력. 모델과 같은 것을 써야 날이 어긋나지 않는다.
    var gridCalendar: Calendar { calendar }

    /// 이 달에 오늘이 있으면 그 날짜.
    var todayDay: Int? {
        let now = CalendarMonth.of(today(), calendar: calendar)
        guard now == month else { return nil }
        return calendar.component(.day, from: today())
    }

    /// 예정 점. **잡아 둔 일정과 아직 확정하지 않은 재방문을 합친다.** 재방문은 진료 후
    /// 기록에서 뽑아 둔 날이고 일정으로는 아직 없다 — 달력에 안 보이면 확정하러 갈 길이
    /// 없다. 지난 날은 빼고 이 달의 것만 남긴다.
    var scheduledDays: Set<Int> {
        CalendarModel.plannedDays(
            appointments: appointments,
            visits: visitDays,
            month: month,
            today: today(),
            calendar: calendar
        )
    }

    /// 기록 점. **카드를 쓴 날과 진료 후 기록을 남긴 날이 "기록 있음"이다.**
    var recordDays: Set<Int> {
        CalendarModel.recordDays(cards: monthCards, visits: visitDays, month: month, calendar: calendar)
    }

    var days: [MMCalendarGrid.Day] {
        month.days(
            calendar: calendar,
            selected: selectedDay,
            today: todayDay,
            scheduled: scheduledDays,
            records: recordDays
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
            .sorted(by: AppointmentMapping.isEarlier)
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

        if let cards, case .success(let list) = await cards.cards() {
            monthCards = list.compactMap { CalendarDayCard(from: $0, calendar: calendar) }
                .filter { CalendarMonth.of($0.writtenOn, calendar: calendar) == month }
        }
        if let visits, case .success(let list) = await visits.visits() {
            visitDays = list.compactMap { CalendarVisitDay(from: $0) }
        }

        // 떠 있던 시트는 새 값으로 다시 세운다. 그 사이 일정이 생겼으면 닫힌다.
        if cardSheet != nil, let day = selectedDay {
            cardSheet = selectedAppointments.isEmpty
                ? CalendarModel.card(on: day, cards: monthCards, appointments: appointments, calendar: calendar)
                : nil
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
        // 일정이 없고 카드만 쓴 날은 갈 화면이 없다. 그 자리에서 시트로 보여준다.
        cardSheet = selectedAppointments.isEmpty
            ? CalendarModel.card(on: day, cards: monthCards, appointments: appointments, calendar: calendar)
            : nil
    }

    func dismissCardSheet() {
        cardSheet = nil
    }

    private func move(by months: Int) async {
        month = month.advanced(by: months, calendar: calendar)
        // 달을 넘기면 고른 날을 1일로 둔다. 비워 두면 아래 구간이 사라져 화면이 흔들린다.
        selectedDay = todayDay ?? 1
        appointments = []
        monthCards = []
        cardSheet = nil
        isLoading = true
        await load()
    }

    // MARK: - 규칙

    nonisolated static func plannedDays(
        appointments: [Appointment],
        visits: [CalendarVisitDay],
        month: CalendarMonth,
        today: Date,
        calendar: Calendar
    ) -> Set<Int> {
        let scheduled = appointments.filter { $0.status != .canceled }.map(\.on)
        let revisits = visits.compactMap(\.followUpOn)
        let startOfToday = calendar.startOfDay(for: today)
        return Set(
            (scheduled + revisits)
                .filter { calendar.startOfDay(for: $0) >= startOfToday }
                .filter { CalendarMonth.of($0, calendar: calendar) == month }
                .map { calendar.component(.day, from: $0) }
        )
    }

    nonisolated static func recordDays(
        cards: [CalendarDayCard],
        visits: [CalendarVisitDay],
        month: CalendarMonth,
        calendar: Calendar
    ) -> Set<Int> {
        Set(
            (cards.map(\.writtenOn) + visits.map(\.visitedOn))
                .filter { CalendarMonth.of($0, calendar: calendar) == month }
                .map { calendar.component(.day, from: $0) }
        )
    }

    /// 그 날 쓴 카드. **여럿이면 첫 장이다** — 시안의 시트도 한 장을 보여준다.
    nonisolated static func card(
        on day: Int,
        cards: [CalendarDayCard],
        appointments: [Appointment],
        calendar: Calendar
    ) -> CalendarDayCard? {
        guard var card = cards.first(where: { calendar.component(.day, from: $0.writtenOn) == day }) else {
            return nil
        }
        // 이 카드로 이미 만든 일정이 있으면 시트가 "만들기"가 아니라 "보러가기"가 된다.
        // **이 달 안에서만 찾는다** — 캘린더가 그 달 일정만 들고 있다.
        card.scheduled = appointments.first { appointment in
            appointment.status != .canceled && appointment.cards.contains { $0.id == card.id }
        }
        return card
    }
}
