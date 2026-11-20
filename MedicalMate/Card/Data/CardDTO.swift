import Foundation

/// `GET /api/me/cards` 한 줄.
struct CardSummaryResponse: Decodable, Sendable {
    let cardId: Int64
    let title: String?
    let chiefComplaint: String?
    let visited: Bool?
    let clinicName: String?
    let createdAt: String?
    /// 카드에 담긴 항목 이름. 셋째 줄에 "부위 · 기간 · 양상"으로 선다.
    let axes: [String]?
}

/// `GET /api/me/home`의 열린 문답. 목록에도 한 줄로 선다.
struct OpenIntakeResponse: Decodable, Sendable {
    let sessionId: Int64
    let siteText: String?
    /// 질문 고르기까지 마쳤는지. true면 "임시 저장", false면 "작성 중"이다.
    let questionsConfirmed: Bool?
    let startedAt: String?
    let progressCurrent: Int?
    let progressTotal: Int?
}
