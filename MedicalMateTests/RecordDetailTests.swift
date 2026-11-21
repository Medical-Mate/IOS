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

    @Test("어떤 날짜 표기가 와도 월일 두 자리로 줄인다")
    func shortensAnyDateForm() {
        #expect(RecordDetailModel.shortDay("2026.09.04") == "09.04")
        #expect(RecordDetailModel.shortDay("9월 4일") == "09.04")
        #expect(RecordDetailModel.shortDay("09.12") == "09.12")
    }

    @Test("숫자가 모자라면 원문을 그대로 둔다")
    func keepsTextWhenNoDigits() {
        // 못 읽은 날짜를 지어내지 않는다.
        #expect(RecordDetailModel.shortDay("미정") == "미정")
    }

    @Test("머리글 둘째 줄은 병원과 진료일이다")
    func clinicLineHasClinicAndDay() {
        let line = RecordDetailModel.clinicLine(
            [visit(clinic: "서울OO병원 내과", on: "2026-09-12")],
            calendar: calendar
        )
        #expect(line == "서울OO병원 내과 · 09.12 진료")
    }

    @Test("여러 번이면 오래된 차례로 초진과 재방문을 적는다")
    func clinicLineListsVisitsOldestFirst() {
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

    @Test("병원도 날짜도 없으면 둘째 줄이 비어 있다")
    func clinicLineIsEmptyWithoutData() {
        #expect(RecordDetailModel.clinicLine([visit(clinic: nil, on: nil)], calendar: calendar).isEmpty)
    }

    @Test("배지는 진료 횟수를 말한다")
    func badgeCountsVisits() {
        #expect(RecordDetailModel.headBadge(visitCount: 1).text == "진료 완료")
        #expect(RecordDetailModel.headBadge(visitCount: 3).text == "진료 3회")
        #expect(RecordDetailModel.headBadge(visitCount: 1).tone == .success)
    }

    @Test("접었을 때는 세 줄만 보인다")
    func collapsedCardShowsThreeRows() {
        // 1j-3 시안이 부위 · 기간 · 양상 셋을 남긴다.
        #expect(RecordDetailModel.collapsedItemCount == 3)
    }

    @Test("한 번만 진료했으면 몇 번째인지 붙이지 않는다")
    func singleVisitHasNoOrdinal() {
        let steps = RecordDetailModel.visitSteps(
            [visit(clinic: "서울OO병원", on: "2026-09-12")],
            calendar: calendar
        )
        #expect(steps.count == 1)
        #expect(steps[0].when == "09.12 · 진료 후 기록")
        #expect(steps[0].kind == .visit(id: 5))
    }

    @Test("여러 번이면 가장 오래된 것이 초진이다")
    func oldestVisitIsFirstVisit() {
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

    @Test("카드 칸은 작성일만 적는다")
    func visitKindByPosition() {
        // 진료실에서 보여 준 날은 바로 위 기록 칸이 이미 적는다.
        #expect(RecordDetailModel.visitKind(count: 1, index: 0) == nil)
        #expect(RecordDetailModel.visitKind(count: 2, index: 1) == "초진")
        #expect(RecordDetailModel.visitKind(count: 2, index: 0) == "재방문")
    }

    @Test("잡아 둔 일정이 없으면 기록의 재방문 날짜를 세운다")
    func followUpBecomesPendingStep() throws {
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

    @Test("카드 제목이 비면 목록의 제목으로 받친다")
    func fallsBackToListedTitle() {
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

    @Test("제목이 하나도 없으면 병원으로 받친다")
    func fallsBackToClinicName() {
        let title = RecordDetailModel.title(
            card: nil,
            summaries: [],
            newest: visit(clinic: "서울OO병원", on: "2026-09-12")
        )
        #expect(title == "서울OO병원")
    }
}
