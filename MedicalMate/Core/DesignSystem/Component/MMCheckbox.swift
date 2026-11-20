import SwiftUI

/// 디자인 시스템 `Checkbox` (Figma `311:851`).
///
/// Figma 설명 그대로:
/// > 동의·다중 선택. 박스 24 · 반경 8, **행 높이 52로 터치 하한을 넘는다. 누를 수 있는
/// > 영역은 행 전체다.** 미선택 테두리는 `border/strong` 1.5px(3.78:1) —
/// > `border/default`(1.64)로는 비텍스트 3:1을 통과하지 못한다.
///
/// 행 높이 52는 글자(Body/L, 26) + 위아래 14다. 글이 길어 두 줄이 되면 행도 함께 늘어난다.
struct MMCheckbox: View {
    let text: String
    @Binding var isOn: Bool

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(alignment: .center, spacing: MMSpace.s12) {
                box
                Text(text)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(isEnabled ? MMColor.fgDefault : MMColor.fgDisabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, MMSpace.s14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var box: some View {
        RoundedRectangle(cornerRadius: MMRadius.xs)
            .fill(isOn && isEnabled ? MMColor.bgPrimary : MMColor.bgSurface)
            .overlay {
                if isOn && isEnabled {
                    MMIcon.check.view(size: Metrics.check)
                        .foregroundStyle(MMColor.fgOnPrimary)
                } else {
                    RoundedRectangle(cornerRadius: MMRadius.xs)
                        .strokeBorder(
                            isEnabled ? MMColor.borderStrong : MMColor.borderSubtle,
                            lineWidth: Metrics.borderWidth
                        )
                }
            }
            .frame(width: Metrics.box, height: Metrics.box)
    }

    private enum Metrics {
        static let box: CGFloat = MMSize.iconLg
        static let check: CGFloat = 16
        static let borderWidth: CGFloat = 1.5
    }
}

#Preview {
    @Previewable @State var on = true
    @Previewable @State var off = false

    return VStack(spacing: 0) {
        MMCheckbox(text: "진료 기록을 병원에 전달하는 것에 동의합니다", isOn: $off)
        MMCheckbox(text: "진료 기록을 병원에 전달하는 것에 동의합니다", isOn: $on)
        MMCheckbox(text: "진료 기록을 병원에 전달하는 것에 동의합니다", isOn: $off).disabled(true)
    }
    .padding(.horizontal, MMSize.gutter)
    .background(MMColor.bgCanvas)
}
