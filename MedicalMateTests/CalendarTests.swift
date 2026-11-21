import Foundation
import Testing
@testable import MedicalMate

/// G 섹션 — 캘린더가 한 달을 어떻게 칸으로 펴는지.
struct CalendarMonthTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    /// 2026년 9월은 1일이 화요일이고 30일까지다(마스터의 기본값).
    private let september = CalendarMonth(year: 2026, month: 9)

    @Test func 달의_첫날이_요일_칸에_맞춰_선다() {
        // 1일이 화요일이면 앞에 빈 칸 둘(일·월)이 선다.
        #expect(september.leadingBlanks(calendar: calendar) == 2)
        #expect(september.dayCount(calendar: calendar) == 30)
    }

    @Test func 칸은_주_단위로_떨어진다() {
        // 빈 칸 2 + 30일 = 32칸 → 5주 35칸.
        let days = september.days(calendar: calendar, selected: nil, today: nil, scheduled: [], records: [])
        #expect(days.count == 35)
        #expect(days.count % 7 == 0)
    }

    @Test func 여섯_주짜리_달은_42칸이다() {
        // 2026년 8월은 1일이 토요일이라 6주가 된다.
        let august = CalendarMonth(year: 2026, month: 8)
        let days = august.days(calendar: calendar, selected: nil, today: nil, scheduled: [], records: [])
        #expect(days.count == 42)
    }

    @Test func 오늘이_고른_날보다_앞선다() {
        // 1r-1에서 오늘(7)은 테두리, 고른 날(12)은 채움이다. 고른 날이 오늘이면
        // 테두리로 그린다.
        let days = september.days(calendar: calendar, selected: 18, today: 18, scheduled: [], records: [])
        let cell = days.first { $0.date == 18 }
        #expect(cell?.state == .today)
    }

    @Test func 고른_날은_채우고_오늘은_테두리다() {
        let days = september.days(calendar: calendar, selected: 12, today: 7, scheduled: [], records: [])
        #expect(days.first { $0.date == 12 }?.state == .selected)
        #expect(days.first { $0.date == 7 }?.state == .today)
        #expect(days.first { $0.date == 3 }?.state == .default)
    }

    @Test func 기록이_예정보다_먼저_보인다() {
        // 겹치면 이미 지난 일을 보인다. 지난 일은 사실이고 예정은 계획이다(Android markerOn).
        let days = september.days(calendar: calendar, selected: nil, today: nil, scheduled: [12, 20], records: [12, 4])
        #expect(days.first { $0.date == 12 }?.dot == .record)
        #expect(days.first { $0.date == 20 }?.dot == .scheduled)
        #expect(days.first { $0.date == 4 }?.dot == .record)
        #expect(days.first { $0.date == 5 }?.dot == MMCalendarDay.Dot.none)
    }

    @Test func 달을_넘기면_해가_바뀐다() {
        let december = CalendarMonth(year: 2026, month: 12)
        #expect(december.advanced(by: 1, calendar: calendar) == CalendarMonth(year: 2027, month: 1))
        #expect(CalendarMonth(year: 2026, month: 1).advanced(by: -1, calendar: calendar)
            == CalendarMonth(year: 2025, month: 12))
    }

    @Test func 머리와_구간_제목의_모양() throws {
        #expect(september.title == "2026년 9월")
        let day = try #require(september.date(day: 12, calendar: calendar))
        #expect(CalendarMonth.dayTitle(day, calendar: calendar) == "9월 12일 (토)")
    }
}

/// 일정 응답을 화면 값으로.
struct AppointmentMappingTests {
    private func response(
        clinic: String? = "서울OO병원",
        department: String? = "내과",
        purpose: String? = "재진",
        time: String? = "10:30:00",
        status: String? = "SCHEDULED",
        cards: [LinkedCardResponse] = []
    ) -> AppointmentResponse {
        AppointmentResponse(
            appointmentId: 1, clinicName: clinic, department: department, purpose: purpose,
            scheduledOn: "2026-09-12", scheduledTime: time, status: status, origin: nil,
            cards: cards, todos: nil
        )
    }

    @Test func 제목은_병원_진료과_목적을_합친다() {
        #expect(AppointmentMapping.title(response(), cards: []) == "서울OO병원 내과 재진")
    }

    @Test func 셋이_다_비면_붙은_카드_제목을_쓴다() {
        // 제목 없는 줄은 무엇에 대한 일정인지 알 수 없다.
        let empty = response(clinic: nil, department: nil, purpose: nil)
        let cards = [AppointmentCard(id: 7, title: "복부 통증 · 3주")]
        #expect(AppointmentMapping.title(empty, cards: cards) == "복부 통증 · 3주")
    }

    @Test func 시각은_오전_오후로_읽는다() {
        #expect(AppointmentTime(hour: 10, minute: 30).label == "오전 10:30")
        #expect(AppointmentTime(hour: 14, minute: 5).label == "오후 2:05")
        #expect(AppointmentTime(hour: 0, minute: 0).label == "오전 12:00")
        #expect(AppointmentTime(hour: 12, minute: 0).label == "오후 12:00")
    }

    @Test func 못_읽는_시각은_미정으로_본다() {
        // 일정 하나 때문에 캘린더 전체가 죽는 것보다 낫다.
        #expect(AppointmentMapping.time(from: "10:30") == AppointmentTime(hour: 10, minute: 30))
        #expect(AppointmentMapping.time(from: "이상한값") == nil)
        #expect(AppointmentMapping.time(from: "99:99") == nil)
        #expect(AppointmentMapping.time(from: nil) == nil)
    }

    @Test func 시간이_미정이면_그_사실을_적는다() throws {
        // 빈 자리로 두면 시간이 정해진 것처럼 읽힌다.
        let appointment = try #require(AppointmentMapping.appointment(from: response(time: nil)))
        #expect(AppointmentMapping.meta(appointment) == "시간 미정")
    }

    @Test func 둘째_줄은_시각과_카드를_잇는다() throws {
        let cards = [LinkedCardResponse(cardId: 7, title: "복부 통증 브리핑 카드")]
        let appointment = try #require(AppointmentMapping.appointment(from: response(cards: cards)))
        #expect(AppointmentMapping.meta(appointment) == "오전 10:30 · 복부 통증 브리핑 카드")
    }

    @Test func 모르는_상태는_예정으로_본다() {
        // 캘린더에서 사라지면 사용자가 일정을 잃었다고 본다.
        #expect(AppointmentStatus.of("NEW_THING") == .scheduled)
        #expect(AppointmentStatus.of(nil) == .scheduled)
        #expect(AppointmentStatus.of("DONE") == .done)
    }

    @Test func 모르는_출처는_손으로_만든_것으로_본다() {
        #expect(AppointmentOrigin.of("NEW") == .manual)
        #expect(AppointmentOrigin.of("VISIT_FOLLOW_UP") == .visitFollowUp)
    }

    @Test func 지난_일정은_진료_완료_배지다() throws {
        let done = try #require(AppointmentMapping.appointment(from: response(status: "DONE")))
        #expect(AppointmentMapping.badge(done)?.text == "진료 완료")
        let canceled = try #require(AppointmentMapping.appointment(from: response(status: "CANCELED")))
        #expect(AppointmentMapping.badge(canceled) == nil)
    }
}

/// 일정 추가가 무엇을 보내는지.
struct ScheduleAddTests {
    @Test func 열두시간_표기를_스물네시간으로_옮긴다() {
        // 오전 12시는 0시, 오후 12시는 12시다.
        #expect(AppointmentMapping.time(isMorning: true, hour: 10, minute: 30) == AppointmentTime(hour: 10, minute: 30))
        #expect(AppointmentMapping.time(isMorning: false, hour: 2, minute: 0) == AppointmentTime(hour: 14, minute: 0))
        #expect(AppointmentMapping.time(isMorning: true, hour: 12, minute: 0) == AppointmentTime(hour: 0, minute: 0))
        #expect(AppointmentMapping.time(isMorning: false, hour: 12, minute: 0) == AppointmentTime(hour: 12, minute: 0))
    }

    @Test func 서버가_받는_시각은_두_자리로_간다() {
        #expect(AppointmentTime(hour: 9, minute: 5).wire == "09:05")
    }

    @Test func 적지_않은_빈_할_일은_보내지_않는다() {
        // 추가만 누르고 안 적은 칸이다.
        let todos = [
            AppointmentTodo(text: "복용 중인 약 챙기기"),
            AppointmentTodo(text: "   "),
            AppointmentTodo(text: "", isDone: true)
        ]
        let cleaned = AppointmentMapping.cleaned(todos)
        #expect(cleaned.count == 1)
        #expect(cleaned.first?.text == "복용 중인 약 챙기기")
    }
}

/// 일자 상세가 하루의 일정을 어떻게 고르는지.
struct CalendarDayTests {
    private func appointment(id: Int64, hour: Int?, minute: Int = 0) -> Appointment {
        Appointment(
            id: id, title: "", clinic: nil,
            on: fixtureDay("2026-09-12"),
            time: hour.map { AppointmentTime(hour: $0, minute: minute) },
            status: .scheduled, origin: .manual, cards: [], todos: []
        )
    }

    @Test func 이른_시각이_먼저고_미정은_뒤로_간다() {
        let early = appointment(id: 1, hour: 9)
        let late = appointment(id: 2, hour: 14)
        let unset = appointment(id: 3, hour: nil)

        #expect(AppointmentMapping.isEarlier(early, than: late))
        #expect(!AppointmentMapping.isEarlier(late, than: early))
        #expect(AppointmentMapping.isEarlier(late, than: unset))
        #expect(!AppointmentMapping.isEarlier(unset, than: late))
    }

    @Test func 시각이_둘_다_없으면_id_순이다() {
        #expect(AppointmentMapping.isEarlier(appointment(id: 1, hour: nil), than: appointment(id: 2, hour: nil)))
    }
}

/// 일자 상세가 카드 줄과 기록 줄에 무엇을 적는지.
@MainActor
struct CalendarDayCopyTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private var summary: CardSummaryResponse {
        CardSummaryResponse(
            cardId: 7, title: nil, chiefComplaint: "복부 통증 · 3주", visited: nil,
            clinicName: nil, createdAt: "2026-09-18",
            axes: ["부위", "기간", "양상", "복용약", "기저질환"]
        )
    }

    @Test func 진료_전에는_작성일과_항목_수를_적는다() {
        #expect(CalendarDayModel.cardMeta(summary, isVisited: false, calendar: calendar) == "2026.09.18 · 5항목")
    }

    @Test func 진료를_마치면_무엇에_쓰는_카드인지를_적는다() {
        #expect(CalendarDayModel.cardMeta(summary, isVisited: true, calendar: calendar) == "브리핑 카드 · 진료실에서 보여줌")
    }

    @Test func 기록_줄은_재방문_날짜를_덧붙인다() {
        let record = VisitListItem(
            id: 5, cardId: 7, cardTitle: "위염 초기 · 2주 약", clinicName: nil,
            visitedOn: fixtureDay("2026-09-18"),
            followUp: VisitFollowUp(date: fixtureDay("2026-09-26"), text: nil, approximate: true)
        )
        #expect(CalendarDayView.recordMeta(record) == "위염 초기 · 2주 약 · 09.26 재방문")
    }

    @Test func 재방문이_없으면_카드_제목만_적는다() {
        let record = VisitListItem(
            id: 5, cardId: 7, cardTitle: "위염 초기", clinicName: nil,
            visitedOn: fixtureDay("2026-09-18"), followUp: nil
        )
        #expect(CalendarDayView.recordMeta(record) == "위염 초기")
    }
}

/// `1r-1`의 점 두 가지와 `1r-1-S`(카드만 있는 날 시트).
struct CalendarDotsAndCardSheetTests {
    private var seoul: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func appointment(id: Int64, on day: String, cards: [Int64] = []) -> Appointment {
        Appointment(
            id: id, title: "", clinic: nil,
            on: fixtureDay(day),
            time: nil,
            status: .scheduled, origin: .manual,
            cards: cards.map { AppointmentCard(id: $0, title: nil) },
            todos: []
        )
    }

    private func dayCard(id: Int64, on day: String, visited: Bool = false) throws -> CalendarDayCard {
        try #require(CalendarDayCard(
            from: CardSummaryResponse(
                cardId: id,
                title: "복부 통증 · 3주",
                chiefComplaint: nil,
                visited: visited,
                clinicName: "서울OO병원 내과",
                createdAt: day,
                axes: ["부위", "기간", "양상", "강도", "동반 증상"]
            ),
            calendar: seoul
        ))
    }

    @Test func 기록_점은_카드를_쓴_날과_기록을_남긴_날이다() throws {
        let month = CalendarMonth(year: 2026, month: 9)
        let visits = [
            CalendarVisitDay(visitedOn: fixtureDay("2026-09-12"), followUpOn: nil),
            // 다른 달의 기록은 찍지 않는다.
            CalendarVisitDay(visitedOn: fixtureDay("2026-08-30"), followUpOn: nil)
        ]
        let days = CalendarModel.recordDays(
            cards: [try dayCard(id: 1, on: "2026-09-04")],
            visits: visits,
            month: month,
            calendar: seoul
        )
        #expect(days == [4, 12])
    }

    @Test func 예정_점은_잡아_둔_일정과_확정하지_않은_재방문을_합친다() {
        let month = CalendarMonth(year: 2026, month: 9)
        let appointment = appointment(id: 1, on: "2026-09-25")
        // 아직 일정으로 만들지 않은 재방문도 찍는다 — 안 보이면 확정하러 갈 길이 없다.
        let visits = [CalendarVisitDay(visitedOn: fixtureDay("2026-09-12"), followUpOn: fixtureDay("2026-09-26"))]
        let days = CalendarModel.plannedDays(
            appointments: [appointment],
            visits: visits,
            month: month,
            today: fixtureDay("2026-09-18"),
            calendar: seoul
        )
        #expect(days == [25, 26])
    }

    @Test func 지난_날은_예정으로_찍지_않는다() {
        let days = CalendarModel.plannedDays(
            appointments: [appointment(id: 1, on: "2026-09-04")],
            visits: [],
            month: CalendarMonth(year: 2026, month: 9),
            today: fixtureDay("2026-09-18"),
            calendar: seoul
        )
        #expect(days.isEmpty)
    }

    @Test func 그_날_쓴_카드가_시트에_선다() throws {
        let card = CalendarModel.card(
            on: 4,
            cards: [try dayCard(id: 7, on: "2026-09-04")],
            appointments: [],
            calendar: seoul
        )
        #expect(card?.id == 7)
        // 일정이 없으면 만들러 간다.
        #expect(card?.scheduled == nil)
    }

    @Test func 이미_만든_일정이_있으면_보러가기가_된다() throws {
        // 14일 카드로 16일 일정을 만든 뒤 14일을 다시 눌러도 또 만들라고 하면 안 된다.
        let scheduled = appointment(id: 3, on: "2026-09-16", cards: [7])
        let card = CalendarModel.card(
            on: 4,
            cards: [try dayCard(id: 7, on: "2026-09-04")],
            appointments: [scheduled],
            calendar: seoul
        )
        #expect(card?.scheduled?.id == 3)
    }

    @Test func 시트의_안내와_버튼이_일정_유무로_갈린다() throws {
        var card = try dayCard(id: 7, on: "2026-09-04")
        let sheet = CalendarCardSheet(dayTitle: "9월 4일 (금)", card: card, calendar: seoul)
        #expect(sheet.hint == "이 카드를 가져갈 일정을 만들 수 있어요")
        #expect(sheet.buttonTitle == "이 카드로 일정 만들기")

        card.scheduled = appointment(id: 3, on: "2026-09-16", cards: [7])
        let scheduled = CalendarCardSheet(dayTitle: "9월 4일 (금)", card: card, calendar: seoul)
        #expect(scheduled.hint == "이 카드로 만들어진 일정이 있어요")
        #expect(scheduled.buttonTitle == "일정 보러가기")
    }

    @Test func 시트의_줄은_작성일과_항목_수를_적는다() throws {
        #expect(try dayCard(id: 7, on: "2026-09-04").meta(calendar: seoul) == "2026.09.04 작성 · 5항목")
    }
}
