import Foundation
import Observation

/// 1j-4 브리핑 카드 전체의 상태.
@MainActor
@Observable
final class BriefCardListModel {
    private(set) var sections: [CardMonthSection] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 편집 중인지. 켜면 줄마다 고르는 상자가 서고 아래에 삭제가 선다.
    private(set) var isEditing = false
    private(set) var picked: Set<String> = []

    private let repository: CardRepository
    private let home: HomeRepository

    init(repository: CardRepository, home: HomeRepository) {
        self.repository = repository
        self.home = home
    }

    var pickedCount: Int { picked.count }

    func pickedCount(in section: CardMonthSection) -> Int {
        section.items.count { picked.contains($0.id) }
    }

    func isPicked(_ item: CardListItem) -> Bool { picked.contains(item.id) }

    func load() async {
        errorMessage = nil
        // 목록은 카드 API가, 열린 문답은 홈 응답이 들고 있다. 둘을 합쳐 한 목록으로
        // 만든다 — 1j-4는 아직 카드가 아닌 문답도 한 줄로 보여 준다.
        async let cards = repository.cards()
        async let summary = home.summary()

        switch await cards {
        case .success(let list):
            let openIntake = await openIntakeResponse(from: summary)
            sections = repository.sections(cards: list, openIntake: openIntake)
        case .rejected(let error):
            errorMessage = error.message ?? "불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
    }

    /// 홈 응답의 열린 문답을 목록이 쓰는 모양으로.
    private func openIntakeResponse(from summary: ApiResult<HomeSummary>) -> OpenIntakeResponse? {
        guard case .success(let summary) = summary, let open = summary.openIntake else { return nil }
        return OpenIntakeResponse(
            sessionId: open.sessionId,
            siteText: nil,
            questionsConfirmed: open.step >= open.total,
            startedAt: nil,
            progressCurrent: open.step,
            progressTotal: open.total
        )
    }

    func startEditing() {
        isEditing = true
        picked = []
    }

    func cancelEditing() {
        isEditing = false
        picked = []
    }

    func toggle(_ item: CardListItem) {
        if picked.contains(item.id) {
            picked.remove(item.id)
        } else {
            picked.insert(item.id)
        }
    }

    /// 고른 것을 지운다. **되돌릴 수 없어서 Dialog가 먼저 묻는다.**
    func deletePicked() async {
        let targets = sections.flatMap(\.items).filter { picked.contains($0.id) }
        for item in targets {
            switch item.kind {
            case .card(let id, _):
                _ = await repository.delete(cardId: id)
            case .openIntake(let sessionId, _, _, _):
                _ = await repository.deleteIntake(sessionId: sessionId)
            }
        }
        cancelEditing()
        await load()
    }
}
