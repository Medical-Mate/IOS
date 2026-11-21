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

    @Test func 예정이_기록보다_먼저_보인다() {
        // 겹치면 아직 할 일이 남은 쪽을 보인다.
        let days = september.days(calendar: calendar, selected: nil, today: nil, scheduled: [12], records: [12, 4])
        #expect(days.first { $0.date == 12 }?.dot == .scheduled)
        #expect(days.first { $0.date == 4 }?.dot == .record)
        #expect(days.first { $0.date == 5 }?.dot == MMCalendarDay.Dot.none)
    }

    @Test func 달을_넘기면_해가_바뀐다() {
        let december = CalendarMonth(year: 2026, month: 12)
        #expect(december.advanced(by: 1, calendar: calendar) == CalendarMonth(year: 2027, month: 1))
        #expect(CalendarMonth(year: 2026, month: 1).advanced(by: -1, calendar: calendar)
            == CalendarMonth(year: 2025, month: 12))
    }

    @Test func 머리와_구간_제목의_모양() {
        #expect(september.title == "2026년 9월")
        let day = september.date(day: 12, calendar: calendar)!
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

    @Test func 시간이_미정이면_그_사실을_적는다() {
        // 빈 자리로 두면 시간이 정해진 것처럼 읽힌다.
        let appointment = AppointmentMapping.appointment(from: response(time: nil))!
        #expect(AppointmentMapping.meta(appointment) == "시간 미정")
    }

    @Test func 둘째_줄은_시각과_카드를_잇는다() {
        let cards = [LinkedCardResponse(cardId: 7, title: "복부 통증 브리핑 카드")]
        let appointment = AppointmentMapping.appointment(from: response(cards: cards))!
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

    @Test func 지난_일정은_진료_완료_배지다() {
        let done = AppointmentMapping.appointment(from: response(status: "DONE"))!
        #expect(AppointmentMapping.badge(done)?.text == "진료 완료")
        let canceled = AppointmentMapping.appointment(from: response(status: "CANCELED"))!
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
            AppointmentTodo(text: "", isDone: true),
        ]
        let cleaned = AppointmentMapping.cleaned(todos)
        #expect(cleaned.count == 1)
        #expect(cleaned.first?.text == "복용 중인 약 챙기기")
    }
}
