import Foundation
import Observation

/// 홈 화면의 상태.
@MainActor
@Observable
final class HomeModel {
    private(set) var summary = HomeSummary()
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    private let repository: HomeRepository

    init(repository: HomeRepository) {
        self.repository = repository
    }

    /// 화면으로 돌아올 때마다 다시 읽는다 — 다른 화면에서 카드를 만들거나 일정을
    /// 잡고 돌아오면 홈이 바뀌어 있어야 한다.
    func load() async {
        errorMessage = nil
        switch await repository.summary() {
        case .success(let summary):
            self.summary = summary
        case .rejected(let error):
            errorMessage = error.message ?? "불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
    }

    /// 어떤 배너를 맨 위에 둘지.
    ///
    /// 와이어프레임의 다섯 장 가운데 **지금 데이터로 가를 수 있는 둘만** 쓴다 —
    /// 카드도 일정도 없으면 `처음`(`1n-2`), 그 밖에는 `진료 후`(`1n-1`)다.
    ///
    /// 나머지 셋(내일 진료 · 카드 저장 · 헤이 메이트)은 홈 응답에 가를 값이 없다.
    /// `docs/FEATURE-SPEC.md` 2.9에 규칙이 적혀 있고, 백엔드가 그 값을 주면 여기서
    /// 갈라 붙인다. **짐작해서 돌리지 않는다.**
    var banner: HomeBannerKind {
        summary.isEmpty ? .first : .afterVisit
    }
}

/// 홈 맨 위 배너. 와이어프레임 `1n-2` · `1n-1`.
enum HomeBannerKind {
    /// `1n-2 · 홈 · 처음 (기록 없음)`. 링크도 장 수도 없고 높이가 334다.
    case first
    /// `1n-1 · 홈 · 기록 있음 · 배너 1 진료 후`.
    case afterVisit

    var title: String {
        switch self {
        case .first: "처음 오셨네요,\n반가워요"
        case .afterVisit: "진료 잘\n다녀오셨나요?"
        }
    }

    var message: String {
        switch self {
        case .first: "아픈 곳을 짚고 몇 가지만 답하면\n진료실에서 보여줄 카드가 돼요."
        case .afterVisit: "서울OO병원 내과에서 들은 말을\n잊기 전에 남겨두세요."
        }
    }

    var link: (title: String, counter: String)? {
        switch self {
        case .first: nil
        case .afterVisit: ("진료 후 기록하기", "1 / 5")
        }
    }
}
