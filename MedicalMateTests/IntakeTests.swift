import Foundation
import Testing
@testable import MedicalMate

/// D 섹션 — 증상 정리 2 · 3단계의 규칙.
struct IntakeTests {
    // MARK: - 강도

    @Test func 강도요청은_화면에_보이는_낱말을_함께_보낸다() {
        let request = IntakeRepository.severityRequest(level: 3)
        #expect(request.level == 3)
        // 낱말은 디자인 카피라 앱이 들고 보낸다. 서버가 들고 있으면 문구를 바꿀 때마다
        // 배포해야 한다.
        #expect(request.label == "꽤 아파요")
    }

    @Test func 강도는_1에서_5로_잘린다() {
        #expect(IntakeRepository.severityRequest(level: 0).label == MMSeverityLevel.of(1).title)
        #expect(IntakeRepository.severityRequest(level: 9).label == MMSeverityLevel.of(5).title)
    }

    // MARK: - 대화

    @Test func 대화는_seq_순으로_서고_역할이_갈린다() {
        let messages = IntakeRepository.messages(from: [
            MessageResponse(seq: 2, role: "USER", text: "한 3주쯤 됐어요."),
            MessageResponse(seq: 1, role: "AI", text: "언제부터 그러셨어요?")
        ])
        #expect(messages.map(\.text) == ["언제부터 그러셨어요?", "한 3주쯤 됐어요."])
        #expect(messages.map(\.fromPatient) == [false, true])
    }

    // MARK: - 추천 질문

    @Test func 후보는_rank_순이다() {
        // 서버가 정렬해 주지만 순서를 믿지 않는다.
        let candidates = IntakeRepository.candidates(from: [
            QuestionCandidateResponse(text: "셋", rank: 3),
            QuestionCandidateResponse(text: "하나", rank: 1),
            QuestionCandidateResponse(text: "둘", rank: 2)
        ])
        #expect(candidates == ["하나", "둘", "셋"])
    }

    @Test func 환자가_손댄_줄은_서버_후보로_덮지_않는다() {
        // 덮으면 지운 질문이 되살아나고 직접 적은 줄이 사라진다.
        let existing = [IntakeQuestionRow(text: "공복으로 가야 하나요?", isSelected: true, isOwn: true)]
        let rows = IntakeRepository.rows(candidates: ["검사를 받아야 하나요?"], existing: existing)
        #expect(rows == existing)
    }

    @Test func 비어_있을_때만_후보가_줄로_선다() {
        let rows = IntakeRepository.rows(candidates: ["하나", "둘"], existing: [])
        #expect(rows.map(\.text) == ["하나", "둘"])
        #expect(rows.allSatisfy { !$0.isSelected && !$0.isOwn })
    }

    @Test func 다섯_개가_차면_빈_칸이_사라진다() {
        let full = (1...BriefCardQuestions.max).map { IntakeQuestionRow(text: "질문 \($0)", isSelected: true) }
        #expect(!IntakeRepository.showsBlankRow(full))
        #expect(IntakeRepository.showsBlankRow(Array(full.dropLast())))
    }

    @Test func 고른_줄만_화면_순서대로_간다() {
        let rows = [
            IntakeQuestionRow(text: "하나", isSelected: true),
            IntakeQuestionRow(text: "둘", isSelected: false),
            IntakeQuestionRow(text: "셋", isSelected: true)
        ]
        #expect(IntakeRepository.selected(in: rows) == ["하나", "셋"])
    }

    @Test func 고른_것이_없으면_정리_문장이_서지_않는다() {
        #expect(IntakeRepository.summary(rows: [IntakeQuestionRow(text: "하나")]) == nil)
    }

    @Test func 질문_줄_위의_AI_말은_추천만_센다() {
        // 환자가 직접 적은 줄은 AI가 고른 것이 아니다(3663:7218).
        let rows = [
            IntakeQuestionRow(text: "검사를 받아야 하나요?"),
            IntakeQuestionRow(text: "지금 진통제 계속 먹어도 되나요?"),
            IntakeQuestionRow(text: "내가 적은 질문", isSelected: true, isOwn: true)
        ]
        #expect(IntakeRepository.intro(rows: rows) == "물어볼 질문 2개를 골라봤어요.\n눌러서 카드에 담아주세요.")
    }

    @Test func 추천이_없으면_AI_말이_서지_않는다() {
        #expect(IntakeRepository.intro(rows: []) == nil)
        #expect(IntakeRepository.intro(rows: [IntakeQuestionRow(text: "내가 적은 질문", isOwn: true)]) == nil)
    }

    @Test func 정리_문장은_고른_수를_세고_직접_적은_것이_있으면_마무리로_바뀐다() {
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

    @Test func 문답이_끝나면_다음이라고_말해_넘어간다() {
        #expect(IntakeVoiceCommand.isNext("다음"))
        // 받아쓰기가 마침표를 붙여 올 때가 있다.
        #expect(IntakeVoiceCommand.isNext("다음."))
        #expect(!IntakeVoiceCommand.isNext("다음에 할게요"))
    }

    @Test func 받아쓰기는_1초에_보내고_5초에_닫는다() {
        #expect(DictationTiming.send == 1)
        #expect(DictationTiming.close == 5)
    }

    // MARK: - 조사

    @Test func 부위_이름의_받침에_따라_조사가_갈린다() {
        #expect(KoreanParticle.subject(after: "복부") == "가")
        #expect(KoreanParticle.subject(after: "손목") == "이")
        // 한글이 하나도 없으면 읽는 소리를 추측하지 않는다.
        #expect(KoreanParticle.subject(after: "MRI") == "가")
    }

    @Test func 괄호로_끝나는_이름은_마지막_한글_음절로_조사를_정한다() {
        // 온톨로지의 부위 이름이 괄호로 끝난다. 맨 끝 글자만 보면 늘 "가"가 붙어
        // "목 안(목구멍)가"가 된다.
        #expect(KoreanParticle.subject(after: "목 안(목구멍)") == "이")
        #expect(KoreanParticle.subject(after: "윗배(명치)") == "가")
        #expect(KoreanParticle.subject(after: "가슴 옆(갈비)") == "가")
        #expect(KoreanParticle.object(after: "목 안(목구멍)") == "을")
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

    @Test func 직접_적은_질문은_적자마자_체크된_채로_선다() {
        let model = model()
        model.addOwn("  공복으로 가야 하나요?  ")
        #expect(model.rows.count == 1)
        #expect(model.rows[0].text == "공복으로 가야 하나요?")
        #expect(model.rows[0].isSelected)
        #expect(model.rows[0].isOwn)
        #expect(!model.isWritingOwn)
    }

    @Test func 빈_글은_줄이_되지_않는다() {
        let model = model()
        model.addOwn("   ")
        #expect(model.rows.isEmpty)
    }

    @Test func 다섯_개가_차면_더_체크되지_않는다() {
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

    @Test func 받아쓰기를_끄면_켜기_전_글로_되돌린다() {
        let model = model()
        model.draft = "적다 만 글"
        model.rememberDraftBeforeVoice()
        model.previewVoice("말한 글")
        #expect(model.draft == "말한 글")
        model.restoreDraftBeforeVoice()
        #expect(model.draft == "적다 만 글")
    }

    @Test func 빈_칸_번호는_줄_다음이다() {
        let model = model(rows: [IntakeQuestionRow(text: "하나"), IntakeQuestionRow(text: "둘")])
        #expect(model.blankNumber == 3)
    }
}

private enum Stub {
    @MainActor static let client = AppEnvironment().client
}
