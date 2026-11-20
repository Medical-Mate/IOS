import SwiftUI

/// `1c-5 · 증상 정리 완료` (Figma `3663:7292`).
///
/// 가운데 `bg/primary-faint` 원 배지에 `check-circle` 38, 아래에 두 줄. 버튼은 둘이고
/// **세로로 쌓인다** — 주(브리핑 카드 만들기) 위, 보조(진료받을 병원 먼저 찾기) 아래.
struct IntakeDoneView: View {
    let onCreateCard: () -> Void
    let onFindHospital: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MMNavBar(title: "증상 정리", leading: .back, onLeading: onBack)

            VStack(spacing: MMSpace.s10) {
                ZStack {
                    Circle().fill(MMColor.bgPrimaryFaint)
                    MMIcon.checkCircle.view(size: DoneMetrics.icon)
                        .foregroundStyle(MMColor.fgPrimary)
                }
                .frame(width: DoneMetrics.badge, height: DoneMetrics.badge)

                Text("증상 정리가 끝났어요")
                    .mmTextStyle(MMFont.headingL)
                    .foregroundStyle(MMColor.fgDefault)
                    .multilineTextAlignment(.center)

                Text("말씀하신 내용을 진료실에서 보여줄\n카드로 만들 준비가 됐어요")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, MMSize.gutter)
            .padding(.top, MMSpace.s20)
            .padding(.bottom, MMSpace.s40)

            VStack(spacing: MMSpace.s10) {
                MMButton("브리핑 카드 만들기", action: onCreateCard)
                MMButton("진료받을 병원 먼저 찾기", kind: .outline, action: onFindHospital)
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.top, MMSpace.s12)
            .padding(.bottom, MMSize.safeBottom)
        }
        .background(MMColor.bgSurface)
    }
}

private enum DoneMetrics {
    static let badge: CGFloat = 80
    static let icon: CGFloat = 38
}

#Preview {
    IntakeDoneView(onCreateCard: {}, onFindHospital: {}, onBack: {})
}
