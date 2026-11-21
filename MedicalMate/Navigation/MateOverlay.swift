import SwiftUI

/// 떠 있는 메이트 카드 레이어 (Figma J 섹션 `3671:11369`).
///
/// **딤이 없다.** 아래 화면은 그대로 보이고 그대로 눌린다 — 말로 부르는 것이 화면을
/// 가로막으면 안 된다. 탭바 위 12에 뜬다.
struct MateOverlay: View {
    @Bindable var model: MateModel

    var body: some View {
        if let state = model.state {
            MMMateCard(state: state, onClose: model.close)
                .padding(.bottom, MateOverlayMetrics.aboveTabBar)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                // 아래 화면을 그대로 쓸 수 있게 카드 밖은 터치를 넘긴다.
                .allowsHitTesting(true)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                // 받아쓰는 동안 제목이 따라 바뀐다(1n-1-M2).
                .onChange(of: model.dictation.transcript) { _, text in
                    model.typing(text)
                }
        }
    }
}

private enum MateOverlayMetrics {
    /// 탭바 위 12.
    static let aboveTabBar: CGFloat = MMSize.tabBarHeight + MMSpace.s12
}

#Preview {
    MMMateCard(state: .navigated(title: "캘린더로 옮겼어요", hint: "날짜를 말하면 그 날을 열어드려요"), onClose: {})
}
