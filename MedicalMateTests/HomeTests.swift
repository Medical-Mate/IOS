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
        // 처음 온 사람에게는 링크도 장 수도 없다.
        #expect(HomeBannerCopy.link(.firstVisit) == nil)
        let today = HomeLead.todayVisit(clinic: nil, cardId: 1, cardTitle: "", clinicName: nil)
        #expect(HomeBannerCopy.link(today)?.counter == "1 / 5")
    }

    @Test("오늘 진료 배너는 병원 이름을 글에 넣는다 (3663:7014)")
    func todayBannerClinic() {
        let lead = HomeLead.todayVisit(clinic: "서울OO병원 내과", cardId: 7, cardTitle: "복부 통증", clinicName: "서울OO병원")
        #expect(HomeBannerCopy.message(lead) == "서울OO병원 내과에서 들은 말을\n잊기 전에 남겨두세요.")
        // 병원을 모르면 "진료실에서"로 받친다. 표본에 있던 이름을 그대로 적지 않는다.
        let unknown = HomeLead.todayVisit(clinic: nil, cardId: 7, cardTitle: "복부 통증", clinicName: nil)
        #expect(HomeBannerCopy.message(unknown) == "진료실에서 들은 말을\n잊기 전에 남겨두세요.")
    }

    @Test("내일 진료 배너는 시각과 병원을 잇는다 (3663:7029)")
    func tomorrowBanner() {
        #expect(HomeBannerCopy.tomorrowMessage(time: "오전 10:30", clinic: "서울OO병원 내과")
            == "내일 오전 10:30 서울OO병원 내과예요.\n달라진 점이 있으면 오늘 고쳐두세요.")
        // 시간 미정이면 시각을 빼고 적는다.
        #expect(HomeBannerCopy.tomorrowMessage(time: nil, clinic: "서울OO병원 내과")
            == "내일 서울OO병원 내과예요.\n달라진 점이 있으면 오늘 고쳐두세요.")
        #expect(HomeBannerCopy.tomorrowMessage(time: nil, clinic: nil)
            == "내일 진료예요.\n달라진 점이 있으면 오늘 고쳐두세요.")
    }

    @Test("오늘 진료를 이미 기록했으면 오늘 배너를 띄우지 않는다")
    func todayAlreadyRecorded() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let today = HomeRepository.date(from: "2026-09-12")!
        var input = HomeLeadInput()
        input.nextOn = today
        input.nextCard = (id: 7, title: "복부 통증")
        #expect(HomeRepository.timedLead(input, today: today, calendar: calendar) != nil)

        input.lastVisitedOn = today
        #expect(HomeRepository.timedLead(input, today: today, calendar: calendar) == nil)
    }

    @Test("내일 진료면 내일 배너다")
    func tomorrowLead() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        var input = HomeLeadInput()
        input.nextOn = HomeRepository.date(from: "2026-09-13")
        input.nextCard = (id: 7, title: "복부 통증")
        let lead = HomeRepository.timedLead(input, today: HomeRepository.date(from: "2026-09-12")!, calendar: calendar)
        #expect(lead == .tomorrowVisit(time: nil, clinic: nil, cardId: 7))
    }

    @Test("카드가 걸리지 않은 일정은 배너를 가르지 않는다")
    func noCardNoLead() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        var input = HomeLeadInput()
        input.nextOn = HomeRepository.date(from: "2026-09-12")
        // 기록도 "카드 다시 보기"도 카드가 있어야 갈 곳이 있다.
        let today = HomeRepository.date(from: "2026-09-12")!
        #expect(HomeRepository.timedLead(input, today: today, calendar: calendar) == nil)
    }
}

/// 테스트가 저장소만 보려고 쓰는 빈 클라이언트.
@MainActor
private enum AppEnvironmentStub {
    static let client = AppEnvironment().client
}
