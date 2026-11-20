import SwiftUI

/// 디자인 시스템 `Badge` (Figma `311:834`).
///
/// Figma 설명 그대로:
/// > 상태·속성 표시. 높이 26 · 반경 8 · Label/S. **반경을 pill이 아니라 8로 둔다** —
/// > pill은 Chip(누를 수 있는 것)의 형태다. 배지는 읽는 것이라 모서리를 다르게 해서
/// > 형태로 구분한다. 배지는 작으므로 유색 tint를 써도 큰 면과 혼동되지 않는다.
struct MMBadge: View {
    enum Tone { case brand, neutral, success, warning, danger }

    let text: String
    var tone: Tone = .brand

    var body: some View {
        Text(text)
            .mmTextStyle(MMFont.labelS)
            .foregroundStyle(tone.label)
            .lineLimit(1)
            .padding(.horizontal, MMSpace.s8)
            .frame(height: Metrics.height)
            .background(tone.container)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.xs))
    }

    private enum Metrics {
        static let height: CGFloat = 26
    }
}

private extension MMBadge.Tone {
    var container: Color {
        switch self {
        case .brand: MMColor.bgPrimarySubtle
        case .neutral: MMColor.bgSubtle
        case .success: MMColor.bgSuccess
        case .warning: MMColor.bgWarning
        case .danger: MMColor.bgDanger
        }
    }

    var label: Color {
        switch self {
        case .brand: MMColor.fgPrimary
        case .neutral: MMColor.fgSubtle
        case .success: MMColor.fgSuccess
        case .warning: MMColor.fgWarning
        case .danger: MMColor.fgDanger
        }
    }
}

#Preview {
    HStack(spacing: MMSpace.s8) {
        MMBadge(text: "진료 전", tone: .brand)
        MMBadge(text: "작성중", tone: .neutral)
        MMBadge(text: "완료", tone: .success)
        MMBadge(text: "임시 저장", tone: .warning)
        MMBadge(text: "응급", tone: .danger)
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
