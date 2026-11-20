import Foundation

// MARK: - 보내는 것

/// `POST /api/sessions` — 부위와 강도를 함께 보내 문답을 연다.
///
/// **강도를 고르고 "다음"을 누를 때 한 번만 연다**(FEATURE-SPEC 2.3). 문답은 강도를
/// 다시 묻지 않고 이 값이 질문 후보와 카드에 들어간다.
struct StartSessionRequest: Encodable, Sendable {
    /// 온톨로지 id 하나. 구역까지 골랐으면 `SUR:*`, 앵커까지면 `ANC:*`.
    ///
    /// **배열이 아니라 하나다.** Android는 `siteCodes` 배열로 보내다가 백엔드에 그 필드가
    /// 없어 조용히 버려졌다(AOS #300). 부위 이름만 넘어가서 첫 질문이 부위에 묶이지 않았다.
    let siteNodeId: String?
    /// `LEFT` · `RIGHT`. **좌우가 있는 부위에만 보낸다** — 없는 부위에 보내면 400이다.
    let side: String?
    /// 사람이 읽는 표현. 문답 첫 문장에 그대로 들어간다.
    let siteText: String?
    /// `ONDEVICE`면 폰이 뽑는다. 비우면 서버다.
    ///
    /// 온디바이스 LLM은 1차 출시 제외 제안 상태다(AOS-IOS-DIFF D2). 비워서 서버로 간다.
    let profile: String?
    let severity: SeverityRequest?
}

/// 강도. **1~5 서열척도다. NRS 0~10이 아니다.**
///
/// `label`을 앱이 보낸다. 서버가 들고 있으면 문구를 바꿀 때마다 배포해야 하고,
/// 이것은 디자인 카피라 서버 것이 아니다.
struct SeverityRequest: Encodable, Sendable {
    let level: Int
    let label: String
}

/// `POST /api/sessions/{id}/messages`.
struct SendMessageRequest: Encodable, Sendable {
    let text: String
    /// `STT` · `TEXT`. **음성으로 말했어도 오디오를 보내지 않는다** — 앱이 바꾼 글만 간다.
    let inputMethod: String
}

/// `PUT /api/sessions/{id}/questions`. 체크한 줄만 **화면 순서대로** 통째로 보낸다.
struct QuestionsRequest: Encodable, Sendable {
    let questions: [String]
}

// MARK: - 받는 것

struct SessionResponse: Decodable, Sendable {
    let sessionId: Int64
    let status: String?
    let siteNodeId: String?
    let siteText: String?
    let progress: ProgressResponse?
    let messages: [MessageResponse]?
    let severity: SeverityResponse?
    /// 환자가 확정한 것.
    let questions: [String]?
    /// AI가 고른 후보. 확정과 다르다 — 이쪽은 제안이고 저쪽은 확정이다.
    let questionCandidates: [QuestionCandidateResponse]?
}

/// 한 턴의 결과.
struct TurnResponse: Decodable, Sendable {
    let sessionId: Int64
    let status: String?
    /// AI의 다음 질문.
    let reply: String?
    /// 문답이 끝났는지. **끝난 뒤 또 보내도 오류가 아니라 마지막 문장만 돌아온다.**
    let ended: Bool?
    let progress: ProgressResponse?
    let messages: [MessageResponse]?
    /// 추천 질문. **문답이 끝난 턴의 응답에 실려 온다.** 그 밖에는 비어 있다.
    let questionCandidates: [QuestionCandidateResponse]?
}

/// `role`은 `AI` 또는 `USER`.
struct MessageResponse: Decodable, Sendable {
    let seq: Int64
    let role: String
    let text: String
}

struct SeverityResponse: Decodable, Sendable {
    let level: Int
    let label: String?
}

struct ProgressResponse: Decodable, Sendable {
    let current: Int
    let total: Int
}

/// `rank`는 **낮을수록 먼저** 보여줄 것. 서버가 정렬해 주지만 순서를 믿지 않는다.
struct QuestionCandidateResponse: Decodable, Sendable {
    let text: String
    let rank: Int?
}
