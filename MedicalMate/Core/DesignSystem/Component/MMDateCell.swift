import SwiftUI

/// 디자인 시스템 `Date Cell` (Figma `335:1188`).
///
/// Figma 설명 그대로:
/// > 캘린더 한 칸. **아래 5px 점은 그날 기록이 있다는 표시다. 숫자와 분리해 두면
/// > "선택됨"과 "기록 있음"이 겹치지 않는다.** **Today는 채우기가 아니라 옅은 면이다**
/// > — 오늘은 상태이지 선택이 아니다.
///
/// 설명은 46×46으로 적었는데 마스터는 42×42다. 마스터를 따랐다. 터치 영역은 부모
/// 격자에서 확보한다.
///
/// 캘린더 월 격자는 2026-10-15 추가분의 ``MMCalendarDay``를 쓴다. 이 컴포넌트는 그 전
/// 디자인 시스템 판이고 일자 선택이 들어가는 다른 자리에서 쓴다.
struct MMDateCell: View {
    enum State { case `default`, today, selected, disabled }

    let day: Int
    var state: State = .default
    /// 그날 기록이 있는지.
    var hasRecord: Bool = true
    var action: (() -> Void)?

    var body: some View {
        Button { action?() } label: {
            VStack(spacing: DateCellMetrics.gap) {
                // 숫자가 설 자리는 글자 배율과 상관없이 고정이다 — ``MMCalendarDay``와
                // 같은 까닭이다. 따르면 아래 점이 면 밖으로 밀려 잘린다.
                Text("\(day)")
                    .mmTextStyle(MMFont.bodyMStrong)
                    .foregroundStyle(state.textColor)
                    .fixedSize()
                    .frame(height: DateCellMetrics.numberHeight)
                if hasRecord && state != .disabled {
                    Circle()
                        .fill(state == .selected ? MMColor.fgOnPrimary : MMColor.bgPrimary)
                        .frame(width: DateCellMetrics.dot, height: DateCellMetrics.dot)
                }
            }
            .frame(width: DateCellMetrics.size, height: DateCellMetrics.size)
            .background(state.container)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.dateCell))
            .overlay {
                if state == .today {
                    RoundedRectangle(cornerRadius: MMRadius.dateCell)
                        .strokeBorder(MMColor.borderPrimary, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled || action == nil)
        .accessibilityLabel("\(day)일\(hasRecord ? ", 기록 있음" : "")")
        .accessibilityAddTraits(state == .selected ? [.isSelected] : [])
    }
}

private enum DateCellMetrics {
    static let size: CGFloat = 42
    static let gap: CGFloat = 3
    static let dot: CGFloat = 5
    static let numberHeight: CGFloat = 24
}

private extension MMDateCell.State {
    var container: Color {
        switch self {
        case .selected: MMColor.bgPrimary
        case .today: MMColor.bgPrimaryFaint
        case .default, .disabled: .clear
        }
    }

    var textColor: Color {
        switch self {
        case .selected: MMColor.fgOnPrimary
        case .disabled: MMColor.fgDisabled
        case .default, .today: MMColor.fgDefault
        }
    }
}

#Preview {
    HStack(spacing: MMSpace.s8) {
        MMDateCell(day: 14, state: .default, action: {})
        MMDateCell(day: 14, state: .today, action: {})
        MMDateCell(day: 14, state: .selected, action: {})
        MMDateCell(day: 14, state: .disabled, hasRecord: false)
        MMDateCell(day: 14, state: .default, hasRecord: false, action: {})
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgSurface)
}
