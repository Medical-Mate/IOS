import Foundation
import Testing
@testable import MedicalMate

/// 1j-4 목록이 카드와 열린 문답을 한 줄씩 어떻게 세우는지 본다.
@MainActor
struct CardListTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    /// 배지·요약만 보는 줄. 나머지 값은 비운다.
    private func item(_ kind: CardListItem.Kind) -> CardListItem {
        CardListItem(kind: kind, title: "", meta: "", summary: nil, month: "", writtenOn: .now)
    }

    private func repository(today: String = "2026-09-18") -> CardRepository {
        CardRepository(
            client: Stub.client,
            calendar: calendar,
            today: { fixtureDay(today) }
        )
    }

    private func card(id: Int64, created: String, visited: Bool = false, clinic: String? = nil) -> CardSummaryResponse {
        CardSummaryResponse(
            cardId: id, title: "카드 \(id)", chiefComplaint: nil,
            visited: visited, clinicName: clinic, createdAt: created, axes: ["부위", "기간"]
        )
    }

    @Test("달로 묶고 최신이 위다 (3663:7125)")
    func sections() {
        let sections = repository().sections(
            cards: [card(id: 1, created: "2026-08-21"), card(id: 2, created: "2026-09-04")],
            openIntake: nil
        )
        #expect(sections.map(\.month) == ["2026년 9월", "2026년 8월"])
        #expect(sections.first?.items.count == 1)
    }

    @Test("열린 문답도 같은 목록에 선다")
    func openIntakeJoinsList() {
        let intake = OpenIntakeResponse(
            sessionId: 7, siteText: "무릎", questionsConfirmed: false,
            startedAt: "2026-09-18", progressCurrent: 2, progressTotal: 3
        )
        let sections = repository().sections(cards: [card(id: 1, created: "2026-09-04")], openIntake: intake)
        let items = sections.flatMap(\.items)
        #expect(items.count == 2)
        // 오늘 시작한 것이 맨 위다.
        #expect(items.first?.isCard == false)
        #expect(items.first?.meta == "오늘 · 3단계 중 2단계")
        #expect(items.first?.summary == "이어서 정리하기")
    }

    @Test("배지는 네 가지다 (FEATURE-SPEC 2.4)")
    func badges() {
        let before = item(.card(id: 1, visited: false))
        let done = item(.card(id: 2, visited: true))
        let writing = item(.openIntake(sessionId: 3, tempSaved: false, step: 1, total: 3))
        let saved = item(.openIntake(sessionId: 4, tempSaved: true, step: 3, total: 3))

        #expect(before.badge.text == "진료 전")
        #expect(done.badge.text == "진료 완료")
        #expect(writing.badge.text == "작성 중")
        #expect(saved.badge.text == "임시 저장")
    }

    @Test("병원이 비면 '병원 미정'으로 적는다 (3663:7132)")
    func clinicFallback() {
        let sections = repository().sections(cards: [card(id: 1, created: "2026-08-21")], openIntake: nil)
        #expect(sections.first?.items.first?.meta == "08.21 작성 · 병원 미정")
    }

    @Test("구간 머리의 수는 편집 중에 '선택됨'으로 바뀐다 (3663:7148)")
    func countLabel() {
        #expect(CardRepository.countLabel(2, unit: "장", selected: false) == "2장")
        #expect(CardRepository.countLabel(1, unit: "장", selected: true) == "1장 선택됨")
    }

    @Test("기록은 건으로 세고 카드는 장으로 센다")
    func 세는_말이_화면마다_갈린다() {
        // Android가 `record_count`와 `brief_card_list_count`로 나눠 둔 자리다.
        #expect(BriefCardListView.Kind.records.unit == "건")
        #expect(BriefCardListView.Kind.briefCards.unit == "장")
        #expect(CardRepository.countLabel(3, unit: "건", selected: false) == "3건")
        #expect(CardRepository.countLabel(3, unit: "건", selected: true) == "3건 선택됨")
    }

    @Test("삭제 확인은 무엇이 사라지는지를 화면마다 다르게 적는다")
    func 삭제_확인_문구가_갈린다() {
        #expect(BriefCardListView.Kind.briefCards.deleteTitle(2) == "브리핑 카드 2장을 삭제할까요?")
        #expect(BriefCardListView.Kind.records.deleteTitle(2) == "기록 2건을 삭제할까요?")
        // 카드를 지워도 진료 기록은 남는다 — 1j-4가 꼭 적어야 하는 말이다.
        #expect(BriefCardListView.Kind.briefCards.deleteBody == "연결된 진료 기록은 남고 선택한 카드는 사라져요.")
        #expect(BriefCardListView.Kind.records.deleteBody == "선택한 기록이 사라지고 되돌릴 수 없어요.")
    }

    @Test("고른 것이 없으면 아래 버튼은 수를 적지 않는다")
    func 삭제_버튼_라벨() {
        #expect(BriefCardListView.deleteTitle(0, unit: "장") == "삭제")
        #expect(BriefCardListView.deleteTitle(2, unit: "장") == "2장 삭제")
        #expect(BriefCardListView.deleteTitle(2, unit: "건") == "2건 삭제")
    }

    @Test("빈 자리 제목은 무엇이 없는지를 가리킨다")
    func 빈_자리_제목() {
        #expect(BriefCardListView.Kind.briefCards.emptyTitle == "아직 브리핑 카드가 없어요")
        #expect(BriefCardListView.Kind.records.emptyTitle == "아직 진료 기록이 없어요")
    }

    @Test("이어서 할 것은 요약 줄이 warning이다 (3663:7130)")
    func summaryTone() {
        let intake = item(.openIntake(sessionId: 1, tempSaved: false, step: 1, total: 3))
        let card = item(.card(id: 1, visited: false))
        #expect(intake.summaryTone == .warning)
        #expect(card.summaryTone == .subtle)
    }
}

extension MMListRow.SummaryTone: @retroactive Equatable {}

@MainActor
private enum Stub {
    static let client = AppEnvironment().client
}

/// 1j-1 기록 목록이 카드 · 문답 · 기록을 어떻게 한 줄씩 세우는지.
@MainActor
struct RecordListTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func repository() -> CardRepository {
        CardRepository(
            client: Stub.client,
            calendar: calendar,
            today: { fixtureDay("2026-09-21") }
        )
    }

    private func visit(id: Int64, cardId: Int64?, on: String, followUp: String? = nil) -> VisitSummaryResponse {
        VisitSummaryResponse(
            visitId: id, cardId: cardId, cardTitle: "복부 통증 · 3주",
            clinicName: "서울OO병원 내과", visitedOn: on,
            followUp: followUp.map { FollowUpResponse(date: $0, text: nil, approximate: true) }
        )
    }

    private func card(id: Int64, on: String) -> CardSummaryResponse {
        CardSummaryResponse(
            cardId: id, title: nil, chiefComplaint: "두통 · 잦은 어지러움", visited: nil,
            clinicName: nil, createdAt: on, axes: nil
        )
    }

    @Test func 기록_줄은_진료_완료_배지를_단다() {
        let item = repository().item(from: visit(id: 5, cardId: 7, on: "2026-09-12"))
        #expect(item?.badge.text == "진료 완료")
        #expect(item?.meta == "09.12 진료 · 서울OO병원 내과")
    }

    @Test func 재방문이_있으면_셋째_줄에_적는다() {
        let item = repository().item(from: visit(id: 5, cardId: 7, on: "2026-09-12", followUp: "2026-09-26"))
        #expect(item?.summary == "09.26 재방문")
    }

    @Test func 기록이_있는_카드는_기록_줄로만_선다() {
        // 같은 진료가 두 줄이 되면 안 된다.
        let sections = repository().sections(
            cards: [card(id: 7, on: "2026-09-04"), card(id: 2, on: "2026-09-21")],
            visits: [visit(id: 5, cardId: 7, on: "2026-09-12")],
            openIntake: nil
        )
        let ids = sections.flatMap(\.items).map(\.id)
        #expect(ids.contains("visit-5"))
        #expect(!ids.contains("card-7"))
        #expect(ids.contains("card-2"))
    }

    @Test func 달로_묶고_최신이_위다() {
        let sections = repository().sections(
            cards: [card(id: 2, on: "2026-09-21")],
            visits: [visit(id: 6, cardId: 8, on: "2026-07-18")],
            openIntake: nil
        )
        #expect(sections.map(\.month) == ["2026년 9월", "2026년 7월"])
    }
}
