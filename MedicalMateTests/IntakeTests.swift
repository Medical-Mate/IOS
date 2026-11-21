import Foundation
import Testing
@testable import MedicalMate

/// D 섹션 — 증상 정리 2 · 3단계의 규칙.
struct IntakeTests {
    // MARK: - 강도

    @Test("강도요청은 화면에 보이는 낱말을 함께 보낸다")
    func severityRequestCarriesLabel() {
        let request = IntakeRepository.severityRequest(level: 3)
        #expect(request.level == 3)
        // 낱말은 디자인 카피라 앱이 들고 보낸다. 서버가 들고 있으면 문구를 바꿀 때마다
        // 배포해야 한다.
        #expect(request.label == "꽤 아파요")
    }

    @Test("강도는 1에서 5로 잘린다")
    func severityIsClampedToFive() {
        #expect(IntakeRepository.severityRequest(level: 0).label == MMSeverityLevel.of(1).title)
        #expect(IntakeRepository.severityRequest(level: 9).label == MMSeverityLevel.of(5).title)
    }

    // MARK: - 대화

    @Test("대화는 seq 순으로 서고 역할이 갈린다")
    func messagesOrderBySeq() {
        let messages = IntakeRepository.messages(from: [
            MessageResponse(seq: 2, role: "USER", text: "한 3주쯤 됐어요."),
            MessageResponse(seq: 1, role: "AI", text: "언제부터 그러셨어요?")
        ])
        #expect(messages.map(\.text) == ["언제부터 그러셨어요?", "한 3주쯤 됐어요."])
        #expect(messages.map(\.fromPatient) == [false, true])
    }

    // MARK: - 추천 질문

    @Test("후보는 rank 순이다")
    func candidatesFollowRank() {
        // 서버가 정렬해 주지만 순서를 믿지 않는다.
        let candidates = IntakeRepository.candidates(from: [
            QuestionCandidateResponse(text: "셋", rank: 3),
            QuestionCandidateResponse(text: "하나", rank: 1),
            QuestionCandidateResponse(text: "둘", rank: 2)
        ])
        #expect(candidates == ["하나", "둘", "셋"])
    }

    @Test("환자가 손댄 줄은 서버 후보로 덮지 않는다")
    func touchedRowsSurviveRefresh() {
        // 덮으면 지운 질문이 되살아나고 직접 적은 줄이 사라진다.
        let existing = [IntakeQuestionRow(text: "공복으로 가야 하나요?", isSelected: true, isOwn: true)]
        let rows = IntakeRepository.rows(candidates: ["검사를 받아야 하나요?"], existing: existing)
        #expect(rows == existing)
    }

    @Test("비어 있을 때만 후보가 줄로 선다")
    func candidatesFillOnlyWhenEmpty() {
        let rows = IntakeRepository.rows(candidates: ["하나", "둘"], existing: [])
        #expect(rows.map(\.text) == ["하나", "둘"])
        #expect(rows.allSatisfy { !$0.isSelected && !$0.isOwn })
    }

    @Test("다섯 개가 차면 빈 칸이 사라진다")
    func blankRowHidesWhenFull() {
        let full = (1...BriefCardQuestions.max).map { IntakeQuestionRow(text: "질문 \($0)", isSelected: true) }
        #expect(!IntakeRepository.showsBlankRow(full))
        #expect(IntakeRepository.showsBlankRow(Array(full.dropLast())))
    }

    @Test("고른 줄만 화면 순서대로 간다")
    func selectedRowsKeepScreenOrder() {
        let rows = [
            IntakeQuestionRow(text: "하나", isSelected: true),
            IntakeQuestionRow(text: "둘", isSelected: false),
            IntakeQuestionRow(text: "셋", isSelected: true)
        ]
        #expect(IntakeRepository.selected(in: rows) == ["하나", "셋"])
    }

    @Test("고른 것이 없으면 정리 문장이 서지 않는다")
    func noSummaryWithoutSelection() {
        #expect(IntakeRepository.summary(rows: [IntakeQuestionRow(text: "하나")]) == nil)
    }

    @Test("정리 문장은 고른 수를 세고 직접 적은 것이 있으면 마무리로 바뀐다")
    func summaryCountsAndSwitchesTail() {
        let suggested = [
            IntakeQuestionRow(text: "하나", isSelected: true),
            IntakeQuestionRow(text: "둘", isSelected: true)
        ]
        #expect(IntakeRepository.summary(rows: suggested) == "질문 2개를 카드에 담을게요.\n더 묻고 싶은 게 있으면 빈 칸에 적어주세요.")

        let withOwn = suggested + [IntakeQuestionRow(text: "셋", isSelected: true, isOwn: true)]
        #expect(IntakeRepository.summary(rows: withOwn) == "질문 3개를 카드에 담을게요.\n진료실에서 순서대로 물어보세요.")

        // 적어 넣고 체크를 푼 줄도 "직접 적은 것"이다(Android IntakeQuestionRows와 같다).
        let unchecked = suggested + [IntakeQuestionRow(text: "셋", isOwn: true)]
        #expect(IntakeRepository.summary(rows: unchecked) == "질문 2개를 카드에 담을게요.\n진료실에서 순서대로 물어보세요.")
    }

    // MARK: - 말로 넘기기

    @Test("문답이 끝나면 다음이라고 말해 넘어간다")
    func sayingNextAdvances() {
        #expect(IntakeVoiceCommand.isNext("다음"))
        // 받아쓰기가 마침표를 붙여 올 때가 있다.
        #expect(IntakeVoiceCommand.isNext("다음."))
        #expect(!IntakeVoiceCommand.isNext("다음에 할게요"))
    }

    @Test("받아쓰기는 1초에 보내고 5초에 닫는다")
    func dictationTimings() {
        #expect(DictationTiming.send == 1)
        #expect(DictationTiming.close == 5)
    }

    // MARK: - 조사

    @Test("부위 이름의 받침에 따라 조사가 갈린다")
    func particleFollowsFinalConsonant() {
        #expect(KoreanParticle.subject(after: "복부") == "가")
        #expect(KoreanParticle.subject(after: "손목") == "이")
        // 한글이 아닌 글자로 끝나면 읽는 소리를 추측하지 않는다.
        #expect(KoreanParticle.subject(after: "MRI") == "가")
    }
}

/// 화면이 들고 있는 상태.
@MainActor
struct IntakeModelTests {
    private func model(rows: [IntakeQuestionRow] = []) -> IntakeModel {
        let model = IntakeModel(site: IntakeSite(text: "복부"), repository: IntakeRepository(client: Stub.client))
        for row in rows { model.addOwn(row.text) }
        return model
    }

    @Test("직접 적은 질문은 적자마자 체크된 채로 선다")
    func ownQuestionArrivesChecked() {
        let model = model()
        model.addOwn("  공복으로 가야 하나요?  ")
        #expect(model.rows.count == 1)
        #expect(model.rows[0].text == "공복으로 가야 하나요?")
        #expect(model.rows[0].isSelected)
        #expect(model.rows[0].isOwn)
        #expect(!model.isWritingOwn)
    }

    @Test("빈 글은 줄이 되지 않는다")
    func blankTextMakesNoRow() {
        let model = model()
        model.addOwn("   ")
        #expect(model.rows.isEmpty)
    }

    @Test("다섯 개가 차면 더 체크되지 않는다")
    func cannotCheckBeyondFive() {
        let model = model(rows: (1...BriefCardQuestions.max).map { IntakeQuestionRow(text: "질문 \($0)") })
        #expect(model.isFull)

        model.addOwn("여섯 번째")
        #expect(model.rows.count == BriefCardQuestions.max)

        // 푸는 것은 언제나 된다.
        let first = model.rows[0]
        model.toggle(first)
        #expect(!model.rows[0].isSelected)
        #expect(!model.isFull)
    }

    @Test("받아쓰기를 끄면 켜기 전 글로 되돌린다")
    func cancellingDictationRestoresText() {
        let model = model()
        model.draft = "적다 만 글"
        model.rememberDraftBeforeVoice()
        model.previewVoice("말한 글")
        #expect(model.draft == "말한 글")
        model.restoreDraftBeforeVoice()
        #expect(model.draft == "적다 만 글")
    }

    @Test("빈 칸 번호는 줄 다음이다")
    func blankRowNumberFollowsRows() {
        let model = model(rows: [IntakeQuestionRow(text: "하나"), IntakeQuestionRow(text: "둘")])
        #expect(model.blankNumber == 3)
    }
}

private enum Stub {
    @MainActor static let client = AppEnvironment().client
}
