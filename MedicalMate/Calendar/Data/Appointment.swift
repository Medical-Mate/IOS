import Foundation

/// 캘린더 일정 하나.
struct Appointment: Sendable, Equatable, Identifiable {
    let id: Int64
    /// 화면의 "서울OO병원 내과 재진". **앱이 병원 · 진료과 · 목적 셋을 합쳐 만든다.**
    let title: String
    /// 병원 + 진료과. 제목에서 목적을 뺀 것이다.
    let clinic: String?
    let on: Date
    /// 없으면 **시간 미정**이다.
    let time: AppointmentTime?
    let status: AppointmentStatus
    let origin: AppointmentOrigin
    let cards: [AppointmentCard]
    let todos: [AppointmentTodo]
}

/// 시각. 서버가 `HH:mm:ss`로 주는데 초를 생략한 판본도 있다.
struct AppointmentTime: Sendable, Equatable, Comparable {
    let hour: Int
    let minute: Int

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }

    /// 화면의 "오전 10:30".
    var label: String {
        let isMorning = hour < 12
        let display = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%@ %d:%02d", isMorning ? "오전" : "오후", display, minute)
    }

    /// 서버가 받는 `HH:mm`.
    var wire: String { String(format: "%02d:%02d", hour, minute) }
}

struct AppointmentCard: Sendable, Equatable, Identifiable {
    let id: Int64
    let title: String?
}

/// 진료 전 할 일 한 줄.
///
/// **서버가 id를 매기지 않는다.** 같은 글이 두 줄 있을 수 있어 글을 열쇠로 쓸 수 없고,
/// 화면의 열쇠는 앱이 차례로 만든다.
struct AppointmentTodo: Sendable, Equatable, Identifiable {
    let id: UUID
    var text: String
    var isDone: Bool

    init(id: UUID = UUID(), text: String, isDone: Bool = false) {
        self.id = id
        self.text = text
        self.isDone = isDone
    }
}

/// **모르는 값은 예정으로 본다.** 서버가 상태를 늘렸을 때 일정을 숨기면 사용자는
/// 일정을 잃었다고 본다.
enum AppointmentStatus: Sendable {
    case scheduled, done, canceled

    static func of(_ value: String?) -> AppointmentStatus {
        switch value {
        case "DONE": .done
        case "CANCELED": .canceled
        default: .scheduled
        }
    }
}

/// 어디서 만든 일정인지. **모르는 값은 손으로 만든 것으로 본다** — 서버가 갈래를 늘렸을
/// 때 일정을 잃는 것보다 낫다.
enum AppointmentOrigin: Sendable {
    case manual, visitFollowUp

    static func of(_ value: String?) -> AppointmentOrigin {
        value == "VISIT_FOLLOW_UP" ? .visitFollowUp : .manual
    }

    var wire: String {
        switch self {
        case .manual: "MANUAL"
        case .visitFollowUp: "VISIT_FOLLOW_UP"
        }
    }
}
