import Foundation
import Testing
@testable import MedicalMate

/// F 섹션 — 진료 후 기록이 응답을 어떻게 읽고 무엇을 보내는지.
struct VisitTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func axis(_ value: String?) -> VisitAxisResponse {
        VisitAxisResponse(status: "FILLED", value: value)
    }

    private func followUp(_ day: String, approximate: Bool) -> VisitFollowUp {
        VisitFollowUp(date: fixtureDay(day), text: nil, approximate: approximate)
    }

    // MARK: - 축

    @Test func 값이_있는_축만_줄이_된다() {
        // 못 찾은 항목은 키가 없고, 값이 비었다는 것은 환자가 지웠다는 뜻이다.
        let items = VisitMapping.items(from: [
            "findings": axis("위염 초기 소견"),
            "tests": axis(""),
            "medication_instructions": axis(nil)
        ])
        #expect(items.map(\.label) == ["소견"])
    }

    @Test func 축은_시안의_차례로_선다() {
        let items = VisitMapping.items(from: [
            "follow_up": axis("2주 뒤"),
            "findings": axis("위염"),
            "medication_instructions": axis("2주분")
        ])
        #expect(items.map(\.label) == ["소견", "약", "재방문"])
    }

    @Test func 모르는_축은_뒤에_붙고_id를_그대로_쓴다() {
        // 항목 이름이 닫힌 목록이 아니라 AI가 늘릴 수 있다. 아는 것만 그리면 환자가
        // 적은 줄이 사라진다.
        let items = VisitMapping.items(from: [
            "referral": axis("상급병원 의뢰"),
            "findings": axis("위염")
        ])
        #expect(items.map(\.label) == ["소견", "referral"])
    }

    // MARK: - 재방문 줄

    @Test func 재방문_줄에만_날짜를_붙이고_범위면_전후를_단다() {
        let items = [
            VisitItem(axis: VisitAxis.findings, label: "소견", value: "위염"),
            VisitItem(axis: VisitAxis.followUp, label: "재방문", value: "2주 뒤 재방문")
        ]
        let withDate = VisitMapping.withRevisitDate(
            items,
            followUp: followUp("2026-09-26", approximate: true),
            calendar: calendar
        )
        #expect(withDate[0].value == "위염")
        #expect(withDate[1].value == "2주 뒤 재방문 (9월 26일 전후)")
    }

    @Test func 정확한_날짜면_전후를_붙이지_않는다() {
        let items = [VisitItem(axis: VisitAxis.followUp, label: "재방문", value: "9월 26일에 오세요")]
        let withDate = VisitMapping.withRevisitDate(
            items,
            followUp: followUp("2026-09-26", approximate: false),
            calendar: calendar
        )
        #expect(withDate[0].value == "9월 26일에 오세요 (9월 26일)")
    }

    @Test func 이미_붙어_있으면_다시_붙이지_않는다() {
        // 붙인 값을 그대로 저장한 기록이 있어서, 또 붙이면 날짜가 두 번 찍힌다.
        let follow = followUp("2026-09-26", approximate: true)
        let items = [VisitItem(axis: VisitAxis.followUp, label: "재방문", value: "2주 뒤 (9월 26일 전후)")]
        let withDate = VisitMapping.withRevisitDate(items, followUp: follow, calendar: calendar)
        #expect(withDate[0].value == "2주 뒤 (9월 26일 전후)")
    }

    @Test func 저장할_때는_붙인_날짜를_뗀다() {
        // 서버에는 환자가 말한 값만 가야 한다. 날짜는 followUp이 따로 나른다.
        let follow = followUp("2026-09-26", approximate: true)
        let bare = VisitMapping.withoutRevisitNote("2주 뒤 (9월 26일 전후)", followUp: follow, calendar: calendar)
        #expect(bare == "2주 뒤")
    }

    @Test func 붙인_적이_없으면_그대로_둔다() {
        let follow = followUp("2026-09-26", approximate: true)
        #expect(VisitMapping.withoutRevisitNote("2주 뒤", followUp: follow, calendar: calendar) == "2주 뒤")
        #expect(VisitMapping.withoutRevisitNote("2주 뒤", followUp: nil, calendar: calendar) == "2주 뒤")
    }

    // MARK: - 저장 요청

    @Test func 저장_요청은_축과_재방문을_나눠_보낸다() {
        let follow = followUp("2026-09-26", approximate: true)
        let request = VisitMapping.createRequest(
            VisitMapping.Draft(
                clinicName: "서울OO병원 내과",
                visitedOn: HomeRepository.date(from: "2026-09-18"),
                items: [VisitItem(axis: VisitAxis.followUp, label: "재방문", value: "2주 뒤 (9월 26일 전후)")],
                followUp: follow,
                patientNotes: ["커피 줄이기"],
                rawNote: "원문"
            ),
            calendar: calendar
        )
        #expect(request.visitedOn == "2026-09-18")
        #expect(request.axes.first?.value == "2주 뒤")
        #expect(request.followUp?.date == "2026-09-26")
        #expect(request.followUp?.approximate == true)
        #expect(request.rawNote == "원문")
    }

    // MARK: - 글 꾸미기

    @Test func 기록_머리는_병원과_날짜를_가운뎃점으로_잇는다() {
        let meta = VisitMapping.recordMeta(
            clinicName: "서울OO병원 내과",
            visitedOn: HomeRepository.date(from: "2026-09-18"),
            calendar: calendar
        )
        #expect(meta == "서울OO병원 내과 · 2026.09.18")
    }

    @Test func 병원이_없으면_날짜만_선다() {
        let meta = VisitMapping.recordMeta(
            clinicName: nil,
            visitedOn: HomeRepository.date(from: "2026-09-18"),
            calendar: calendar
        )
        #expect(meta == "2026.09.18")
    }

    @Test func 재방문_주석은_월일만_쓴다() {
        #expect(VisitMapping.revisitNote(followUp("2026-09-26", approximate: false), calendar: calendar) == "(9월 26일)")
        #expect(VisitMapping.revisitNote(nil, calendar: calendar) == nil)
    }

    // MARK: - 받아쓰기

    @Test func 말한_글은_적던_글_뒤에_이어_붙인다() {
        // 문답과 달리 보낼 곳이 없다.
        #expect(VisitNoteView.joined("위염이래요", "2주 약 먹으래요") == "위염이래요 2주 약 먹으래요")
        #expect(VisitNoteView.joined("", "2주 약") == "2주 약")
        #expect(VisitNoteView.joined("위염", "  ") == "위염")
    }

    @Test func 메모_상한은_300이다() {
        #expect(VisitNoteMetrics.limit == 300)
    }
}

/// 병원 찾기가 두 가지 일을 한다.
struct HospitalPickPurposeTests {
    @Test func 툴팁은_네_가지를_이름으로_적는다() {
        // 시안(3663:14452)이 축 이름을 그대로 적는다. 지어내지 않는다.
        #expect(VisitRecordView.tooltipText == "소견·검사·약·재방문으로 나눴어요.\n원문 메모도 함께 남아요")
        // **두 줄이다.** 말풍선이 한 줄로 눌리면 뒷말이 잘린다.
        #expect(VisitRecordView.tooltipText.contains("\n"))
    }

    @Test func 저장_실패_문구가_갈린다() {
        // Android의 RETRYABLE · REJECTED와 같은 갈림이다.
        #expect(VisitFlowModel.saveFailed == "저장하지 못했어요. 다시 눌러주세요.")
        #expect(VisitFlowModel.saveRejected.hasPrefix("다시 눌러도 저장되지 않아요."))
        #expect(VisitFlowModel.saveRejected.contains("브리핑 카드를 먼저 저장해야"))
    }

    @Test func 진료_전과_후의_문구가_갈린다() {
        #expect(HospitalPickPurpose.beforeVisit.title == "진료받을 병원을 찾아주세요")
        #expect(HospitalPickPurpose.afterVisit.title == "진료받은 병원을 찾아주세요")
        #expect(HospitalPickPurpose.beforeVisit.submitTitle == "브리핑 카드 만들기")
        #expect(HospitalPickPurpose.afterVisit.submitTitle == "완료")
    }
}
