import SwiftUI

/// `Button` 마스터의 고정 수치. 제네릭 타입 안에 정적 저장 프로퍼티를 둘 수 없어 밖에 있다.
private enum ButtonMetrics {
    static let gap: CGFloat = 6
    static let horizontalPadding: CGFloat = MMSpace.s20
    static let minWidth: CGFloat = 96
}

/// 디자인 시스템 `Button` (Figma `291:670`).
///
/// Figma 설명 그대로:
/// > 높이 L 56 · M 48 · S 40. 반경 16 / 14 / 12. 라벨 L·M은 Label/L(15), S는 Label/M(13).
/// > 한 줄에 두 개를 놓을 때는 각 인스턴스를 Fill로 둔다 — 폭이 고정이 아니라 컨테이너를
/// > 채운다. 주/보조를 나란히 둘 때는 보조를 왼쪽 Outline, 주를 오른쪽 Primary로 둔다.
/// > 방향이 있는 이동은 chevron을 쓰고, **라벨 없이 아이콘만 쓸 때는 Button이 아니라
/// > Icon Button을 쓴다.** Danger는 파스텔 면 + 진한 빨강 글자다. 파괴적 동작은 눈에 띄되
/// > 화면을 위협하지 않아야 하고, 실행 확인은 Dialog가 맡는다.
///
/// 마스터는 Type 5 × Size 3 × State 3 = 45 변형이다. `State`는 코드에서 변형이 아니라
/// 눌림·비활성으로 저절로 갈린다.
/// 버튼의 갈래. **제네릭 바깥에 둔다** — 안에 두면 쓰는 쪽이 `MMButton<_, _>.Kind`로
/// 가리켜야 한다(`MMCardEmphasis`와 같은 자리).
enum MMButtonKind { case primary, tonal, outline, ghost, danger }

struct MMButton<Leading: View, Trailing: View>: View {
    typealias Kind = MMButtonKind
    enum Size { case l, m, s }

    let title: String
    var kind: Kind = .primary
    var size: Size = .l
    /// 컨테이너를 채운다. 한 줄에 둘을 놓을 때 쓴다.
    var fill: Bool = true
    let action: () -> Void
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: ButtonMetrics.gap) {
                leading.frame(width: size.iconSize, height: size.iconSize)
                Text(title)
                    .mmTextStyle(size.label)
                    .lineLimit(1)
                trailing.frame(width: size.iconSize, height: size.iconSize)
            }
            .padding(.horizontal, ButtonMetrics.horizontalPadding)
            .frame(minWidth: ButtonMetrics.minWidth, maxWidth: fill ? .infinity : nil)
            .frame(height: size.height)
        }
        .buttonStyle(Style(kind: kind, size: size, isEnabled: isEnabled))
    }

    private struct Style: ButtonStyle {
        let kind: Kind
        let size: Size
        let isEnabled: Bool

        func makeBody(configuration: Configuration) -> some View {
            let state: State = isEnabled ? (configuration.isPressed ? .pressed : .default) : .disabled
            let look = Look(kind: kind, state: state)

            return configuration.label
                .foregroundStyle(look.label)
                .background(look.background)
                .clipShape(RoundedRectangle(cornerRadius: size.radius))
                .overlay {
                    if let border = look.border {
                        RoundedRectangle(cornerRadius: size.radius)
                            .strokeBorder(border, lineWidth: 1)
                    }
                }
        }
    }

    private enum State { case `default`, pressed, disabled }

    /// Figma 변형 하나의 면 · 글자 · 테두리.
    private struct Look {
        let background: Color
        let label: Color
        let border: Color?

        init(kind: Kind, state: State) {
            // 비활성은 종류와 상관없이 같다. Outline만 테두리가 옅어진다.
            if state == .disabled {
                background = MMColor.bgSubtle
                label = MMColor.fgDisabled
                border = kind == .outline ? MMColor.borderSubtle : nil
                return
            }

            switch kind {
            case .primary:
                background = state == .pressed ? MMColor.bgPrimaryPressed : MMColor.bgPrimary
                label = MMColor.fgOnPrimary
                border = nil
            case .tonal:
                // 눌리면 **옅어진다**(primary-subtle → primary-faint). 다른 종류와 방향이 반대다.
                background = state == .pressed ? MMColor.bgPrimaryFaint : MMColor.bgPrimarySubtle
                label = MMColor.fgPrimary
                border = nil
            case .outline:
                background = state == .pressed ? MMColor.bgSubtle : MMColor.bgSurface
                label = MMColor.fgPrimary
                border = MMColor.borderStrong
            case .ghost:
                // 기본은 면이 없다. 눌렸을 때만 깔린다.
                background = state == .pressed ? MMColor.bgSubtle : .clear
                label = MMColor.fgSubtle
                border = nil
            case .danger:
                // 눌려도 면이 그대로다. 파괴적 동작이라 눌림을 면으로 알리지 않는다.
                background = MMColor.bgDanger
                label = MMColor.fgDanger
                border = nil
            }
        }
    }
}

extension MMButton.Size {
    var height: CGFloat {
        switch self {
        case .l: MMSize.controlLg
        case .m: MMSize.controlMd
        case .s: MMSize.controlSm
        }
    }

    var radius: CGFloat {
        switch self {
        case .l: MMRadius.md
        case .m: MMRadius.buttonM
        case .s: MMRadius.sm
        }
    }

    var label: MMTextStyle {
        switch self {
        case .l, .m: MMFont.labelL
        case .s: MMFont.labelM
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .l, .m: MMSize.iconMd
        case .s: 16
        }
    }
}

// 아이콘 없이 쓰는 경우가 대부분이라 기본 생성자를 따로 둔다.
extension MMButton where Leading == EmptyView, Trailing == EmptyView {
    init(_ title: String, kind: Kind = .primary, size: Size = .l, fill: Bool = true, action: @escaping () -> Void) {
        self.init(
            title: title,
            kind: kind,
            size: size,
            fill: fill,
            action: action,
            leading: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}

#Preview {
    VStack(spacing: MMSpace.s12) {
        MMButton("다음 단계로", kind: .primary) {}
        MMButton("진료 기록 보기", kind: .tonal) {}
        MMButton("이전", kind: .outline) {}
        MMButton("나중에 하기", kind: .ghost) {}
        MMButton("예약 취소", kind: .danger) {}
        MMButton("다음 단계로", kind: .primary, size: .m) {}
        MMButton("다음 단계로", kind: .primary, size: .s) {}
        MMButton("비활성", kind: .primary) {}.disabled(true)
        HStack(spacing: MMSpace.s8) {
            MMButton("이전", kind: .outline) {}
            MMButton("다음", kind: .primary) {}
        }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
