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

    @Test("값이 있는 축만 줄이 된다")
    func onlyFilledAxesMakeRows() {
        // 못 찾은 항목은 키가 없고, 값이 비었다는 것은 환자가 지웠다는 뜻이다.
        let items = VisitMapping.items(from: [
            "findings": axis("위염 초기 소견"),
            "tests": axis(""),
            "medication_instructions": axis(nil)
        ])
        #expect(items.map(\.label) == ["소견"])
    }

    @Test("축은 시안의 차례로 선다")
    func axesFollowDesignOrder() {
        let items = VisitMapping.items(from: [
            "follow_up": axis("2주 뒤"),
            "findings": axis("위염"),
            "medication_instructions": axis("2주분")
        ])
        #expect(items.map(\.label) == ["소견", "약", "재방문"])
    }

    @Test("모르는 축은 뒤에 붙고 id를 그대로 쓴다")
    func unknownAxisGoesLast() {
        // 항목 이름이 닫힌 목록이 아니라 AI가 늘릴 수 있다. 아는 것만 그리면 환자가
        // 적은 줄이 사라진다.
        let items = VisitMapping.items(from: [
            "referral": axis("상급병원 의뢰"),
            "findings": axis("위염")
        ])
        #expect(items.map(\.label) == ["소견", "referral"])
    }

    // MARK: - 재방문 줄

    @Test("재방문 줄에만 날짜를 붙이고 범위면 전후를 단다")
    func followUpRowGetsDate() {
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

    @Test("정확한 날짜면 전후를 붙이지 않는다")
    func exactDateHasNoAround() {
        let items = [VisitItem(axis: VisitAxis.followUp, label: "재방문", value: "9월 26일에 오세요")]
        let withDate = VisitMapping.withRevisitDate(
            items,
            followUp: followUp("2026-09-26", approximate: false),
            calendar: calendar
        )
        #expect(withDate[0].value == "9월 26일에 오세요 (9월 26일)")
    }

    @Test("이미 붙어 있으면 다시 붙이지 않는다")
    func dateIsNotAppendedTwice() {
        // 붙인 값을 그대로 저장한 기록이 있어서, 또 붙이면 날짜가 두 번 찍힌다.
        let follow = followUp("2026-09-26", approximate: true)
        let items = [VisitItem(axis: VisitAxis.followUp, label: "재방문", value: "2주 뒤 (9월 26일 전후)")]
        let withDate = VisitMapping.withRevisitDate(items, followUp: follow, calendar: calendar)
        #expect(withDate[0].value == "2주 뒤 (9월 26일 전후)")
    }

    @Test("저장할 때는 붙인 날짜를 뗀다")
    func savingStripsAppendedDate() {
        // 서버에는 환자가 말한 값만 가야 한다. 날짜는 followUp이 따로 나른다.
        let follow = followUp("2026-09-26", approximate: true)
        let bare = VisitMapping.withoutRevisitNote("2주 뒤 (9월 26일 전후)", followUp: follow, calendar: calendar)
        #expect(bare == "2주 뒤")
    }

    @Test("붙인 적이 없으면 그대로 둔다")
    func untouchedValueIsKept() {
        let follow = followUp("2026-09-26", approximate: true)
        #expect(VisitMapping.withoutRevisitNote("2주 뒤", followUp: follow, calendar: calendar) == "2주 뒤")
        #expect(VisitMapping.withoutRevisitNote("2주 뒤", followUp: nil, calendar: calendar) == "2주 뒤")
    }

    // MARK: - 저장 요청

    @Test("저장 요청은 축과 재방문을 나눠 보낸다")
    func requestSplitsAxesAndFollowUp() {
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

    @Test("기록 머리는 병원과 날짜를 가운뎃점으로 잇는다")
    func recordMetaJoinsClinicAndDay() {
        let meta = VisitMapping.recordMeta(
            clinicName: "서울OO병원 내과",
            visitedOn: HomeRepository.date(from: "2026-09-18"),
            calendar: calendar
        )
        #expect(meta == "서울OO병원 내과 · 2026.09.18")
    }

    @Test("병원이 없으면 날짜만 선다")
    func metaKeepsDayWithoutClinic() {
        let meta = VisitMapping.recordMeta(
            clinicName: nil,
            visitedOn: HomeRepository.date(from: "2026-09-18"),
            calendar: calendar
        )
        #expect(meta == "2026.09.18")
    }

    @Test("재방문 주석은 월일만 쓴다")
    func revisitNoteUsesMonthDay() {
        #expect(VisitMapping.revisitNote(followUp("2026-09-26", approximate: false), calendar: calendar) == "(9월 26일)")
        #expect(VisitMapping.revisitNote(nil, calendar: calendar) == nil)
    }

    // MARK: - 받아쓰기

    @Test("말한 글은 적던 글 뒤에 이어 붙인다")
    func dictationAppendsToDraft() {
        // 문답과 달리 보낼 곳이 없다.
        #expect(VisitNoteView.joined("위염이래요", "2주 약 먹으래요") == "위염이래요 2주 약 먹으래요")
        #expect(VisitNoteView.joined("", "2주 약") == "2주 약")
        #expect(VisitNoteView.joined("위염", "  ") == "위염")
    }

    @Test("메모 상한은 300이다")
    func memoLimitIs300() {
        #expect(VisitNoteMetrics.limit == 300)
    }
}

/// 병원 찾기가 두 가지 일을 한다.
struct HospitalPickPurposeTests {
    @Test("진료 전과 후의 문구가 갈린다")
    func copyDiffersBeforeAndAfter() {
        #expect(HospitalPickPurpose.beforeVisit.title == "진료받을 병원을 찾아주세요")
        #expect(HospitalPickPurpose.afterVisit.title == "진료받은 병원을 찾아주세요")
        #expect(HospitalPickPurpose.beforeVisit.submitTitle == "브리핑 카드 만들기")
        #expect(HospitalPickPurpose.afterVisit.submitTitle == "완료")
    }
}
