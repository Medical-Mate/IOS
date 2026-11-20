import SwiftUI

/// 디자인 시스템 `Mate Card` (Figma `3532:5543`).
///
/// Figma 설명 그대로: **헤이 메이트 떠 있는 카드. 딤 없이 탭바 위 12에 뜬다.**
/// State = 듣는 중 · 가이드 / 말하는 중 / 답 / 화면 이동.
///
/// 336 · 반경 24 · pl16 pr10 py16 · `Elevation/Float`.
///
/// **호출어는 iOS에서 아직 정해지지 않았다**(`docs/AOS-IOS-DIFF.md` D1). 이 카드는
/// 마이크 버튼으로 열어도 같은 모양이라 먼저 옮겨 둔다.
struct MMMateCard: View {
    /// 가이드에 서는 한 줄.
    struct Guide: Identifiable {
        let id = UUID()
        let icon: MMIcon
        let phrase: String
        let meaning: String
    }

    enum State {
        /// 듣는 중 · 가이드. 할 수 있는 말을 함께 보인다.
        case listening(guides: [Guide])
        /// 말하는 중. 받아쓴 글이 제목에 선다.
        case speaking(text: String, pending: String = "")
        /// 답. 본문만 놓는다.
        case answer(String)
        /// 화면 이동. 어디로 갔는지와 다음에 할 수 있는 말을 적는다.
        case navigated(title: String, hint: String)
    }

    let state: State
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isGuide ? MMSpace.s12 : 0) {
            if case .listening(let guides) = state {
                guideSection(guides)
                MMDivider()
            }
            mainRow
        }
        .padding(.leading, MMSpace.s16)
        .padding(.trailing, MMSpace.s10)
        .padding(.vertical, MMSpace.s16)
        .frame(width: MateCardMetrics.width)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xl))
        .mmShadow(MMElevation.float)
    }

    private var isGuide: Bool {
        if case .listening = state { return true }
        return false
    }

    private func guideSection(_ guides: [Guide]) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s2) {
            Text("이렇게 말해도 돼요")
                .mmTextStyle(MMFont.labelM)
                .foregroundStyle(MMColor.fgSubtle)
            Spacer().frame(height: MMSpace.s4)

            ForEach(guides) { guide in
                HStack(spacing: MMSpace.s10) {
                    guide.icon.view(size: MMSize.iconSm)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(width: MateCardMetrics.iconCircle, height: MateCardMetrics.iconCircle)
                        .background(MMColor.bgSubtle)
                        .clipShape(Circle())

                    Text("\"\(guide.phrase)\"")
                        .mmTextStyle(MMFont.bodyMStrong)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(guide.meaning)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                }
                .frame(minHeight: MateCardMetrics.guideRow)
            }

            Spacer().frame(height: MMSpace.s8)
        }
        .padding(.trailing, MMSpace.s6)
    }

    private var mainRow: some View {
        HStack(spacing: MMSpace.s14) {
            MMWaveform(size: .s, isActive: isListeningOrSpeaking)

            VStack(alignment: .leading, spacing: MMSpace.s4) {
                text
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MMIconButton(icon: .close, label: "닫기", style: .ghost, size: .m, action: onClose)
        }
    }

    @ViewBuilder
    private var text: some View {
        switch state {
        case .listening:
            title("무엇을 도와드릴까요?")
            caption("듣고 있어요", color: MMColor.fgSubtle)

        case .speaking(let said, let pending):
            // 받아쓰는 중인 꼬리는 가라앉혀 아직 확정이 아님을 보인다.
            (Text(said).foregroundStyle(MMColor.fgDefault)
                + Text(pending).foregroundStyle(MMColor.fgMuted))
                .mmTextStyle(MMFont.headingS)
            caption("듣고 있어요", color: MMColor.fgSubtle)

        case .answer(let body):
            Text(body)
                .mmTextStyle(MMFont.bodyL)
                .foregroundStyle(MMColor.fgDefault)

        case .navigated(let heading, let hint):
            title(heading)
            caption(hint, color: MMColor.fgPrimary)
        }
    }

    private func title(_ value: String) -> some View {
        Text(value)
            .mmTextStyle(MMFont.headingS)
            .foregroundStyle(MMColor.fgDefault)
    }

    private func caption(_ value: String, color: Color) -> some View {
        Text(value)
            .mmTextStyle(MMFont.bodyS)
            .foregroundStyle(color)
    }

    private var isListeningOrSpeaking: Bool {
        switch state {
        case .listening, .speaking: true
        case .answer, .navigated: false
        }
    }
}

private enum MateCardMetrics {
    static let width: CGFloat = 336
    static let iconCircle: CGFloat = 28
    static let guideRow: CGFloat = 36
}

#Preview {
    ScrollView {
        VStack(spacing: MMSpace.s16) {
            MMMateCard(
                state: .listening(guides: [
                    .init(icon: .note, phrase: "배가 아파서 정리할래", meaning: "증상 정리"),
                    .init(icon: .edit, phrase: "진료 끝났어", meaning: "진료 후 기록"),
                    .init(icon: .calendar, phrase: "다음 진료 언제야", meaning: "일정 찾기"),
                ]),
                onClose: {}
            )
            MMMateCard(state: .speaking(text: "다음 진료 언제", pending: "야"), onClose: {})
            MMMateCard(state: .answer("9월 25일 (금) 오전 10:30,\n서울OO병원 내과 재진이에요"), onClose: {})
            MMMateCard(state: .navigated(title: "캘린더로 옮겼어요", hint: "날짜를 말하면 그 날을 열어드려요"), onClose: {})
        }
        .padding(MMSize.gutter)
    }
    .background(MMColor.bgCanvas)
}
