import SwiftUI

/// 디자인 시스템 `Tooltip` (Figma `542:1295`) — 말풍선을 여는 트리거.
///
/// 아이콘 24가 패딩 4를 두르고, 활성이면 `bg/primary-faint` 면이 깔린다. 바깥 패딩 8을
/// 더해 터치 영역을 만든다. 설명 자체는 ``MMTooltipBubble``이 그린다.
struct MMTooltip: View {
    @Binding var isPresented: Bool
    /// 스크린 리더가 읽을 이름. "무엇에 대한 설명인지"를 적는다.
    let label: String

    var body: some View {
        Button { isPresented.toggle() } label: {
            MMIcon.info.view()
                .foregroundStyle(MMColor.fgDefault)
                .padding(MMSpace.s4)
                .background(isPresented ? MMColor.bgPrimaryFaint : .clear)
                .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
                .padding(MMSpace.s8)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isPresented ? [.isSelected] : [])
    }
}

/// 디자인 시스템 `Tooltip Bubble` (Figma `575:1287`).
///
/// 180 폭 · 반경 10 · `bg/inverse-soft` 면 · `Label/S` 흰 글자 · `Elevation/Float`.
/// 위쪽 화살표가 오른쪽에서 16 떨어진 자리에 붙는다.
struct MMTooltipBubble: View {
    let text: String

    /// 마스터(`575:1287`)의 화살표 크기. 테스트가 못박는다.
    nonisolated static let arrowSize = CGSize(
        width: TooltipMetrics.arrowWidth, height: TooltipMetrics.arrowHeight
    )
    /// 말풍선 오른쪽 끝에서 화살표까지. 마스터가 x=148 · 폭 16 · 말풍선 180이다.
    nonisolated static let arrowInsetFromTrailing = TooltipMetrics.arrowInset
    nonisolated static let bubbleWidth = TooltipMetrics.width

    var body: some View {
        Text(text)
            .mmTextStyle(MMFont.labelS)
            .foregroundStyle(MMColor.fgOnInverse)
            // **세로로는 필요한 만큼 늘어난다.** 말풍선이 한 줄짜리 자리(설명 줄 옆)에
            // 얹히는 자리라, 이것이 없으면 부모 높이에 눌려 두 줄짜리 글이 한 줄로
            // 잘린다(`1q-1-T` `3663:14452` · `1e-1-T` `3663:7496`은 두 줄이다).
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MMSpace.s12)
            .padding(.vertical, MMSpace.s10)
            .frame(width: TooltipMetrics.width, alignment: .leading)
            .background(MMColor.bgInverseSoft)
            .clipShape(RoundedRectangle(cornerRadius: TooltipMetrics.radius))
            .overlay(alignment: .topTrailing) {
                Arrow()
                    .fill(MMColor.bgInverseSoft)
                    .frame(width: TooltipMetrics.arrowWidth, height: TooltipMetrics.arrowHeight)
                    .offset(x: -TooltipMetrics.arrowInset, y: -TooltipMetrics.arrowHeight + 1)
            }
            .mmShadow(MMElevation.float)
            .accessibilityElement(children: .combine)
    }

    /// 위를 가리키는 삼각형. 마스터의 화살표는 면과 같은 색이다.
    private struct Arrow: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
}

private enum TooltipMetrics {
    static let width: CGFloat = 180
    static let radius: CGFloat = 10
    static let arrowWidth: CGFloat = 16
    /// 마스터(`575:1287`)의 `Arrow`가 16×10이다. 8로 두면 말풍선이 가리키는 각이
    /// 뭉툭해져 어느 줄을 가리키는지가 흐려진다.
    static let arrowHeight: CGFloat = 10
    static let arrowInset: CGFloat = MMSpace.s16
}

#Preview {
    @Previewable @State var open = true
    return VStack(alignment: .trailing, spacing: MMSpace.s16) {
        MMTooltip(isPresented: $open, label: "브리핑 카드란")
        if open { MMTooltipBubble(text: "여기에 짧은 설명이 들어갑니다") }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
