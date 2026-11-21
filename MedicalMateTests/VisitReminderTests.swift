import Foundation
import Testing
@testable import MedicalMate

/// 무엇을 언제 걸지(`VisitReminderPlan`). 기기도 시계도 건드리지 않는 자리다.
struct VisitReminderPlanTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    /// 2026-09-25의 그 시각.
    private func moment(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: fixtureDay("2026-09-25")) ?? .distantPast
    }

    private func appointment(
        time: AppointmentTime? = AppointmentTime(hour: 10, minute: 30),
        status: AppointmentStatus = .scheduled
    ) -> Appointment {
        Appointment(
            id: 9, title: "서울OO병원 내과 재진", clinic: "서울OO병원 내과",
            on: fixtureDay("2026-09-25"), time: time,
            status: status, origin: .manual, cards: [], todos: []
        )
    }

    private func plan(
        _ appointment: Appointment,
        settings: ReminderSettings = ReminderSettings(),
        now: Date
    ) -> [VisitReminder] {
        VisitReminderPlan.reminders(
            appointments: [appointment], settings: settings, now: now, calendar: calendar
        )
    }

    @Test func 시각을_정한_일정은_24시간_전과_2시간_뒤다() {
        let planned = plan(appointment(), now: fixtureDay("2026-09-01"))
        #expect(planned.count == 2)
        // 09-25 10:30 진료 → 09-24 10:30에 알린다.
        #expect(planned.first { $0.kind == .beforeVisit }?.at
            == calendar.date(bySettingHour: 10, minute: 30, second: 0, of: fixtureDay("2026-09-24")))
        #expect(planned.first { $0.kind == .afterVisit }?.at == moment(12, 30))
    }

    @Test func 시간_미정이면_전날과_당일의_정한_시각이다() {
        let planned = plan(appointment(time: nil), now: fixtureDay("2026-09-01"))
        #expect(planned.first { $0.kind == .beforeVisit }?.at
            == calendar.date(bySettingHour: 19, minute: 0, second: 0, of: fixtureDay("2026-09-24")))
        #expect(planned.first { $0.kind == .afterVisit }?.at == moment(19))
    }

    @Test func 시간_미정의_기본_시각은_오후_7시다() {
        #expect(ReminderTime.default == ReminderTime(hour: 19, minute: 0))
    }

    @Test func 꺼_둔_쪽은_걸지_않는다() {
        var settings = ReminderSettings()
        settings.beforeVisit = false
        let planned = plan(appointment(), settings: settings, now: fixtureDay("2026-09-01"))
        #expect(planned.map(\.kind) == [.afterVisit])
    }

    @Test func 이미_지난_알림은_빼고_남은_것만_건다() {
        // 진료 당일 11시. 전날 알림은 지났고 2시간 뒤는 남았다.
        let planned = plan(appointment(), now: moment(11))
        #expect(planned.map(\.kind) == [.afterVisit])
    }

    @Test func 둘_다_지났으면_걸지_않는다() {
        #expect(plan(appointment(), now: moment(23)).isEmpty)
    }

    @Test func 다녀왔거나_취소한_일정에는_걸지_않는다() {
        #expect(plan(appointment(status: .done), now: fixtureDay("2026-09-01")).isEmpty)
        #expect(plan(appointment(status: .canceled), now: fixtureDay("2026-09-01")).isEmpty)
    }

    @Test func 알림에_실을_이름을_들고_간다() {
        let planned = plan(appointment(), now: fixtureDay("2026-09-01"))
        #expect(planned.allSatisfy { $0.title == "서울OO병원 내과 재진" })
        #expect(planned.allSatisfy { $0.appointmentId == 9 })
    }

    @Test func 시각을_정한_진료는_오늘이라고_하지_않는다() {
        // 2시간 뒤에 울리므로 그 날이 맞지만, 미정이면 당일 저녁이라 "오늘"이 자연스럽다.
        let timed = plan(appointment(), now: fixtureDay("2026-09-01"))
        #expect(timed.first { $0.kind == .afterVisit }?.notificationTitle == "진료 잘 다녀오셨어요?")
        let untimed = plan(appointment(time: nil), now: fixtureDay("2026-09-01"))
        #expect(untimed.first { $0.kind == .afterVisit }?.notificationTitle == "오늘 진료 다녀오셨어요?")
        #expect(untimed.first { $0.kind == .beforeVisit }?.notificationTitle == "내일 진료가 있어요")
    }

    @Test func 알림마다_할_일을_적는다() {
        let planned = plan(appointment(), now: fixtureDay("2026-09-01"))
        #expect(planned.first { $0.kind == .beforeVisit }?.actionTitle == "일정 확인하기")
        #expect(planned.first { $0.kind == .afterVisit }?.actionTitle == "들은 말 남기기")
    }

    @Test func 우리가_건_것만_지운다() {
        // `removeAllPending`은 이 앱이 나중에 걸 다른 알림까지 쓸어 간다.
        #expect(VisitReminderScheduler.isOurs("beforeVisit-9"))
        #expect(VisitReminderScheduler.isOurs("afterVisit-9"))
        #expect(!VisitReminderScheduler.isOurs("medication-3"))
    }
}
