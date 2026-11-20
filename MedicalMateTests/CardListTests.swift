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

    private func repository(today: String = "2026-09-18") -> CardRepository {
        CardRepository(
            client: Stub.client,
            calendar: calendar,
            today: { HomeRepository.date(from: today)! }
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
        let before = CardListItem(kind: .card(id: 1, visited: false), title: "", meta: "", summary: nil, month: "", writtenOn: .now)
        let done = CardListItem(kind: .card(id: 2, visited: true), title: "", meta: "", summary: nil, month: "", writtenOn: .now)
        let writing = CardListItem(kind: .openIntake(sessionId: 3, tempSaved: false, step: 1, total: 3), title: "", meta: "", summary: nil, month: "", writtenOn: .now)
        let saved = CardListItem(kind: .openIntake(sessionId: 4, tempSaved: true, step: 3, total: 3), title: "", meta: "", summary: nil, month: "", writtenOn: .now)

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
        #expect(CardRepository.countLabel(2, selected: false) == "2장")
        #expect(CardRepository.countLabel(1, selected: true) == "1장 선택됨")
    }

    @Test("이어서 할 것은 요약 줄이 warning이다 (3663:7130)")
    func summaryTone() {
        let intake = CardListItem(kind: .openIntake(sessionId: 1, tempSaved: false, step: 1, total: 3), title: "", meta: "", summary: nil, month: "", writtenOn: .now)
        let card = CardListItem(kind: .card(id: 1, visited: false), title: "", meta: "", summary: nil, month: "", writtenOn: .now)
        #expect(intake.summaryTone == .warning)
        #expect(card.summaryTone == .subtle)
    }
}

extension MMListRow.SummaryTone: @retroactive Equatable {}

@MainActor
private enum Stub {
    static let client = AppEnvironment().client
}
