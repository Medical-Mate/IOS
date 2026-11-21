import Foundation

/// 다가오는 일정과 설정을 읽어 알림을 다시 건다.
///
/// **한 자리에 모은다.** 다시 걸어야 하는 때가 여럿이라(토글 · 알림 시각 · 일정 추가 ·
/// 일정 삭제 · 로그인) 저마다 읽고 계산하면 규칙이 갈린다.
struct VisitReminders: Sendable {
    let appointments: AppointmentRepository
    let settings: SettingsRepository
    let scheduler: any VisitReminderScheduling
    var calendar: Calendar = .current
    var now: @Sendable () -> Date = { Date() }

    /// 서버에서 다시 읽어 전부 다시 건다.
    ///
    /// **못 읽으면 걸린 것을 건드리지 않는다.** 지우고 나서 못 읽으면 알림이 통째로
    /// 사라지는데, 그건 못 읽은 것보다 나쁘다.
    func refresh() async {
        guard case .success(let list) = await appointments.upcoming(),
              case .success(let reminderSettings) = await settings.reminders()
        else { return }

        await scheduler.replaceAll(
            VisitReminderPlan.reminders(
                appointments: list.compactMap(AppointmentMapping.appointment(from:)),
                settings: reminderSettings,
                now: now(),
                calendar: calendar
            )
        )
    }

    /// 로그아웃. **걸린 것을 지운다** — 다음 사람의 기기에 앞 사람의 진료가 뜨면 안 된다.
    func clear() async {
        await scheduler.cancelAll()
    }
}
