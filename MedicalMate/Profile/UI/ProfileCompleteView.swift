import SwiftUI

/// `1b-4 · 신상정보 완료` (Figma `3663:6999`).
///
/// `bg/primary` 면에 로고 마크 106 · 제목 · 설명. 잠깐 보이고 홈으로 넘어간다.
///
/// 설명은 85%로 눌러 둔다 — 제목이 먼저 읽히게 하려는 마스터의 값이다.
struct ProfileCompleteView: View {
    /// 다음으로 넘어갈 때.
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: MMSpace.s10) {
                MMLogo.Symbol.mark.view(size: CompleteMetrics.mark)
                    .foregroundStyle(MMColor.fgOnPrimary)

                Text("내 정보가 등록되었어요")
                    .mmTextStyle(MMFont.headingL)
                    .foregroundStyle(MMColor.fgOnPrimary)

                Text("복용약 · 기저질환 · 알러지를 카드에 담았어요")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgOnPrimary)
                    .opacity(CompleteMetrics.messageOpacity)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, MMSize.gutter)
            .padding(.vertical, MMSpace.s16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Color.clear.frame(height: MMSize.safeBottom)
        }
        .background(MMColor.bgPrimary)
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(for: .seconds(CompleteMetrics.dwell))
            onFinish()
        }
    }
}

private enum CompleteMetrics {
    static let mark: CGFloat = 106
    static let messageOpacity: Double = 0.85
    /// 머무는 시간. 시안에 값이 없어 정한 것이고, 모션을 정하면 함께 맞춘다.
    static let dwell: Double = 1.6
}

#Preview {
    ProfileCompleteView {}
}
