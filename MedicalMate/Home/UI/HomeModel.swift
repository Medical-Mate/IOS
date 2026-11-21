import Foundation
import Observation

/// 홈 화면의 상태.
@MainActor
@Observable
final class HomeModel {
    private(set) var summary = HomeSummary()
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 어떤 배너를 맨 위에 둘지. `load()`가 채운다.
    private(set) var lead: HomeLead = .other
    /// 배너 다섯 장. 처음 온 사람은 한 장이다.
    private(set) var banners: [HomeBannerPage] = []
    /// `.other`일 때 첫 장에 올릴 자리. **화면이 살아 있는 동안 같은 장을 유지한다.**
    private let restIndex = Int.random(in: 0..<HomeBannerPage.rest(latestCardId: nil).count)

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
            lead = await repository.lead(for: summary)
            banners = HomeBannerPage.pages(
                lead: lead,
                latestCardId: summary.recentCards.first.flatMap { Int64($0.id) },
                restIndex: restIndex
            )
        case .rejected(let error):
            errorMessage = error.message ?? "불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
    }

}

/// 홈 맨 위 배너의 글. 와이어프레임 `1n-2` · `1n-1` · `1n-1-4` · `1n-1-5`.
///
/// **배너 2~5(예약 문자 · 일정 알림 · 카드 저장 · 헤이 메이트)는 아직 세우지 않는다.**
/// 사진 다섯 장을 못 받아서이고, 가르는 규칙 자체는 `docs/FEATURE-SPEC.md` 2.9에 있다.
enum HomeBannerCopy {
    static func title(_ page: HomeBannerPage) -> String {
        switch page {
        case .welcome: "처음 오셨네요,\n반가워요"
        case .today: "진료 잘\n다녀오셨나요?"
        case .tomorrow: "내일 진료 전에\n카드 한 번 볼까요?"
        case .cardReady: "카드는 준비됐어요,\n언제 진료 가실래요?"
        case .message: "예약 문자,\n그대로 넘겨주세요"
        case .schedule: "진료 날짜,\n대신 기억할게요"
        case .saveCard: "카드를 사진첩에\n넣어둘까요?"
        case .mate: "\u{201C}헤이 메이트\u{201D}라고\n불러보세요"
        }
    }

    /// **병원 이름을 글에 넣는다.** 없으면 "진료실에서"로 받친다 — 빈 자리를 남기거나
    /// 표본에 있던 병원 이름을 그대로 적지 않는다.
    static func message(_ page: HomeBannerPage) -> String {
        switch page {
        case .welcome:
            "아픈 곳을 짚고 몇 가지만 답하면\n진료실에서 보여줄 카드가 돼요."
        case .today(let clinic, _, _, _):
            "\(clinic ?? "진료실")에서 들은 말을\n잊기 전에 남겨두세요."
        case .tomorrow(let time, let clinic, _):
            tomorrowMessage(time: time, clinic: clinic)
        case .cardReady(_, let symptom):
            "\(symptom) 카드가 기다리고 있어요.\n진료 날짜를 정하면 미리 알려드려요."
        case .message:
            "병원에서 받은 예약 문자를 공유하면\n날짜와 시간이 알아서 채워져요."
        case .schedule:
            "일정을 넣어두면 진료 전날과\n진료 뒤에 한 번씩 알려드려요."
        case .saveCard:
            "인터넷이 안 될 때도\n사진첩에서 바로 꺼내 보여주세요."
        case .mate:
            "다음 진료가 언제인지 묻거나\n들은 말을 말로 남길 수 있어요."
        }
    }

    /// "내일 오전 10:30 서울OO병원 내과예요." 시각도 병원도 없으면 "내일 진료예요."
    static func tomorrowMessage(time: String?, clinic: String?) -> String {
        let detail = [time, clinic].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " ")
        let head = detail.isEmpty ? "내일 진료예요." : "내일 \(detail)예요."
        return "\(head)\n달라진 점이 있으면 오늘 고쳐두세요."
    }

    /// 배너 아래 링크. **처음 온 사람에게는 링크도 장 수도 없다**(`1n-2`).
    static func link(_ page: HomeBannerPage, index: Int, total: Int) -> (title: String, counter: String)? {
        guard let title = linkTitle(page) else { return nil }
        return (title, counter(index: index, total: total))
    }

    static func linkTitle(_ page: HomeBannerPage) -> String? {
        switch page {
        case .welcome: nil
        case .today: "진료 후 기록하기"
        case .tomorrow: "카드 다시 보기"
        case .cardReady: "진료 일정 잡기"
        case .message: "방법 보기"
        case .schedule: "일정 추가하기"
        case .saveCard: "카드 저장하기"
        case .mate: "메이트에게 말해보기"
        }
    }

    /// 몇 번째 장인지. "1 / 5".
    static func counter(index: Int, total: Int) -> String { "\(index + 1) / \(total)" }
}
