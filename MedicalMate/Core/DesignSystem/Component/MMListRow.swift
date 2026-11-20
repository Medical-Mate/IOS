import SwiftUI

/// 디자인 시스템 `List Row` (Figma `335:1114`).
///
/// Figma 설명 그대로:
/// > 목록 한 줄. **카드 형태로 띄우고 구분선을 쓰지 않는다** — 인터랙션이 있는 행과
/// > 구분선을 함께 쓰면 눌리는 영역의 경계가 흐려진다. 제목 + 메타(날짜·장소) 2단.
/// > **우측 chevron은 들어갈 곳이 있을 때만 붙인다.** `Type=Plain`은 눌리지 않는 행이다.
/// > **행 사이는 8~12 간격으로 띄운다.**
struct MMListRow: View {
    let title: String
    let meta: String
    /// 제목 옆 배지. 진료 전 · 진료 완료처럼 상태를 적는다.
    var badge: (text: String, tone: MMBadge.Tone)?
    /// 한 줄 요약. 넘치면 잘린다.
    var summary: String?
    /// 요약 줄의 색. 마스터는 `fg/default`인데 1j-4는 `fg/subtle`로, 이어서 정리할
    /// 카드는 `fg/warning`으로 쓴다.
    var summaryTone: SummaryTone = .default
    /// 여러 건 고르기. 편집 모드에서만 선다.
    var selection: Binding<Bool>?
    /// 들어갈 곳이 있으면 chevron이 서고 행이 눌린다. `nil`이면 `Type=Plain`이다.
    var action: (() -> Void)?
    /// chevron 없이 행만 눌릴 때. 편집 중 고르기처럼 들어갈 곳이 없는 경우다.
    var onTap: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
        } else if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: MMSpace.s12) {
            if let selection {
                MMSelectBox(isOn: selection)
            }

            VStack(alignment: .leading, spacing: MMSpace.s4) {
                HStack(spacing: badge == nil ? 0 : MMSpace.s6) {
                    Text(title)
                        .mmTextStyle(MMFont.headingS)
                        .foregroundStyle(MMColor.fgDefault)
                        .lineLimit(1)
                    if let badge {
                        MMBadge(text: badge.text, tone: badge.tone)
                    }
                    Spacer(minLength: 0)
                }

                Text(meta)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let summary {
                    Text(summary)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(summaryTone.color)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if action != nil {
                MMIcon.chevronRight.view(size: MMSize.iconMd)
                    .foregroundStyle(MMColor.fgDefault)
            }
        }
        .padding(.leading, ListRowMetrics.leading)
        .padding(.trailing, MMSpace.s14)
        .padding(.vertical, MMSpace.s16)
        .frame(maxWidth: .infinity)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
        .overlay {
            // 고른 줄은 1.5px 테두리로 표시한다. 색은 `bg/primary-subtle`이다 —
            // `border/primary`보다 옅어서 카드가 들뜨지 않는다(1j-4-D2).
            if selection?.wrappedValue == true {
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .strokeBorder(MMColor.bgPrimarySubtle, lineWidth: 1.5)
            }
        }
        .mmShadow(MMElevation.card)
    }
}

extension MMListRow {
    enum SummaryTone {
        case `default`, subtle, warning

        var color: Color {
            switch self {
            case .default: MMColor.fgDefault
            case .subtle: MMColor.fgSubtle
            case .warning: MMColor.fgWarning
            }
        }
    }
}

/// 행 안에서 고르는 상자. `Checkbox`의 상자 부분만 떼어 쓴다(마스터가 그렇게 합성한다).
struct MMSelectBox: View {
    @Binding var isOn: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: MMRadius.xs)
            .fill(isOn ? MMColor.bgPrimary : MMColor.bgSurface)
            .overlay {
                if isOn {
                    MMIcon.check.view(size: 16).foregroundStyle(MMColor.fgOnPrimary)
                } else {
                    RoundedRectangle(cornerRadius: MMRadius.xs)
                        .strokeBorder(MMColor.borderStrong, lineWidth: 1.5)
                }
            }
            .frame(width: MMSize.iconLg, height: MMSize.iconLg)
            .onTapGesture { isOn.toggle() }
            .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

private enum ListRowMetrics {
    static let leading: CGFloat = 18
}

#Preview {
    @Previewable @State var picked = false

    return VStack(spacing: MMSpace.s12) {
        MMListRow(title: "복부 통증 · 3주", meta: "2026.09.04 · 서울OO병원 내과", action: {})
        MMListRow(title: "복부 통증 · 3주", meta: "2026.09.04 · 서울OO병원 내과", badge: ("진료 전", .brand), action: {})
        MMListRow(title: "복부 통증 · 3주", meta: "2026.09.04 · 서울OO병원 내과", summary: "진행 요약이 들어갑니다")
        MMListRow(title: "복부 통증 · 3주", meta: "2026.09.04", selection: $picked, action: {})
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
