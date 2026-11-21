import Foundation

/// 진료 후 기록.
///
/// **녹음은 저장하지 않는다.** 오디오 컬럼 자체가 없고, 음성으로 적어도 변환한 글만 간다.
struct VisitRepository: Sendable {
    let client: ApiClient

    /// 적어 둔 메모를 항목으로 나눈다. **저장하지 않는다** — 카드에도 매이지 않아서
    /// 저장 전에 부를 수 있다.
    func classify(
        memo: String,
        visitedOn: String?,
        clinicName: String?,
        labels: [String: String]?
    ) async -> ApiResult<ClassifyMemoResponse> {
        let body = ClassifyMemoRequest(
            memo: memo,
            visitedOn: visitedOn,
            clinicName: clinicName,
            labels: labels
        )
        return await client.send(.post("api/visits/classify", body: body), as: ClassifyMemoResponse.self)
    }

    /// 기록을 남긴다. **확정한 카드에만** 남길 수 있고 카드 하나에 기록 하나다.
    func create(cardId: Int64, request: CreateVisitRequest) async -> ApiResult<VisitResponse> {
        await client.send(.post("api/cards/\(cardId)/visit", body: request), as: VisitResponse.self)
    }

    func visit(id: Int64) async -> ApiResult<VisitResponse> {
        await client.send(.get("api/visits/\(id)"), as: VisitResponse.self)
    }

    func visits() async -> ApiResult<[VisitSummaryResponse]> {
        await client.send(.get("api/me/visits"), as: [VisitSummaryResponse].self)
    }

    /// 기록 하나를 지운다. **카드는 남는다** — 전에는 이 자리가 없어서 기록 삭제가 카드
    /// 삭제로 나갔고, 기록 한 건을 지우려던 사람이 카드와 문답까지 잃었다.
    func delete(visitId: Int64) async -> ApiResult<Void> {
        await client.send(.delete("api/visits/\(visitId)"))
    }
}
