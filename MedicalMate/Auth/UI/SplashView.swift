import SwiftUI

/// `V2 · 스플래시` (Figma `3663:6845`).
///
/// `bg/primary` 면에 로고 로크업(Mono Light)과 한 줄. 세션을 확인하는 동안만 보인다.
///
/// 로크업은 심볼 36이 기준인데 이 화면은 50.4로 키워 쓴다(×1.4). 워드마크도 같은
/// 비율로 커져 22 → 30이 된다 — 로크업을 통째로 키우는 것이라 비율이 유지된다.
struct SplashView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: MMSpace.s10) {
                MMLogo.Lockup.monoLight.view(height: SplashMetrics.lockupHeight)
                    .foregroundStyle(MMColor.fgOnInverse)

                Text("진료실에서 하고 싶은 말, 미리 정리해요")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgOnPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.vertical, MMSpace.s16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Color.clear.frame(height: MMSize.safeBottom)
        }
        .background(MMColor.bgPrimary)
        .ignoresSafeArea()
    }
}

private enum SplashMetrics {
    /// 심볼 50.4 기준. 로크업의 원본 높이 36에 ×1.4다.
    static let lockupHeight: CGFloat = 50.4
}

#Preview {
    SplashView()
}
