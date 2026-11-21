import Foundation

/// `GET /api/visits/{visitId}`.
struct VisitResponse: Decodable, Sendable {
    let visitId: Int64
    let cardId: Int64?
    let clinicName: String?
    let visitedOn: String?
    /// **못 찾은 항목은 빈 값이 아니라 키가 없다.**
    let axes: [String: VisitAxisResponse]?
    let followUp: FollowUpResponse?
    let patientNotes: [String]?
    /// 환자가 적은 원문. 상세에만 온다.
    let rawNote: String?
}

/// 축 하나.
///
/// 카드의 축과 모양이 같지만 **타입을 함께 쓰지 않는다.** 한 도메인이 다른 도메인을
/// 참조하지 않고, 두 계약이 지금 같아 보여도 같이 움직인다는 보장이 없다.
struct VisitAxisResponse: Decodable, Sendable {
    let status: String?
    let value: String?
}

/// `approximate`는 "2주 뒤"처럼 범위로 말한 것.
struct FollowUpResponse: Decodable, Sendable {
    let date: String?
    let text: String?
    let approximate: Bool?
}

/// `GET /api/me/visits` 한 줄. **원문이 담기지 않는다.**
struct VisitSummaryResponse: Decodable, Sendable {
    let visitId: Int64
    let cardId: Int64?
    let cardTitle: String?
    let clinicName: String?
    let visitedOn: String
    let followUp: FollowUpResponse?
}

/// `POST /api/visits/classify` — 적어 둔 메모를 항목으로 나눈다. **저장하지 않는다.**
struct ClassifyMemoRequest: Encodable, Sendable {
    let memo: String
    let visitedOn: String?
    let clinicName: String?
    /// 직전 응답의 분류. **있으면 반드시 함께 보낸다** — 안 보내면 줄 하나를 옮길 때마다
    /// AI 모델 호출이 나가고 그 비용이 서버 크레딧에서 빠진다.
    let labels: [String: String]?
}

struct ClassifyMemoResponse: Decodable, Sendable {
    let axes: [String: VisitAxisResponse]?
    let labels: [String: String]?
    let patientNotes: [String]?
    let followUp: FollowUpResponse?
}

/// `POST /api/cards/{cardId}/visit` — 진료 후 기록을 남긴다.
///
/// **확정한 카드에만** 남길 수 있고 카드 하나에 기록 하나다. **모든 항목이 선택이라
/// `rawNote`만 적어도 저장된다** — 병원을 막 나온 사람에게 필수 입력을 요구하면
/// 아무것도 안 남는다.
///
/// **`status`와 `source`를 보내지 않는다.** 값이 있으면 `FILLED`, 비었으면 `UNKNOWN`이고
/// 출처는 서버가 박는다. 앱이 "AI가 뽑았다"고 주장할 수 있으면 의사 화면의 출처 표시가
/// 의미를 잃는다.
struct CreateVisitRequest: Encodable, Sendable {
    let clinicName: String?
    let visitedOn: String?
    let axes: [VisitAxisRequest]
    let followUp: FollowUpRequest?
    let patientNotes: [String]
    let rawNote: String?
}

struct VisitAxisRequest: Encodable, Sendable {
    let axis: String
    let value: String
}

struct FollowUpRequest: Encodable, Sendable {
    let date: String?
    let text: String?
    let approximate: Bool
}
