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

    private func visit(clinic: String?, on day: String?) -> Visit {
        Visit(
            id: 5,
            cardId: 7,
            clinicName: clinic,
            visitedOn: day.flatMap { HomeRepository.date(from: $0) },
            items: [],
            followUp: nil,
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

    @Test func 머리의_메타는_병원과_진료일이다() {
        let meta = RecordDetailModel.headMeta(
            visit(clinic: "서울OO병원 내과", on: "2026-09-12"),
            visitCount: 1,
            calendar: calendar
        )
        #expect(meta == "서울OO병원 내과 · 09.12 진료")
    }

    @Test func 여러_번_진료면_첫_진료를_초진으로_적는다() {
        let meta = RecordDetailModel.headMeta(
            visit(clinic: "서울OO병원 내과", on: "2026-09-12"),
            visitCount: 2,
            calendar: calendar
        )
        #expect(meta == "서울OO병원 내과 · 09.12 초진")
    }

    @Test func 병원도_날짜도_없으면_메타가_비어_있다() {
        let meta = RecordDetailModel.headMeta(visit(clinic: nil, on: nil), visitCount: 1, calendar: calendar)
        #expect(meta.isEmpty)
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

    @Test func 한_번만_진료했으면_재방문을_붙이지_않는다() {
        let steps = RecordDetailModel.visitSteps(
            current: visit(clinic: "서울OO병원", on: "2026-09-12"),
            history: [],
            calendar: calendar
        )
        #expect(steps.count == 1)
        #expect(steps[0].when == "09.12 · 진료 후 기록")
        #expect(steps[0].kind == .visit(id: 5))
    }
}
