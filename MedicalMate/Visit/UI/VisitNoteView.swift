import SwiftUI

/// `1p · 진료 후 메모` (Figma `3663:14352` · `3663:14377` · `1p-T` `3663:14402`).
///
/// 세 장이 한 화면이다 — 빈 칸, 적은 뒤, 받아쓰는 중. **녹음은 저장하지 않는다.**
/// 음성으로 적어도 글만 남고 오디오는 기기 밖으로 나가지 않는다.
struct VisitNoteView: View {
    @Bindable var model: VisitFlowModel
    let onBack: () -> Void

    @State private var dictation = DictationController()
    /// 받아쓰기를 켜기 전 글. 끄면 이것으로 되돌린다.
    @State private var memoBeforeVoice = ""

    var body: some View {
        VStack(spacing: 0) {
            MMNavBar(title: "진료 후 기록", leading: .back, onLeading: onBack)

            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: MMSpace.s16) {
                        heading
                        card
                        MMTextArea(
                            text: $model.memo,
                            placeholder: "3일치 약 처방을 받았어요",
                            limit: VisitNoteMetrics.limit
                        )

                        if let message = model.errorMessage {
                            Text(message)
                                .mmTextStyle(MMFont.bodyS)
                                .foregroundStyle(MMColor.fgDanger)
                        }
                    }
                    .padding(.horizontal, MMSize.gutter)
                    .padding(.top, MMSpace.s12)
                    .padding(.bottom, MMSpace.s16)
                }
                .scrollBounceBehavior(.basedOnSize)

                // 받아쓰기가 불가능한 기기에서는 그리지 않는다.
                if dictation.isAvailable {
                    fab
                }

                if dictation.isListening {
                    MMVoiceInputMate(title: "말씀해 주세요", message: "듣고 있어요")
                        .frame(width: MMSize.contentWidth)
                        .padding(.bottom, MMSpace.s16)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            footer
        }
        .background(MMColor.bgSurface)
        .onAppear(perform: wireDictation)
        .onDisappear { dictation.stop() }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: MMSpace.s6) {
            Text("진료실에서 들은 말을\n그대로 남겨두세요")
                .mmTextStyle(MMFont.headingL)
                .foregroundStyle(MMColor.fgDefault)
                .fixedSize(horizontal: false, vertical: true)
            Text("기억나는 대로 편하게 적어주세요.")
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgSubtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 무엇에 대한 기록인지 알려 주는 자리. `bg/subtle` 면이고 **그림자가 없다** —
    /// 1e-1의 병원 카드와 달리 누르는 자리가 아니다.
    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: VisitNoteMetrics.iconGap) {
                MMIcon.hospital.view()
                    .foregroundStyle(MMColor.fgPrimary)
                    .frame(width: VisitNoteMetrics.iconBox, height: VisitNoteMetrics.iconBox)

                VStack(alignment: .leading, spacing: MMSpace.s2) {
                    Text(model.clinic?.name ?? "")
                        .mmTextStyle(MMFont.bodyLStrong)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(model.cardLine)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            MMDivider()
                .padding(.top, VisitNoteMetrics.dividerTop)

            // 마스터는 "오늘 진료 · 9월 12일"이다. 지난 날짜에 쓸 낱말이 Figma에 없어서
            // **그때는 날짜만 둔다** — 없는 문구를 지어내지 않는다.
            HStack(spacing: MMSpace.s6) {
                if model.isVisitToday {
                    Text("오늘 진료")
                        .mmTextStyle(MMFont.bodySStrong)
                        .foregroundStyle(MMColor.fgPrimary)
                    Text("· \(model.visitDayLabel)")
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                } else {
                    Text(model.visitDayLabel)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                }
            }
            .padding(.top, VisitNoteMetrics.metaTop)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MMSpace.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgSubtle)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
    }

    private var fab: some View {
        MMIconButton(icon: .mic, label: "말로 적기", style: .solid, size: .l, action: toggleDictation)
            .mmShadow(MMElevation.float)
            .padding(MMSize.gutter)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            MMButton("저장하기") {
                Task { await model.classifyMemo() }
            }
            .disabled(!model.canSaveNote || model.isBusy)
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .background(MMColor.bgSurface)
    }

    private func toggleDictation() {
        if dictation.isListening {
            dictation.stop()
            model.memo = memoBeforeVoice
        } else {
            memoBeforeVoice = model.memo
            Task { await dictation.start() }
        }
    }

    private func wireDictation() {
        dictation.onAutoSend = { text in
            // 문답과 달리 보내는 곳이 없다. 적던 글 뒤에 이어 붙인다.
            model.memo = VisitNoteView.joined(memoBeforeVoice, text)
        }
        dictation.onSilentClose = {
            model.memo = memoBeforeVoice
        }
    }

    /// 적던 글과 말한 글을 잇는다. 둘 다 있으면 사이에 공백 하나를 둔다.
    static func joined(_ typed: String, _ spoken: String) -> String {
        let left = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        if left.isEmpty { return right }
        if right.isEmpty { return left }
        return "\(left) \(right)"
    }
}

enum VisitNoteMetrics {
    /// 메모 상한. 마스터의 카운터가 "71 / 300"이다.
    static let limit = 300
    static let iconBox: CGFloat = 44
    static let iconGap: CGFloat = 13
    static let dividerTop: CGFloat = 13
    static let metaTop: CGFloat = 11
}
