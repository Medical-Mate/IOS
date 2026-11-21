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

    @Test func 상한을_넘기면_들어가는_만큼만_받는다() {
        // 전에는 "412 / 300"처럼 넘긴 수를 적기만 하고 그대로 받았다.
        let long = String(repeating: "가", count: 412)
        #expect(MMTextArea.clamped(long, limit: 300).count == 300)
        // 상한 안쪽은 그대로 둔다.
        #expect(MMTextArea.clamped("위염이래요", limit: 300) == "위염이래요")
        #expect(MMTextArea.clamped(String(repeating: "가", count: 300), limit: 300).count == 300)
    }

    @Test func 말로_적다_넘치면_무엇이_빠졌는지_알린다() {
        #expect(VisitNoteView.overflowNotice == "300자까지만 담겨서 뒷말은 빠졌어요")
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

    @Test func 저장이_되면_재방문_날짜로_일정을_만든다() throws {
        // 이 화면의 재방문 줄에 날짜가 보이고 고칠 수 있어서 **저장이 곧 확인이다.**
        // 서버는 기록에서 일정을 만들지 않는다 — AI가 날짜를 잘못 뽑아도 조용히 생기면
        // 안 되기 때문이다.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let request = try #require(AppointmentFollowUpScheduler.request(
            clinic: "서울OO병원 내과", on: fixtureDay("2026-09-26"), cardId: 7, calendar: calendar
        ))
        #expect(request.scheduledOn == "2026-09-26")
        // **시각은 비워 둔다** — 기록에서 나온 날짜는 "2주 뒤"처럼 날짜까지다.
        #expect(request.scheduledTime == nil)
        #expect(request.origin == "VISIT_FOLLOW_UP")
        #expect(request.cardIds == [7])
    }

    @Test func 병원이_없으면_일정을_만들지_않는다() {
        // 서버가 일정에 병원을 요구한다.
        let calendar = Calendar(identifier: .gregorian)
        #expect(AppointmentFollowUpScheduler.request(
            clinic: nil, on: fixtureDay("2026-09-26"), cardId: 7, calendar: calendar
        ) == nil)
        #expect(AppointmentFollowUpScheduler.request(
            clinic: "", on: fixtureDay("2026-09-26"), cardId: 7, calendar: calendar
        ) == nil)
    }

    @Test func 다시_눌러_보라고_할지는_서버가_말한다() {
        // 잠시 받지 못한 것은 다시 누를 수 있고, 받지 않는 요청은 다시 눌러도 같다.
        #expect(VisitFlowModel.saveMessage(retryable: true) == VisitFlowModel.saveFailed)
        #expect(VisitFlowModel.saveMessage(retryable: false) == VisitFlowModel.saveRejected)
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
        #expect(HospitalPickPurpose.beforeVisit.submitTitle() == "브리핑 카드 만들기")
        #expect(HospitalPickPurpose.afterVisit.submitTitle() == "완료")
    }

    @Test func 일정_추가에서는_문구가_진료_전과_같고_CTA만_다르다() {
        // 칸을 채우고 돌아갈 뿐이라 만들 카드가 없다(Android `SCHEDULE`).
        #expect(HospitalPickPurpose.schedule.title == "진료받을 병원을 찾아주세요")
        #expect(HospitalPickPurpose.schedule.message == HospitalPickPurpose.beforeVisit.message)
        #expect(HospitalPickPurpose.schedule.submitTitle() == "완료")
    }

    @Test func 이미_있는_카드에서_병원만_바꾸면_완료다() {
        // "브리핑 카드 만들기"는 정말 카드를 만드는 길에서만 적는다(Android `#229`).
        #expect(HospitalPickPurpose.beforeVisit.submitTitle(forExistingCard: true) == "완료")
    }
}

/// 받아쓰기 패널의 글(2026-11-22). **두 화면이 다른 말을 쓴다** — 진료 후 메모는
/// "선생님이 뭐라고 하셨나요?", 증상 문답은 "말씀해 주세요"다. iOS가 `1p`에도
/// 문답 쪽 말을 넣고 있었다. 시안 `3663:14424`와 Android `visit_note_voice_title`이
/// 같은 값이다.
@Suite("받아쓰기 패널의 글")
struct VoicePanelCopyTests {
    @Test func 진료_후_메모는_들은_말을_묻는다() {
        #expect(VisitNoteCopy.voiceTitle == "선생님이 뭐라고 하셨나요?")
        #expect(VisitNoteCopy.voiceMessage == "듣고 있어요")
    }

    /// 마스터의 기본값은 또 다르다 — 컴포넌트 혼자 설 때의 말이다.
    @Test func 마스터의_기본값과도_다르다() {
        #expect(VisitNoteCopy.voiceTitle != "듣고 있어요")
    }
}
