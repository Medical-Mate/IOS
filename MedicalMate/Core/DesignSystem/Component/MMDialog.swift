import SwiftUI

/// 디자인 시스템 `Dialog` (Figma `312:845`).
///
/// Figma 설명 그대로:
/// > **되돌릴 수 없는 동작의 확인.** 320 · 반경 24 · `Elevation/Sheet`. **상단 원형 아이콘
/// > 배지가 무슨 종류의 결정인지를 먼저 알린다** — 글을 읽기 전에 성격이 전달된다.
/// > 본문은 **"무엇을 잃는지"**를 말한다. 이 앱에서 잃는 것은 진료실에서 보여줄 내용이다.
/// > **일반 안내에는 쓰지 말고 Toast나 Notice로 충분한지 먼저 본다.**
///
/// 설명은 "취소가 왼쪽 Outline"이라고 적었는데 마스터의 취소는 Tonal(M)이다. 마스터를
/// 따랐다. 실행은 오른쪽 Danger(M)로 설명과 같다.
struct MMDialog: View {
    let title: String
    let message: String
    var icon: MMIcon = .trash
    var cancelTitle: String = "취소"
    var confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: MMSpace.s10) {
            icon.view()
                .foregroundStyle(MMColor.fgDanger)
                .frame(width: DialogMetrics.badge, height: DialogMetrics.badge)
                .background(MMColor.bgDanger)
                .clipShape(RoundedRectangle(cornerRadius: MMRadius.xl))

            VStack(spacing: MMSpace.s4) {
                Text(title)
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
            }
            .multilineTextAlignment(.center)
            .frame(width: DialogMetrics.contentWidth)

            HStack(spacing: MMSpace.s8) {
                MMButton(cancelTitle, kind: .tonal, size: .m, action: onCancel)
                MMButton(confirmTitle, kind: .danger, size: .m, action: onConfirm)
            }
            .padding(.top, MMSpace.s14)
            .frame(width: DialogMetrics.contentWidth)
        }
        .padding(.top, DialogMetrics.topPadding)
        .padding(.bottom, MMSpace.s16)
        .padding(.horizontal, MMSpace.s20)
        .frame(width: DialogMetrics.width)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xl))
        .mmShadow(MMElevation.sheet)
    }
}

private enum DialogMetrics {
    static let width: CGFloat = 320
    static let contentWidth: CGFloat = 280
    static let badge: CGFloat = MMSize.controlMd
    static let topPadding: CGFloat = MMRadius.xxl
}

#Preview {
    ZStack {
        MMColor.bgCanvas.ignoresSafeArea()
        MMOverlayScrim()
        MMDialog(
            title: "이 기록을 삭제할까요?",
            message: "삭제하면 되돌릴 수 없어요.",
            confirmTitle: "삭제",
            onCancel: {},
            onConfirm: {}
        )
    }
}
