import Foundation
import Testing
@testable import MedicalMate

/// 홈이 서버 값을 화면의 글로 바꾸는 규칙을 본다.
///
/// 날짜·시각 꾸미기는 저장소에 모아 두었다. 같은 규칙을 화면마다 다시 쓰면 갈린다.
@MainActor
struct HomeTests {
    private func repository(today: String) -> HomeRepository {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let date = HomeRepository.date(from: today)!
        return HomeRepository(client: AppEnvironmentStub.client, calendar: calendar, today: { date })
    }

    @Test("D-day는 남은 날로 적고 당일은 D-DAY다")
    func dday() {
        let repo = repository(today: "2026-09-18")
        #expect(repo.dday(for: HomeRepository.date(from: "2026-09-25")!) == "D-7")
        #expect(repo.dday(for: HomeRepository.date(from: "2026-09-18")!) == "D-DAY")
        // 지난 일정도 홈에 남을 수 있다. 음수로 적는다.
        #expect(repo.dday(for: HomeRepository.date(from: "2026-09-15")!) == "D+3")
    }

    @Test("긴 제목은 24자에서 줄이고 말줄임을 붙인다")
    func shorten() {
        let long = "두통이랑 어지러움이 자주 있어요 특히 아침에 더 심해요"
        let short = HomeRepository.shorten(long)
        #expect(short.hasSuffix("…"))
        #expect(short.count <= HomeRepository.titleMax + 1)
        // 짧은 것은 그대로 둔다.
        #expect(HomeRepository.shorten("복부 통증 · 3주") == "복부 통증 · 3주")
    }

    @Test("시각은 오전·오후로 적는다")
    func time() {
        #expect(HomeRepository.time(from: "10:30") == "오전 10:30")
        #expect(HomeRepository.time(from: "14:05") == "오후 2:05")
    }

    @Test("서버가 title을 안 주면 환자가 말한 원문을 쓴다")
    func titleFallback() {
        let json = """
        {"recentCards":[{"cardId":1,"chiefComplaint":"배가 아파요","visited":false,"createdAt":"2026-09-04"}]}
        """
        let response = try! JSONDecoder().decode(HomeResponse.self, from: Data(json.utf8))
        let summary = repository(today: "2026-09-18").summary(from: response)
        #expect(summary.recentCards.first?.title == "배가 아파요")
        #expect(summary.recentCards.first?.meta == "2026.09.04")
    }

    @Test("진료 완료 여부로 배지가 갈린다")
    func badge() {
        // "진료 완료"는 visited로 판단한다. 병원명은 선택 입력이라 비어 있을 수 있어
        // 그것으로 판단하면 안 된다.
        #expect(HomeCard(id: "1", title: "a", meta: "", visited: false).badge?.text == "진료 전")
        #expect(HomeCard(id: "2", title: "b", meta: "", visited: true).badge?.text == "진료 완료")
    }

    @Test("아무것도 없으면 첫 홈 배너다 (3663:7007)")
    func emptyHomeBanner() {
        #expect(HomeSummary().isEmpty)
        #expect(HomeBannerKind.first.link == nil)
        #expect(HomeBannerKind.afterVisit.link?.counter == "1 / 5")
    }
}

/// 테스트가 저장소만 보려고 쓰는 빈 클라이언트.
@MainActor
private enum AppEnvironmentStub {
    static let client = AppEnvironment().client
}
