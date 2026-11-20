import SwiftUI

/// 디자인 시스템 `Icon Button` (Figma `298:715`).
///
/// Figma 설명 그대로:
/// > 라벨 없이 아이콘만. L 48 · M 40 · S 32, 아이콘 24 / 20 / 18. **뒤로가기·닫기·더보기처럼
/// > 뜻이 자명한 동작에만 쓴다. 의미가 자명하지 않으면 라벨 있는 Button을 쓴다.**
/// > S 32는 카드 안쪽·행 끝처럼 공간이 좁을 때만 쓰고, **터치 영역은 부모 프레임에서
/// > 44 이상을 확보한다. 하단 액션 영역에는 쓰지 않는다** — 거기는 라벨 있는 버튼 자리다.
///
/// 아이콘 색은 마스터의 내보내기에서 확인한 값이다 — Ghost·Outline은 `fg/default`,
/// Tonal은 `fg/primary`, Solid는 `fg/on-primary`.
///
/// **`accessibilityLabel`이 필수다.** 라벨이 없으니 스크린 리더가 읽을 것이 그것뿐이다.
struct MMIconButton: View {
    enum Style { case ghost, tonal, solid, outline }
    enum Size { case l, m, s }

    let icon: MMIcon
    /// 스크린 리더가 읽을 이름.
    let label: String
    var style: Style = .ghost
    var size: Size = .l
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.view(size: size.iconSize)
                .foregroundStyle(style.iconColor)
                .frame(width: size.frame, height: size.frame)
                .background(style.container)
                .clipShape(RoundedRectangle(cornerRadius: size.radius))
                .overlay {
                    if let border = style.border {
                        RoundedRectangle(cornerRadius: size.radius)
                            .strokeBorder(border, lineWidth: 1)
                    }
                }
                // S 32는 그대로 두면 터치 하한을 넘지 못한다. 눌리는 영역만 넓힌다.
                .frame(minWidth: MMSize.touchMin, minHeight: MMSize.touchMin)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}

extension MMIconButton.Size {
    var frame: CGFloat {
        switch self {
        case .l: MMSize.controlMd
        case .m: MMSize.controlSm
        case .s: 32
        }
    }

    var radius: CGFloat {
        switch self {
        case .l: MMRadius.xl
        case .m: MMRadius.lg
        case .s: MMRadius.md
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .l: MMSize.iconLg
        case .m: MMSize.iconMd
        case .s: MMSize.iconSm
        }
    }
}

private extension MMIconButton.Style {
    var container: Color {
        switch self {
        case .ghost: .clear
        case .tonal: MMColor.bgPrimarySubtle
        case .solid: MMColor.bgPrimary
        case .outline: MMColor.bgSurface
        }
    }

    var iconColor: Color {
        switch self {
        case .ghost, .outline: MMColor.fgDefault
        case .tonal: MMColor.fgPrimary
        case .solid: MMColor.fgOnPrimary
        }
    }

    var border: Color? {
        self == .outline ? MMColor.borderDefault : nil
    }
}

#Preview {
    VStack(spacing: MMSpace.s12) {
        ForEach([MMIconButton.Size.l, .m, .s], id: \.self) { size in
            HStack(spacing: MMSpace.s12) {
                MMIconButton(icon: .chevronLeft, label: "뒤로", style: .ghost, size: size) {}
                MMIconButton(icon: .chevronLeft, label: "뒤로", style: .tonal, size: size) {}
                MMIconButton(icon: .chevronLeft, label: "뒤로", style: .solid, size: size) {}
                MMIconButton(icon: .chevronLeft, label: "뒤로", style: .outline, size: size) {}
            }
        }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}

extension MMIconButton.Size: Hashable {}
