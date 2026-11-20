import SwiftUI

/// 디자인 시스템 `Waveform` (Figma `3539:5606`).
///
/// Figma 설명 그대로: **채우기 없는 파형(메이트 톤).** `Voice Input Mate` 안에서
/// `Size=L · 말하는 중`을 쓴다.
///
/// L은 72×72에 막대 5개(폭 8 · 반경 4 · 간격 8)이고 높이는 26 · 46 · 62 · 42 · 26이다.
/// `Mate Card` 안의 작은 파형은 40×48에 막대 폭 3 · 반경 1.5 · 간격 3이다.
struct MMWaveform: View {
    enum Size {
        /// `Voice Input Mate` 안의 72.
        case l
        /// `Mate Card` 안의 작은 것.
        case s
    }

    var size: Size = .l
    /// 듣는 중이 아니면 조금 가라앉는다(마스터의 85%).
    var isActive: Bool = true

    var body: some View {
        HStack(spacing: size.gap) {
            ForEach(Array(size.heights(active: isActive).enumerated()), id: \.offset) { _, height in
                RoundedRectangle(cornerRadius: size.barRadius)
                    .fill(MMColor.bgPrimary)
                    .frame(width: size.barWidth, height: height)
            }
        }
        .opacity(isActive ? 1 : WaveformMetrics.restingOpacity)
        .frame(width: size.frame.width, height: size.frame.height)
        .accessibilityHidden(true)
    }
}

private enum WaveformMetrics {
    static let restingOpacity: Double = 0.85
}

extension MMWaveform.Size {
    var frame: CGSize {
        switch self {
        case .l: CGSize(width: 72, height: 72)
        case .s: CGSize(width: 40, height: 48)
        }
    }

    var barWidth: CGFloat {
        switch self {
        case .l: 8
        case .s: 3
        }
    }

    var barRadius: CGFloat {
        switch self {
        case .l: 4
        case .s: 1.5
        }
    }

    var gap: CGFloat {
        switch self {
        case .l: MMSpace.s8
        case .s: 3
        }
    }

    func heights(active: Bool) -> [CGFloat] {
        switch self {
        case .l: [26, 46, 62, 42, 26]
        case .s: active ? [10, 18, 24, 16, 10] : [8, 12, 16, 12, 8]
        }
    }
}

/// 디자인 시스템 `Voice Input Mate` (Figma `3539:5647`).
///
/// Figma 설명 그대로: **진료 후 기록 받아쓰기(STT) 섹션**, 폭 320. **누르면 바로 듣기
/// 시작** — 파형 + "듣고 있어요". State = Listening.
struct MMVoiceInputMate: View {
    var title: String = "듣고 있어요"
    var message: String = "다 말씀하시면 한 번 더 눌러주세요"

    var body: some View {
        VStack(spacing: MMSpace.s16) {
            MMWaveform(size: .l)
            VStack(spacing: MMSpace.s4) {
                Text(title)
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, MMRadius.xxl)
        .padding(.bottom, MMSpace.s24)
        .padding(.horizontal, MMSpace.s20)
        .frame(maxWidth: .infinity)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xl))
        .mmShadow(MMElevation.card)
    }
}

#Preview {
    VStack(spacing: MMSpace.s24) {
        MMVoiceInputMate()
        MMWaveform(size: .s)
        MMWaveform(size: .s, isActive: false)
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
