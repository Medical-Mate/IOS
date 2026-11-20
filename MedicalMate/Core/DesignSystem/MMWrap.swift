import SwiftUI

/// 한 줄에 흘려 배치하고 넘치면 줄을 바꾸는 배치.
///
/// Figma `Chip`(`311:823`) 설명이 **"한 줄에 여러 개를 흘려 배치하고 줄바꿈은 Wrap으로
/// 처리한다"**고 적었다. SwiftUI에 그 배치가 없어 `Layout`으로 만든다.
///
/// `LazyVGrid`로는 안 된다 — 칸 폭이 고정돼서 칩마다 다른 글자 길이를 담지 못한다.
struct MMWrap: Layout {
    var horizontalSpacing: CGFloat = MMSpace.s8
    var verticalSpacing: CGFloat = MMSpace.s8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = rows(for: subviews, in: width)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height } +
            verticalSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, in: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, in width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + horizontalSpacing + size.width

            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
