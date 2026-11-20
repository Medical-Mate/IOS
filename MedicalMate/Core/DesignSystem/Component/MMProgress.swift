import SwiftUI

/// 디자인 시스템 `Progress Indicator` (Figma `334:1139`).
///
/// Figma 설명 그대로:
/// > 문답 진행. **연속 막대가 아니라 단계별 칸으로 끊는다** — 몇 개가 남았는지가
/// > 한눈에 보이고, 연속 막대는 "얼마나 남았는지"를 가늠하기 어렵다. **숫자(n/4)를
/// > 항상 병기한다. 막대만으로는 색각 이상에서 진행 상태가 전달되지 않는다(D11).**
/// > **문항이 6개를 넘으면** 칸이 너무 얇아지므로 연속 막대로 바꾸고 숫자를 크게 둔다.
///
/// 마스터는 4칸이지만 증상 정리는 3단계다. `total`을 받아 칸 수를 맞춘다.
struct MMProgressIndicator: View {
    let label: String
    let step: Int
    var total: Int = 4

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpace.s8) {
            HStack {
                Text(label)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(step) / \(total)")
                    .mmTextStyle(MMFont.bodySStrong)
                    .foregroundStyle(MMColor.fgPrimary)
            }

            HStack(spacing: ProgressMetrics.gap) {
                ForEach(1...max(total, 1), id: \.self) { index in
                    RoundedRectangle(cornerRadius: ProgressMetrics.radius)
                        .fill(index <= step ? MMColor.bgPrimary : MMColor.bgSubtle)
                        .frame(maxWidth: .infinity)
                        .frame(height: ProgressMetrics.height)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(total)단계 중 \(step)단계")
    }
}

private enum ProgressMetrics {
    static let height: CGFloat = 6
    static let gap: CGFloat = 5
    static let radius: CGFloat = 3
}

/// 디자인 시스템 `Onboarding Progress` (Figma `1155:854`).
///
/// Figma 설명 그대로:
/// > 온보딩 4단계 전용 진행 표시. **active는 `bg/primary` 20×6, inactive는 `bg/subtle`
/// > 6×6**, gap은 `space/8`, marker radius는 `radius/full`. **"총 4단계 중 n단계"라는
/// > 접근성 라벨은 구현 코드에서 제공하며 장식 점은 스크린리더에서 숨긴다.** 전환은
/// > 240ms, **Reduce Motion에서는 즉시 전환 또는 dissolve**를 쓴다.
struct MMOnboardingProgress: View {
    let step: Int
    var total: Int = 4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: MMSpace.s8) {
            ForEach(1...max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(index == step ? MMColor.bgPrimary : MMColor.bgSubtle)
                    .frame(width: index == step ? OnboardingMetrics.active : OnboardingMetrics.dot,
                           height: OnboardingMetrics.dot)
            }
        }
        .frame(height: MMSpace.s24)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("총 \(total)단계 중 \(step)단계")
    }
}

private enum OnboardingMetrics {
    static let dot: CGFloat = 6
    static let active: CGFloat = 20
}

#Preview {
    VStack(spacing: MMSpace.s24) {
        MMProgressIndicator(label: "증상 문답", step: 2)
        MMProgressIndicator(label: "증상 정리", step: 1, total: 3)
        MMOnboardingProgress(step: 2)
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
