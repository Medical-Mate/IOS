import Foundation

/// 진료 알림 설정. **계정 값이다.**
///
/// 받을지와 언제 받을지는 기기 취향이 아니라 그 사람의 선택이라 서버에 둔다 — 기기를
/// 바꾸거나 앱을 다시 깔면 "안 받겠다"고 한 사람에게 알림이 다시 간다.
/// Android `core/model/VisitReminders.kt`와 같은 모양이다.
///
/// **알림을 예약하는 것은 앱이다.** 서버가 보내는 것은 없다(FEATURE-SPEC 2.7).
struct ReminderSettings: Sendable, Equatable {
    var beforeVisit = true
    var afterVisit = true
    /// 시간 미정 일정의 전날 알림 시각.
    var beforeVisitTime = ReminderTime.default
    /// 시간 미정 일정의 당일 기록 알림 시각.
    var afterVisitTime = ReminderTime.default
}

/// 알림 시각. 서버가 `HH:mm`으로 주고받는다.
struct ReminderTime: Sendable, Equatable, Comparable {
    var hour: Int
    var minute: Int

    /// 서버의 기본값. 오후 7시다.
    static let `default` = ReminderTime(hour: 19, minute: 0)

    static func < (lhs: ReminderTime, rhs: ReminderTime) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }

    var isMorning: Bool { hour < 12 }

    /// 12시는 0이 아니라 12로 적는다.
    var hour12: Int {
        let base = hour % 12
        return base == 0 ? 12 : base
    }

    /// "오후 7:00". 알림 시간 줄의 값에 쓴다.
    var value: String {
        String(format: "%@ %d:%02d", isMorning ? "오전" : "오후", hour12, minute)
    }

    /// "오후 7시", 분이 있으면 "오후 7시 30분". 토글 설명에 쓴다.
    var words: String {
        minute == 0
            ? "\(isMorning ? "오전" : "오후") \(hour12)시"
            : "\(isMorning ? "오전" : "오후") \(hour12)시 \(minute)분"
    }

    /// 서버로 가는 `HH:mm`.
    var wire: String { String(format: "%02d:%02d", hour, minute) }

    /// **못 읽으면 서버의 기본값으로 본다.** 알림 하나 때문에 설정 전체를 잃지 않는다.
    static func parse(_ text: String?) -> ReminderTime {
        guard let text else { return .default }
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else {
            return .default
        }
        return ReminderTime(hour: parts[0], minute: parts[1])
    }
}
