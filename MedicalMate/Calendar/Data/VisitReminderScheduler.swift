import Foundation
import UserNotifications

/// 알림을 기기에 건다.
///
/// **무엇을 걸지는 ``VisitReminderPlan``이 정하고 이쪽은 거는 일만 한다.** 그 경계로
/// 나눈 이유는 거는 쪽이 `UserNotifications`에 묶여 테스트가 닿지 않기 때문이다.
/// Android도 같은 경계다(`planVisitReminders` ↔ `ReminderScheduler`).
///
/// **`UNCalendarNotificationTrigger`로 건다.** 시스템이 예약을 들고 있어 재부팅을
/// 넘긴다 — Android가 `WorkManager`로 푼 것과 같은 자리를 iOS는 공짜로 얻는다.
protocol VisitReminderScheduling: Sendable {
    /// 걸린 것을 모두 지우고 `reminders`만 남긴다.
    func replaceAll(_ reminders: [VisitReminder]) async
    func cancelAll() async
}

struct VisitReminderScheduler: VisitReminderScheduling {
    var center: UNUserNotificationCenter { .current() }
    var calendar: Calendar = .current

    /// 걸린 것을 모두 지우고 다시 건다.
    ///
    /// **권한을 여기서 묻지 않는다.** 알림을 걸 일이 생겼을 때 묻는 것이 맞고, 그 자리는
    /// 설정 화면의 토글이다. 허락이 없으면 `add`가 조용히 실패한다 — 기록은 서버에 남아
    /// 있어 허락한 뒤 다시 걸면 된다.
    func replaceAll(_ reminders: [VisitReminder]) async {
        await cancelAll()
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.notificationTitle
            content.body = [reminder.title, reminder.actionTitle]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            content.sound = .default

            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.at)
            let request = UNNotificationRequest(
                identifier: reminder.id,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            )
            try? await center.add(request)
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter(VisitReminderScheduler.isOurs)
        center.removePendingNotificationRequests(withIdentifiers: ours)
    }

    /// 우리가 건 것인지. **남의 알림을 지우지 않는다** — `removeAllPending`은 이 앱이
    /// 나중에 걸게 될 다른 알림까지 쓸어 간다.
    nonisolated static func isOurs(_ identifier: String) -> Bool {
        identifier.hasPrefix(VisitReminder.Kind.beforeVisit.rawValue)
            || identifier.hasPrefix(VisitReminder.Kind.afterVisit.rawValue)
    }
}
