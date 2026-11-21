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

    @Test("달의 첫날이 요일 칸에 맞춰 선다")
    func firstDayAlignsToWeekday() {
        // 1일이 화요일이면 앞에 빈 칸 둘(일·월)이 선다.
        #expect(september.leadingBlanks(calendar: calendar) == 2)
        #expect(september.dayCount(calendar: calendar) == 30)
    }

    @Test("칸은 주 단위로 떨어진다")
    func cellsFillWholeWeeks() {
        // 빈 칸 2 + 30일 = 32칸 → 5주 35칸.
        let days = september.days(calendar: calendar, selected: nil, today: nil, scheduled: [], records: [])
        #expect(days.count == 35)
        #expect(days.count % 7 == 0)
    }

    @Test("여섯 주짜리 달은 42칸이다")
    func sixWeekMonthHas42Cells() {
        // 2026년 8월은 1일이 토요일이라 6주가 된다.
        let august = CalendarMonth(year: 2026, month: 8)
        let days = august.days(calendar: calendar, selected: nil, today: nil, scheduled: [], records: [])
        #expect(days.count == 42)
    }

    @Test("오늘이 고른 날보다 앞선다")
    func todayBeatsSelected() {
        // 1r-1에서 오늘(7)은 테두리, 고른 날(12)은 채움이다. 고른 날이 오늘이면
        // 테두리로 그린다.
        let days = september.days(calendar: calendar, selected: 18, today: 18, scheduled: [], records: [])
        let cell = days.first { $0.date == 18 }
        #expect(cell?.state == .today)
    }

    @Test("고른 날은 채우고 오늘은 테두리다")
    func selectedFillsTodayOutlines() {
        let days = september.days(calendar: calendar, selected: 12, today: 7, scheduled: [], records: [])
        #expect(days.first { $0.date == 12 }?.state == .selected)
        #expect(days.first { $0.date == 7 }?.state == .today)
        #expect(days.first { $0.date == 3 }?.state == .default)
    }

    @Test("기록이 예정보다 먼저 보인다")
    func recordDotBeatsScheduled() {
        // 겹치면 이미 지난 일을 보인다. 지난 일은 사실이고 예정은 계획이다(Android markerOn).
        let days = september.days(calendar: calendar, selected: nil, today: nil, scheduled: [12, 20], records: [12, 4])
        #expect(days.first { $0.date == 12 }?.dot == .record)
        #expect(days.first { $0.date == 20 }?.dot == .scheduled)
        #expect(days.first { $0.date == 4 }?.dot == .record)
        #expect(days.first { $0.date == 5 }?.dot == MMCalendarDay.Dot.none)
    }

    @Test("달을 넘기면 해가 바뀐다")
    func monthRollsOverYear() {
        let december = CalendarMonth(year: 2026, month: 12)
        #expect(december.advanced(by: 1, calendar: calendar) == CalendarMonth(year: 2027, month: 1))
        #expect(CalendarMonth(year: 2026, month: 1).advanced(by: -1, calendar: calendar)
            == CalendarMonth(year: 2025, month: 12))
    }

    @Test("머리와 구간 제목의 모양")
    func monthAndDayTitles() throws {
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

    @Test("제목은 병원 진료과 목적을 합친다")
    func titleJoinsClinicParts() {
        #expect(AppointmentMapping.title(response(), cards: []) == "서울OO병원 내과 재진")
    }

    @Test("셋이 다 비면 붙은 카드 제목을 쓴다")
    func titleFallsBackToCard() {
        // 제목 없는 줄은 무엇에 대한 일정인지 알 수 없다.
        let empty = response(clinic: nil, department: nil, purpose: nil)
        let cards = [AppointmentCard(id: 7, title: "복부 통증 · 3주")]
        #expect(AppointmentMapping.title(empty, cards: cards) == "복부 통증 · 3주")
    }

    @Test("시각은 오전 오후로 읽는다")
    func timeReadsAsMeridiem() {
        #expect(AppointmentTime(hour: 10, minute: 30).label == "오전 10:30")
        #expect(AppointmentTime(hour: 14, minute: 5).label == "오후 2:05")
        #expect(AppointmentTime(hour: 0, minute: 0).label == "오전 12:00")
        #expect(AppointmentTime(hour: 12, minute: 0).label == "오후 12:00")
    }

    @Test("못 읽는 시각은 미정으로 본다")
    func badTimeIsUnset() {
        // 일정 하나 때문에 캘린더 전체가 죽는 것보다 낫다.
        #expect(AppointmentMapping.time(from: "10:30") == AppointmentTime(hour: 10, minute: 30))
        #expect(AppointmentMapping.time(from: "이상한값") == nil)
        #expect(AppointmentMapping.time(from: "99:99") == nil)
        #expect(AppointmentMapping.time(from: nil) == nil)
    }

    @Test("시간이 미정이면 그 사실을 적는다")
    func metaSaysTimeUnset() throws {
        // 빈 자리로 두면 시간이 정해진 것처럼 읽힌다.
        let appointment = try #require(AppointmentMapping.appointment(from: response(time: nil)))
        #expect(AppointmentMapping.meta(appointment) == "시간 미정")
    }

    @Test("둘째 줄은 시각과 카드를 잇는다")
    func metaJoinsTimeAndCard() throws {
        let cards = [LinkedCardResponse(cardId: 7, title: "복부 통증 브리핑 카드")]
        let appointment = try #require(AppointmentMapping.appointment(from: response(cards: cards)))
        #expect(AppointmentMapping.meta(appointment) == "오전 10:30 · 복부 통증 브리핑 카드")
    }

    @Test("모르는 상태는 예정으로 본다")
    func unknownStatusIsScheduled() {
        // 캘린더에서 사라지면 사용자가 일정을 잃었다고 본다.
        #expect(AppointmentStatus.of("NEW_THING") == .scheduled)
        #expect(AppointmentStatus.of(nil) == .scheduled)
        #expect(AppointmentStatus.of("DONE") == .done)
    }

    @Test("모르는 출처는 손으로 만든 것으로 본다")
    func unknownOriginIsManual() {
        #expect(AppointmentOrigin.of("NEW") == .manual)
        #expect(AppointmentOrigin.of("VISIT_FOLLOW_UP") == .visitFollowUp)
    }

    @Test("지난 일정은 진료 완료 배지다")
    func pastAppointmentIsDone() throws {
        let done = try #require(AppointmentMapping.appointment(from: response(status: "DONE")))
        #expect(AppointmentMapping.badge(done)?.text == "진료 완료")
        let canceled = try #require(AppointmentMapping.appointment(from: response(status: "CANCELED")))
        #expect(AppointmentMapping.badge(canceled) == nil)
    }
}

/// 일정 추가가 무엇을 보내는지.
struct ScheduleAddTests {
    @Test("열두시간 표기를 스물네시간으로 옮긴다")
    func twelveHourToTwentyFour() {
        // 오전 12시는 0시, 오후 12시는 12시다.
        #expect(AppointmentMapping.time(isMorning: true, hour: 10, minute: 30) == AppointmentTime(hour: 10, minute: 30))
        #expect(AppointmentMapping.time(isMorning: false, hour: 2, minute: 0) == AppointmentTime(hour: 14, minute: 0))
        #expect(AppointmentMapping.time(isMorning: true, hour: 12, minute: 0) == AppointmentTime(hour: 0, minute: 0))
        #expect(AppointmentMapping.time(isMorning: false, hour: 12, minute: 0) == AppointmentTime(hour: 12, minute: 0))
    }

    @Test("서버가 받는 시각은 두 자리로 간다")
    func wireTimeIsTwoDigits() {
        #expect(AppointmentTime(hour: 9, minute: 5).wire == "09:05")
    }

    @Test("적지 않은 빈 할 일은 보내지 않는다")
    func blankTodosAreDropped() {
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

    @Test("이른 시각이 먼저고 미정은 뒤로 간다")
    func earlierTimeComesFirst() {
        let early = appointment(id: 1, hour: 9)
        let late = appointment(id: 2, hour: 14)
        let unset = appointment(id: 3, hour: nil)

        #expect(AppointmentMapping.isEarlier(early, than: late))
        #expect(!AppointmentMapping.isEarlier(late, than: early))
        #expect(AppointmentMapping.isEarlier(late, than: unset))
        #expect(!AppointmentMapping.isEarlier(unset, than: late))
    }

    @Test("시각이 둘 다 없으면 id 순이다")
    func ordersByIdWithoutTimes() {
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

    @Test("진료 전에는 작성일과 항목 수를 적는다")
    func beforeVisitMetaCountsItems() {
        #expect(CalendarDayModel.cardMeta(summary, isVisited: false, calendar: calendar) == "2026.09.18 · 5항목")
    }

    @Test("진료를 마치면 무엇에 쓰는 카드인지를 적는다")
    func afterVisitMetaNamesCard() {
        #expect(CalendarDayModel.cardMeta(summary, isVisited: true, calendar: calendar) == "브리핑 카드 · 진료실에서 보여줌")
    }

    @Test("기록 줄은 재방문 날짜를 덧붙인다")
    func recordRowAddsFollowUpDate() {
        let record = VisitListItem(
            id: 5, cardId: 7, cardTitle: "위염 초기 · 2주 약", clinicName: nil,
            visitedOn: fixtureDay("2026-09-18"),
            followUp: VisitFollowUp(date: fixtureDay("2026-09-26"), text: nil, approximate: true)
        )
        #expect(CalendarDayView.recordMeta(record) == "위염 초기 · 2주 약 · 09.26 재방문")
    }

    @Test("재방문이 없으면 카드 제목만 적는다")
    func noFollowUpKeepsTitleOnly() {
        let record = VisitListItem(
            id: 5, cardId: 7, cardTitle: "위염 초기", clinicName: nil,
            visitedOn: fixtureDay("2026-09-18"), followUp: nil
        )
        #expect(CalendarDayView.recordMeta(record) == "위염 초기")
    }
}
