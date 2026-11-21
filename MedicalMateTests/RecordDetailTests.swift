import Foundation
import Testing
@testable import MedicalMate

/// H 섹션 — 기록 상세(`1j-3`)가 한 증상의 일대기를 어떻게 펴는지.
struct RecordDetailTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func visit(id: Int64 = 5, clinic: String?, on day: String?, followUp: VisitFollowUp? = nil) -> Visit {
        Visit(
            id: id,
            cardId: 7,
            clinicName: clinic,
            visitedOn: day.flatMap { HomeRepository.date(from: $0) },
            items: [],
            followUp: followUp,
            patientNotes: [],
            rawNote: nil
        )
    }

    @Test func 어떤_날짜_표기가_와도_월일_두_자리로_줄인다() {
        #expect(RecordDetailModel.shortDay("2026.09.04") == "09.04")
        #expect(RecordDetailModel.shortDay("9월 4일") == "09.04")
        #expect(RecordDetailModel.shortDay("09.12") == "09.12")
    }

    @Test func 숫자가_모자라면_원문을_그대로_둔다() {
        // 못 읽은 날짜를 지어내지 않는다.
        #expect(RecordDetailModel.shortDay("미정") == "미정")
    }

    @Test func 머리글_둘째_줄은_병원과_진료일이다() {
        let line = RecordDetailModel.clinicLine(
            [visit(clinic: "서울OO병원 내과", on: "2026-09-12")],
            calendar: calendar
        )
        #expect(line == "서울OO병원 내과 · 09.12 진료")
    }

    @Test func 여러_번이면_오래된_차례로_초진과_재방문을_적는다() {
        // 타임라인은 최신이 위인데 이 줄만 반대다 — 흘러온 순서를 한 줄로 읽는 자리다.
        let line = RecordDetailModel.clinicLine(
            [
                visit(id: 6, clinic: "서울OO병원 내과", on: "2026-09-26"),
                visit(id: 5, clinic: "서울OO병원 내과", on: "2026-09-12")
            ],
            calendar: calendar
        )
        #expect(line == "서울OO병원 내과 · 09.12 초진 · 09.26 재방문")
    }

    @Test func 병원도_날짜도_없으면_둘째_줄이_비어_있다() {
        #expect(RecordDetailModel.clinicLine([visit(clinic: nil, on: nil)], calendar: calendar).isEmpty)
    }

    @Test func 배지는_진료_횟수를_말한다() {
        #expect(RecordDetailModel.headBadge(visitCount: 1).text == "진료 완료")
        #expect(RecordDetailModel.headBadge(visitCount: 3).text == "진료 3회")
        #expect(RecordDetailModel.headBadge(visitCount: 1).tone == .success)
    }

    @Test func 접었을_때는_세_줄만_보인다() {
        // 1j-3 시안이 부위 · 기간 · 양상 셋을 남긴다.
        #expect(RecordDetailModel.collapsedItemCount == 3)
    }

    @Test func 한_번만_진료했으면_몇_번째인지_붙이지_않는다() {
        let steps = RecordDetailModel.visitSteps(
            [visit(clinic: "서울OO병원", on: "2026-09-12")],
            calendar: calendar
        )
        #expect(steps.count == 1)
        #expect(steps[0].when == "09.12 · 진료 후 기록")
        #expect(steps[0].kind == .visit(id: 5))
    }

    @Test func 여러_번이면_가장_오래된_것이_초진이다() {
        // 최신이 0이라 끝이 초진이다.
        let steps = RecordDetailModel.visitSteps(
            [
                visit(id: 6, clinic: "서울OO병원", on: "2026-09-26"),
                visit(id: 5, clinic: "서울OO병원", on: "2026-09-12")
            ],
            calendar: calendar
        )
        #expect(steps.map(\.when) == ["09.26 · 진료 후 기록 · 재방문", "09.12 · 진료 후 기록 · 초진"])
    }

    @Test func 카드_칸은_작성일만_적는다() {
        // 진료실에서 보여 준 날은 바로 위 기록 칸이 이미 적는다.
        #expect(RecordDetailModel.visitKind(count: 1, index: 0) == nil)
        #expect(RecordDetailModel.visitKind(count: 2, index: 1) == "초진")
        #expect(RecordDetailModel.visitKind(count: 2, index: 0) == "재방문")
    }

    @Test func 잡아_둔_일정이_없으면_기록의_재방문_날짜를_세운다() throws {
        // 캘린더가 점을 찍는 값과 같아야 달력과 상세가 다른 날을 가리키지 않는다.
        let followUp = VisitFollowUp(
            date: try #require(HomeRepository.date(from: "2026-09-26")),
            text: nil,
            approximate: true
        )
        let step = RecordDetailModel.pending(followUp, calendar: calendar)
        #expect(step.when == "09.26 예정")
        #expect(step.notice?.title == "재방문 예정이에요")
        #expect(step.notice?.message == "9월 26일 (토) 전후")
    }

    @Test func 카드_제목이_비면_목록의_제목으로_받친다() {
        let summary = VisitSummaryResponse(
            visitId: 5,
            cardId: 7,
            cardTitle: "복부 통증 · 3주",
            clinicName: "서울OO병원",
            visitedOn: "2026-09-12",
            followUp: nil
        )
        let title = RecordDetailModel.title(
            card: nil,
            summaries: [summary],
            newest: visit(clinic: "서울OO병원", on: "2026-09-12")
        )
        #expect(title == "복부 통증 · 3주")
    }

    @Test func 제목이_하나도_없으면_병원으로_받친다() {
        let title = RecordDetailModel.title(
            card: nil,
            summaries: [],
            newest: visit(clinic: "서울OO병원", on: "2026-09-12")
        )
        #expect(title == "서울OO병원")
    }
}
