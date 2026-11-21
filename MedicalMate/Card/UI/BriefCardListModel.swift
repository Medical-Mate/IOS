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
    /// 기록 목록(1j-1)만 쓴다. 브리핑 카드 전체(1j-4)에는 기록 줄이 없다.
    private let visits: VisitRepository?

    init(repository: CardRepository, home: HomeRepository, visits: VisitRepository? = nil) {
        self.repository = repository
        self.home = home
        self.visits = visits
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
        async let records = visitList()

        switch await cards {
        case .success(let list):
            let openIntake = await openIntakeResponse(from: summary)
            // 기록 목록(1j-1)은 진료를 마친 기록까지 한 목록에 세운다.
            if let visits = await records {
                sections = repository.sections(cards: list, visits: visits, openIntake: openIntake)
            } else {
                sections = repository.sections(cards: list, openIntake: openIntake)
            }
        case .rejected(let error):
            // **무엇을 못 읽었는지 적는다.** 같은 목록이 두 화면을 겸해 말이 갈린다
            // (Android `record_failed_title` · `brief_card_list_failed_title`).
            errorMessage = error.message ?? (visits == nil ? "카드를 불러오지 못했어요" : "기록을 불러오지 못했어요")
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
    }

    private func visitList() async -> [VisitSummaryResponse]? {
        guard let visits else { return nil }
        guard case .success(let list) = await visits.visits() else { return [] }
        return list
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
            case .visit(let id, _):
                _ = await visits?.delete(visitId: id)
            }
        }
        cancelEditing()
        await load()
    }
}
