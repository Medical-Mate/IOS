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
        let date = fixtureDay(today)
        return HomeRepository(client: AppEnvironmentStub.client, calendar: calendar, today: { date })
    }

    @Test("D-day는 남은 날로 적고 지난 것은 배지를 달지 않는다")
    func dday() {
        let repo = repository(today: "2026-09-18")
        #expect(repo.dday(for: fixtureDay("2026-09-25")) == "D-7")
        // **대문자 D-DAY가 아니다.** 시안의 `Card / Schedule` 설명이 "D-day"라고 적고
        // Android의 `ddayLabel`도 같다.
        #expect(repo.dday(for: fixtureDay("2026-09-18")) == "D-day")
        // **지난 것은 배지가 없다.** "D+3"은 남은 날을 세는 말이 아니라서
        // 앞으로 할 일을 가리키는 자리에 서면 안 된다. Android도 days >= 0에서만 부른다.
        #expect(repo.dday(for: fixtureDay("2026-09-15")) == nil)
    }

    @Test("병원이 없으면 '카드만 작성됨'으로 적는다 (3663:7014)")
    func 카드_줄의_병원_자리() {
        #expect(HomeRepository.cardMeta(day: "2026.09.04", clinic: "서울OO병원 내과") == "2026.09.04 · 서울OO병원 내과")
        // 빈 자리를 남기지 않는다. 날짜만 선 줄은 무엇이 빠졌는지 알 수 없다.
        #expect(HomeRepository.cardMeta(day: "2026.08.21", clinic: nil) == "2026.08.21 · 카드만 작성됨")
        #expect(HomeRepository.cardMeta(day: "2026.08.21", clinic: "") == "2026.08.21 · 카드만 작성됨")
    }

    @Test("다가오는 일정 제목은 origin으로 초진·재진을 가른다")
    func 일정_제목이_진료_차수를_적는다() {
        // 서버의 `purpose`는 비어 올 때가 많아 제목이 "내과"로 끝나거나 통째로 비었다.
        // Android는 `origin == "VISIT_FOLLOW_UP"`으로 가른다.
        #expect(HomeRepository.scheduleTitle(department: "내과", origin: .visitFollowUp) == "내과 재진")
        #expect(HomeRepository.scheduleTitle(department: "내과", origin: .manual) == "내과 초진")
        // **진료과가 없어도 비지 않는다.**
        #expect(HomeRepository.scheduleTitle(department: nil, origin: .visitFollowUp) == "재진")
        #expect(HomeRepository.scheduleTitle(department: "", origin: .manual) == "초진")
    }

    @Test("모레 진료는 내일 배너가 아니다")
    func 모레는_내일_배너가_아니다() {
        let input = HomeLeadInput(
            lastVisitedOn: nil,
            nextOn: fixtureDay("2026-09-20"),
            nextTime: nil,
            nextClinicLabel: "서울OO병원 내과",
            nextClinicName: "서울OO병원",
            nextCard: (id: 7, title: "복부 통증 · 3주")
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        #expect(HomeRepository.timedLead(input, today: fixtureDay("2026-09-18"), calendar: calendar) == nil)
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
    func titleFallback() throws {
        let json = """
        {"recentCards":[{"cardId":1,"chiefComplaint":"배가 아파요","visited":false,"createdAt":"2026-09-04"}]}
        """
        let response = try JSONDecoder().decode(HomeResponse.self, from: Data(json.utf8))
        let summary = repository(today: "2026-09-18").summary(from: response)
        #expect(summary.recentCards.first?.title == "배가 아파요")
        // 병원이 없는 표본이라 둘째 줄이 "카드만 작성됨"으로 닫힌다(3663:7014).
        #expect(summary.recentCards.first?.meta == "2026.09.04 · 카드만 작성됨")
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
        let today = HomeBannerPage.today(clinic: nil, cardId: 1, cardTitle: "", clinicName: nil)
        #expect(HomeBannerCopy.link(today, index: 0, total: 5)?.counter == "1 / 5")
    }

    @Test("오늘 진료 배너는 병원 이름을 글에 넣는다 (3663:7014)")
    func todayBannerClinic() {
        let page = HomeBannerPage.today(
            clinic: "서울OO병원 내과", cardId: 7, cardTitle: "복부 통증", clinicName: "서울OO병원"
        )
        #expect(HomeBannerCopy.message(page) == "서울OO병원 내과에서 들은 말을\n잊기 전에 남겨두세요.")
        // 병원을 모르면 "진료실에서"로 받친다. 표본에 있던 이름을 그대로 적지 않는다.
        let unknown = HomeBannerPage.today(clinic: nil, cardId: 7, cardTitle: "복부 통증", clinicName: nil)
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
    func todayAlreadyRecorded() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let today = try #require(HomeRepository.date(from: "2026-09-12"))
        var input = HomeLeadInput()
        input.nextOn = today
        input.nextCard = (id: 7, title: "복부 통증")
        #expect(HomeRepository.timedLead(input, today: today, calendar: calendar) != nil)

        input.lastVisitedOn = today
        #expect(HomeRepository.timedLead(input, today: today, calendar: calendar) == nil)
    }

    @Test("내일 진료면 내일 배너다")
    func tomorrowLead() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        var input = HomeLeadInput()
        input.nextOn = HomeRepository.date(from: "2026-09-13")
        input.nextCard = (id: 7, title: "복부 통증")
        let today = try #require(HomeRepository.date(from: "2026-09-12"))
        let lead = HomeRepository.timedLead(input, today: today, calendar: calendar)
        #expect(lead == .tomorrowVisit(time: nil, clinic: nil, cardId: 7))
    }

    @Test("카드가 걸리지 않은 일정은 배너를 가르지 않는다")
    func noCardNoLead() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        var input = HomeLeadInput()
        input.nextOn = HomeRepository.date(from: "2026-09-12")
        // 기록도 "카드 다시 보기"도 카드가 있어야 갈 곳이 있다.
        let today = try #require(HomeRepository.date(from: "2026-09-12"))
        #expect(HomeRepository.timedLead(input, today: today, calendar: calendar) == nil)
    }

    @Test("처음 온 사람은 배너가 한 장이다 (3663:7007)")
    func welcomeIsSingle() {
        // 넘길 것도 장 수도 없다.
        let pages = HomeBannerPage.pages(lead: .firstVisit, latestCardId: nil, restIndex: 0)
        #expect(pages == [.welcome])
        #expect(HomeBannerCopy.link(.welcome, index: 0, total: 1) == nil)
    }

    @Test("그 밖에는 다섯 장이고 첫 장만 상황에 따라 바뀐다 (3663:7014)")
    func fivePages() {
        let lead = HomeLead.tomorrowVisit(time: "오전 10:30", clinic: "서울OO병원 내과", cardId: 7)
        let pages = HomeBannerPage.pages(lead: lead, latestCardId: 7, restIndex: 0)
        #expect(pages.count == 5)
        #expect(pages[0] == .tomorrow(time: "오전 10:30", clinic: "서울OO병원 내과", cardId: 7))
        // 2~5장은 차례가 고정이다.
        #expect(pages[1...].map(\.id) == ["message", "schedule", "saveCard", "mate"])
    }

    @Test("가를 값이 없으면 2~5장 가운데 하나를 첫 장에 올린다")
    func otherPicksFromRest() {
        let pages = HomeBannerPage.pages(lead: .other, latestCardId: nil, restIndex: 2)
        #expect(pages[0] == .saveCard(cardId: nil))
        #expect(pages.count == 5)
    }

    @Test("장 수는 1부터 센다")
    func counter() {
        #expect(HomeBannerCopy.counter(index: 0, total: 5) == "1 / 5")
        #expect(HomeBannerCopy.counter(index: 4, total: 5) == "5 / 5")
    }

    @Test("배너마다 사진이 다르고 첫 장의 네 갈래는 한 장을 같이 쓴다")
    func photos() {
        #expect(HomeBannerPage.welcome.photo == "home-banner-first")
        #expect(HomeBannerPage.tomorrow(time: nil, clinic: nil, cardId: 1).photo == "home-banner-today")
        #expect(HomeBannerPage.cardReady(cardId: 1, symptom: "두통").photo == "home-banner-today")
        #expect(HomeBannerPage.mate.photo == "home-banner-mate")
    }
}

/// 테스트가 저장소만 보려고 쓰는 빈 클라이언트.
@MainActor
private enum AppEnvironmentStub {
    static let client = AppEnvironment().client
}

/// 배너가 이음매 없이 도는 자리(2026-11-22). 자리를 모듈로로 접으면 마지막 장에서
/// 0으로 되돌아가 **앞의 네 장을 거꾸로 되감는다.** 자리는 늘 앞으로만 가고 그릴 때만
/// 접는다 — Android `HomeBannerPager`의 `LOOP_PAGES`와 같은 방법이다.
@Suite("홈 배너가 도는 법")
struct HomeBannerLoopTests {
    @Test func 시작_자리는_첫_장이다() {
        for count in 1...8 {
            #expect(BannerCarouselMetrics.start(for: count) % count == 0)
        }
    }

    @Test func 시작_자리는_가운데_언저리다() {
        let start = BannerCarouselMetrics.start(for: 5)
        #expect(start > 0)
        #expect(start < BannerCarouselMetrics.loopPages)
        // 앞뒤로 넉넉히 남는다.
        #expect(BannerCarouselMetrics.loopPages - start > 1000)
    }

    @Test func 장이_없으면_0이다() {
        #expect(BannerCarouselMetrics.start(for: 0) == 0)
    }
}

/// 문답 줄의 배지(2026-11-22). **"작성 중"과 "임시 저장"은 진행도로 갈리지 않는다** —
/// 3/3은 AI 문답이 끝난 것이고, 거기서 질문을 고르다 나간 사람도 3/3이다.
/// 서버의 `questions_confirmed`가 가른다(`HomeDTO`가 못박아 둔 자리다).
@Suite("문답 줄의 배지")
struct OpenIntakeBadgeTests {
    private func row(_ confirmed: Bool, step: Int, total: Int) -> CardListItem {
        CardListItem(
            kind: .openIntake(sessionId: 9, tempSaved: confirmed, step: step, total: total),
            title: "정리 중인 증상", meta: "", summary: nil,
            clinic: nil,
            month: "2026년 11월", writtenOn: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func 확정_전이면_끝까지_왔어도_작성_중이다() {
        #expect(row(false, step: 3, total: 3).badge.text == "작성 중")
    }

    @Test func 확정했으면_임시_저장이다() {
        #expect(row(true, step: 3, total: 3).badge.text == "임시 저장")
    }

    @Test func 진행_중이면_작성_중이다() {
        #expect(row(false, step: 2, total: 3).badge.text == "작성 중")
    }
}
