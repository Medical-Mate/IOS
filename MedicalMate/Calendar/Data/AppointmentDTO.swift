import Foundation

/// `GET /api/me/appointments`.
///
/// **날짜와 시각이 따로 온다.** 전에는 `scheduledAt` 하나였는데 서버가 갈랐다 — 날짜로
/// 견주므로 시간대 때문에 하루가 밀리지 않고, `scheduledTime`이 없으면 시간 미정이다.
struct AppointmentResponse: Decodable, Sendable {
    let appointmentId: Int64
    let clinicName: String?
    let department: String?
    /// "재진"처럼 무엇 하러 가는지.
    let purpose: String?
    let scheduledOn: String
    let scheduledTime: String?
    let status: String?
    let origin: String?
    let cards: [LinkedCardResponse]?
    let todos: [TodoResponse]?
}

struct LinkedCardResponse: Decodable, Sendable {
    let cardId: Int64
    let title: String?
}

struct TodoResponse: Codable, Sendable {
    let text: String
    let done: Bool?
}

/// `scheduledOn`만 필수다. 시각을 빼면 "시간 미정"으로 만들어진다.
struct CreateAppointmentRequest: Encodable, Sendable {
    let clinicName: String?
    let department: String?
    let purpose: String?
    let scheduledOn: String
    let scheduledTime: String?
    let cardIds: [Int64]
    let origin: String?
    let todos: [TodoResponse]
}

/// 보낸 필드만 바뀐다.
///
/// **시각을 다시 미정으로 되돌리려면 `clearTime`을 세운다.** `scheduledTime = nil`은
/// "안 바꿈"이다 — null을 두 뜻으로 쓰면 시각을 지울 방법이 없어서 서버가 플래그를
/// 따로 뒀다. **날짜는 지울 수 없다** — 날짜 없는 일정은 캘린더에 그릴 자리가 없다.
struct UpdateAppointmentRequest: Encodable, Sendable {
    var clinicName: String?
    var department: String?
    var purpose: String?
    var scheduledOn: String?
    var scheduledTime: String?
    var clearTime: Bool?
    var status: String?
    /// 통째로 갈아끼운다. `nil`이 "안 바꿈", `[]`가 "전부 뗌"이다.
    var cardIds: [Int64]?
    /// 통째로 갈아끼운다. **지운 줄이 남지 않으려면 화면에 있는 것을 전부 보낸다.**
    var todos: [TodoResponse]?
}
