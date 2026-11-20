import SwiftUI

/// 아래에서 올라오는 시트의 바깥 모양(1e-1-X `3663:7479` · 1e-1-S `3681:17846`).
///
/// 손잡이 36×4(`border/default`) · 위 모서리 `radius/2xl` · 패딩 위 12 · 아래 24 ·
/// 옆 20 · `Elevation/Sheet`. 두 시트가 같은 껍데기를 쓴다.
///
/// 시스템 시트(`.presentationDetents`)를 쓰지 않는 이유는 손잡이와 모서리가 마스터와
/// 다르고, 시트 위에 흐린 막(`Overlay Scrim`)을 우리 토큰으로 깔아야 해서다.
struct MMBottomSheet<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(MMColor.borderDefault)
                .frame(width: SheetMetrics.handle.width, height: SheetMetrics.handle.height)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            content
        }
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .padding(.horizontal, MMSize.gutter)
        .frame(maxWidth: .infinity)
        .background(MMColor.bgSurface)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: MMRadius.sheetTop,
                topTrailingRadius: MMRadius.sheetTop
            )
        )
        .mmShadow(MMElevation.sheet)
    }
}

enum SheetMetrics {
    static let handle = (width: CGFloat(36), height: CGFloat(4))
}

#Preview {
    ZStack(alignment: .bottom) {
        MMColor.bgCanvas
        MMBottomSheet {
            Text("진료 날짜가 정해졌나요?")
                .mmTextStyle(MMFont.headingM)
                .padding(.top, MMSpace.s14)
        }
    }
    .ignoresSafeArea()
}
