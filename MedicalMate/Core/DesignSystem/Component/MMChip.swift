import SwiftUI

/// 디자인 시스템 `Chip` (Figma `311:823`).
///
/// Figma 설명 그대로:
/// > 증상·부위처럼 짧은 항목을 고르는 pill. 높이 40 · 반경 20. 선택은 primary tint 면 +
/// > 1.5px brand 테두리 + 체크 세 가지를 겹친다. **색만으로 구분하지 않는다.** 한 줄에
/// > 여러 개를 흘려 배치하고 줄바꿈은 Wrap으로 처리한다. **항목이 6개를 넘어가면 Chip
/// > 대신 세로 목록을 쓴다** — 가로로 흐르면 뒤쪽 항목이 잘 안 읽힌다.
///
/// **체크는 마스터에 없다.** 설명은 "체크를 겹친다"고 적었는데 `Select / Selected`
/// 마스터(`311:819`)에는 체크 레이어가 없다. 임의로 그리지 않고 디자인 트랙에 물어야
/// 한다. 지금은 면 + 1.5px 테두리 둘이고, 선택 상태는 접근성 특성으로도 읽힌다.
struct MMChip: View {
    let text: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .mmTextStyle(MMFont.labelM)
                .lineLimit(1)
                .padding(.horizontal, MMSpace.s16)
                .frame(minWidth: Metrics.minWidth)
                .frame(height: Metrics.height)
        }
        .buttonStyle(Style(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private enum Metrics {
        static let height: CGFloat = MMSize.controlSm
        static let minWidth: CGFloat = 64
        static let selectedBorderWidth: CGFloat = 1.5
        static let borderWidth: CGFloat = 1
    }

    private struct Style: ButtonStyle {
        let isSelected: Bool

        func makeBody(configuration: Configuration) -> some View {
            let background: Color = isSelected
                ? MMColor.bgPrimarySubtle
                : (configuration.isPressed ? MMColor.bgSubtle : MMColor.bgSurface)

            return configuration.label
                .foregroundStyle(isSelected ? MMColor.fgPrimary : MMColor.fgDefault)
                .background(background)
                .clipShape(Capsule())
                .overlay {
                    Capsule().strokeBorder(
                        isSelected ? MMColor.borderPrimary : MMColor.borderDefault,
                        lineWidth: isSelected ? Metrics.selectedBorderWidth : Metrics.borderWidth
                    )
                }
        }
    }
}

/// `Chip / Type=Info` (Figma `3610:10205`).
///
/// Figma 설명 그대로: 정보 표시용 칩(**누르지 않는다**). 어두운 primary 면 + 흰 글자.
/// 예: 내보내기 미리보기의 "긴 이미지 1장".
struct MMInfoChip: View {
    let text: String

    var body: some View {
        Text(text)
            .mmTextStyle(MMFont.labelXS)
            .foregroundStyle(MMColor.fgOnInverse)
            .lineLimit(1)
            .padding(.horizontal, MMSpace.s10)
            .padding(.vertical, MMSpace.s4)
            .background(MMColor.bgPrimaryStrong)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: MMSpace.s12) {
        HStack(spacing: MMSpace.s8) {
            MMChip(text: "두통") {}
            MMChip(text: "두통", isSelected: true) {}
        }
        MMInfoChip(text: "긴 이미지 1장")
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
