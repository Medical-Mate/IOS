import Foundation

/// 기기에 걸 알림 하나.
///
/// **무엇을 걸지(이 파일)와 거는 일(`VisitReminderScheduler`)을 나눈다.** 거는 쪽은
/// `UserNotifications`에 묶여 테스트가 닿지 않지만 규칙은 그렇지 않다.
struct VisitReminder: Sendable, Equatable, Identifiable {
    enum Kind: String, Sendable {
        /// 진료 전. "내일 진료가 있어요".
        case beforeVisit
        /// 진료 뒤 기록. "오늘 진료 다녀오셨어요?".
        case afterVisit
    }

    let appointmentId: Int64
    let kind: Kind
    /// 울릴 때.
    let at: Date
    /// 알림에 실을 일정 이름. "서울OO병원 내과 재진".
    let title: String

    var id: String { "\(kind.rawValue)-\(appointmentId)" }

    /// 알림 제목.
    ///
    /// **시각을 정한 진료는 "오늘"이라고 하지 않는다** — 2시간 뒤에 울리므로 그 날이
    /// 맞지만, 시간 미정이면 당일 저녁에 울려서 "오늘"이 자연스럽다.
    var notificationTitle: String {
        switch kind {
        case .beforeVisit: "내일 진료가 있어요"
        case .afterVisit: isTimed ? "진료 잘 다녀오셨어요?" : "오늘 진료 다녀오셨어요?"
        }
    }

    var actionTitle: String {
        switch kind {
        case .beforeVisit: "일정 확인하기"
        case .afterVisit: "들은 말 남기기"
        }
    }

    /// 시각을 정한 일정에서 나온 알림인지. 제목이 갈린다.
    var isTimed: Bool

    init(appointmentId: Int64, kind: Kind, at: Date, title: String, isTimed: Bool) {
        self.appointmentId = appointmentId
        self.kind = kind
        self.at = at
        self.title = title
        self.isTimed = isTimed
    }
}

/// 무엇을 걸지 정한다. **순수 함수다** — 기기도 시계도 건드리지 않는다.
enum VisitReminderPlan {
    /// - Parameters:
    ///   - appointments: 다가오는 일정. 취소·완료는 여기서 걸러진다.
    ///   - settings: 토글 둘과 시간 미정일 때 쓸 시각.
    ///   - now: 지금. **이미 지난 알림은 걸지 않는다.**
    static func reminders(
        appointments: [Appointment],
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar
    ) -> [VisitReminder] {
        appointments.flatMap { appointment in
            reminders(for: appointment, settings: settings, now: now, calendar: calendar)
        }
    }

    private static func reminders(
        for appointment: Appointment,
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar
    ) -> [VisitReminder] {
        // **다녀왔거나 취소한 일정에는 걸지 않는다.** 알릴 일이 끝났다.
        guard appointment.status == .scheduled else { return [] }

        let timed = appointment.time != nil
        var planned: [VisitReminder] = []

        if settings.beforeVisit,
           let at = beforeVisitAt(appointment, settings: settings, calendar: calendar) {
            planned.append(VisitReminder(
                appointmentId: appointment.id, kind: .beforeVisit,
                at: at, title: appointment.title, isTimed: timed
            ))
        }
        if settings.afterVisit,
           let at = afterVisitAt(appointment, settings: settings, calendar: calendar) {
            planned.append(VisitReminder(
                appointmentId: appointment.id, kind: .afterVisit,
                at: at, title: appointment.title, isTimed: timed
            ))
        }
        // 이미 지난 것은 뺀다. 둘 다 지났으면 아무것도 남지 않는다.
        return planned.filter { $0.at > now }
    }

    /// 진료 전. **시각을 정했으면 24시간 전, 미정이면 전날의 정한 시각.**
    static func beforeVisitAt(
        _ appointment: Appointment,
        settings: ReminderSettings,
        calendar: Calendar
    ) -> Date? {
        if let time = appointment.time {
            guard let at = calendar.date(
                bySettingHour: time.hour, minute: time.minute, second: 0, of: appointment.on
            ) else { return nil }
            return calendar.date(byAdding: .day, value: -1, to: at)
        }
        guard let previous = calendar.date(byAdding: .day, value: -1, to: appointment.on) else { return nil }
        return calendar.date(
            bySettingHour: settings.beforeVisitTime.hour,
            minute: settings.beforeVisitTime.minute,
            second: 0,
            of: previous
        )
    }

    /// 진료 뒤 기록. **시각을 정했으면 2시간 뒤, 미정이면 당일의 정한 시각.**
    static func afterVisitAt(
        _ appointment: Appointment,
        settings: ReminderSettings,
        calendar: Calendar
    ) -> Date? {
        if let time = appointment.time {
            guard let at = calendar.date(
                bySettingHour: time.hour, minute: time.minute, second: 0, of: appointment.on
            ) else { return nil }
            return calendar.date(byAdding: .hour, value: 2, to: at)
        }
        return calendar.date(
            bySettingHour: settings.afterVisitTime.hour,
            minute: settings.afterVisitTime.minute,
            second: 0,
            of: appointment.on
        )
    }
}
