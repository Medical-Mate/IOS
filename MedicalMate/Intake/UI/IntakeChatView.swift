import SwiftUI

/// `1c-2` · `1c-3` 증상 문답과 `1c-D` ~ `1c-D4` 추천 질문 (3/3).
///
/// **여섯 장이 한 화면이다.** 와이어프레임이 장을 나눈 것은 상태가 다른 것이지 화면이
/// 다른 것이 아니다 — 추천 질문은 같은 대화 아래에 줄로 서고(`3663:7222`가 마지막 환자
/// 말을 그대로 들고 있다), 아래 칸만 입력 줄에서 "다음" 버튼으로 바뀐다.
///
/// | 장 | 이 화면의 상태 |
/// | -- | -- |
/// | `1c-2` 직접 입력 (`3919:24204`) | 문답 중 · 입력 줄 |
/// | `1c-2` 음성 입력 (`3663:7181`) | 문답 중 · 받아쓰기 패널 |
/// | `1c-3` 음성 대기 (`3663:7196`) | 보낸 뒤 AI가 답을 짓는 중 |
/// | `1c-D` ~ `1c-D4` (`3663:7218`~`7276`) | 문답이 끝나 질문 줄이 선 뒤 |
struct IntakeChatView: View {
    @Bindable var model: IntakeModel
    let onBack: () -> Void

    @State private var dictation = DictationController()

    var body: some View {
        VStack(spacing: 0) {
            MMNavBar(title: "증상 정리", leading: .back, onLeading: onBack)

            conversation

            footer
        }
        .background(MMColor.bgSurface)
        .onAppear(perform: wireDictation)
        .onDisappear { dictation.stop() }
    }

    // MARK: - 대화

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: MMSpace.s14) {
                    MMProgressIndicator(
                        label: IntakeStep.label,
                        step: IntakeStep.chat.rawValue,
                        total: IntakeStep.total
                    )

                    siteContext

                    ForEach(model.messages) { message in
                        bubble(message)
                    }

                    if model.isAnswering {
                        answering
                    }

                    if model.isEnded {
                        questions
                    }

                    if let message = model.errorMessage {
                        Text(message)
                            .mmTextStyle(MMFont.bodyS)
                            .foregroundStyle(MMColor.fgDanger)
                    }

                    Color.clear.frame(height: 1).id(ChatAnchor.bottom)
                }
                .padding(.horizontal, MMSize.gutter)
                .padding(.top, MMSpace.s12)
                .padding(.bottom, MMSpace.s24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .overlay(alignment: .bottom) { voicePanel }
            .onChange(of: model.messages.count) { _, _ in scroll(proxy) }
            .onChange(of: model.isAnswering) { _, _ in scroll(proxy) }
            .onChange(of: model.isEnded) { _, _ in scroll(proxy) }
        }
    }

    /// "짚은 부위" + 고른 부위 칩. 누르는 자리가 아니라 지금 무엇을 말하는 중인지를
    /// 알려 주는 자리다.
    private var siteContext: some View {
        HStack(spacing: MMSpace.s8) {
            Text("짚은 부위")
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
            MMChip(text: model.site.text, isSelected: true, action: {})
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func bubble(_ message: IntakeMessage) -> some View {
        if message.fromPatient {
            HStack(spacing: 0) {
                Spacer(minLength: MMSpace.s32)
                MMBubble(text: message.text, sender: .patient)
            }
        } else {
            MMBubble(text: message.text, sender: .ai)
        }
    }

    /// AI가 답을 짓는 중(`1c-3`). "AI" 라벨 아래에 점 셋이 선다.
    private var answering: some View {
        VStack(alignment: .leading, spacing: MMSpace.s4) {
            Text("AI")
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgSubtle)
            MMTypingIndicator()
        }
    }

    // MARK: - 추천 질문

    private var questions: some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
            // 줄 위의 AI 말(`3663:7218`). 무엇을 왜 보여주는지를 먼저 적는다.
            if let intro = model.questionIntro {
                MMBubble(text: intro, sender: .ai)
            }

            VStack(spacing: MMSpace.s8) {
                ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                    MMQuestionRow(
                        number: index + 1,
                        text: row.text,
                        state: row.isSelected ? .selected : .default
                    ) {
                        model.toggle(row)
                    }
                }

                if model.showsBlankRow {
                    blankRow
                }
            }

            if let summary = model.questionSummary {
                MMBubble(text: summary, sender: .ai)
            }
        }
    }

    /// 빈 칸. 누르면 아래 입력 줄이 서고(`1c-D2`), 적는 동안 "작성 중…"이 된다(`1c-D3`).
    private var blankRow: some View {
        MMQuestionRow(
            number: model.blankNumber,
            text: blankText,
            state: blankState
        ) {
            model.beginWritingOwn()
        }
    }

    private var blankText: String {
        guard model.isWritingOwn else { return "질문 직접 추가" }
        return model.draft.isEmpty ? "" : "작성 중…"
    }

    private var blankState: MMQuestionRow.State {
        guard model.isWritingOwn else { return .add }
        return model.draft.isEmpty ? .focus : .writing
    }

    // MARK: - 아래 칸

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 0) {
            if model.isEnded, !model.isWritingOwn {
                MMButton("다음") {
                    Task { await model.confirmQuestions() }
                }
                .disabled(model.isBusy || model.selectedQuestions.isEmpty)
            } else {
                MMChatComposer(
                    text: $model.draft,
                    showsMic: dictation.isAvailable,
                    onMic: toggleDictation,
                    onSend: submit
                )
                .disabled(model.isAnswering)
            }
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .background(MMColor.bgSurface)
    }

    /// 받아쓰기 패널(`Voice Input · Mate`). 대화 위에 떠서 아래 16에 선다.
    @ViewBuilder
    private var voicePanel: some View {
        if dictation.isListening {
            MMVoiceInputMate(title: "말씀해 주세요", message: "듣고 있어요")
                .frame(width: MMSize.contentWidth)
                .padding(.bottom, MMSpace.s16)
                .transition(.opacity)
        }
    }

    // MARK: - 움직임

    private func submit(_ text: String) {
        if model.isWritingOwn {
            model.addOwn(text)
        } else {
            Task { await model.send(text, by: dictation.isListening ? .voice : .text) }
        }
    }

    private func toggleDictation() {
        if dictation.isListening {
            // 끄면 입력칸은 음성을 켜기 전에 적은 글로 되돌린다.
            dictation.stop()
            model.restoreDraftBeforeVoice()
        } else {
            model.rememberDraftBeforeVoice()
            Task { await dictation.start() }
        }
    }

    private func wireDictation() {
        dictation.onAutoSend = { text in
            model.previewVoice(text)
            // 문답이 끝난 뒤에는 "다음"이라고 말해 넘어갈 수 있다.
            if model.isEnded {
                handleSpokenCommand(text)
            } else {
                model.draft = ""
                Task { await model.send(text, by: .voice) }
            }
        }
        dictation.onSilentClose = {
            model.restoreDraftBeforeVoice()
        }
    }

    private func handleSpokenCommand(_ text: String) {
        let said = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if IntakeVoiceCommand.isNext(said) {
            model.draft = ""
            Task { await model.confirmQuestions() }
        } else if model.isWritingOwn {
            model.addOwn(said)
        }
    }
}

private enum ChatAnchor: Hashable { case bottom }

private func scroll(_ proxy: ScrollViewProxy) {
    withAnimation(.easeOut(duration: 0.2)) {
        proxy.scrollTo(ChatAnchor.bottom, anchor: .bottom)
    }
}

/// 말로 넘기는 낱말.
///
/// **문답이 끝나면 "다음"이라고 말해 넘어갈 수 있다**(FEATURE-SPEC 2.3). 받아쓰기가
/// 마침표를 붙여 올 때가 있어 문장부호를 떼고 본다.
enum IntakeVoiceCommand {
    static func isNext(_ said: String) -> Bool {
        let bare = said.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
        return bare == "다음"
    }
}
