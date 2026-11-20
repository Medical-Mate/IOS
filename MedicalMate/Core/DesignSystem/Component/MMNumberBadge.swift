import SwiftUI

/// 디자인 시스템 `Number Badge` (Figma `3644:7400`).
///
/// Figma 설명 그대로: 22 원 번호. **Tone = Primary(질문·단계 번호) · Subtle(빈 칸 번호).**
/// `Question Row` · `Step Row` 안에서 쓴다.
struct MMNumberBadge: View {
    enum Tone { case primary, subtle }

    let number: Int
    var tone: Tone = .primary

    var body: some View {
        Text("\(number)")
            .mmTextStyle(MMFont.labelS)
            .foregroundStyle(tone == .primary ? MMColor.fgOnPrimary : MMColor.fgSubtle)
            .frame(width: NumberBadgeMetrics.size, height: NumberBadgeMetrics.size)
            .background(tone == .primary ? MMColor.bgPrimary : MMColor.bgSubtle)
            .clipShape(Circle())
    }
}

private enum NumberBadgeMetrics {
    static let size: CGFloat = 22
}

/// 디자인 시스템 `Question Row` (Figma `3644:7446`).
///
/// Figma 설명 그대로:
/// > 증상 정리 3/3 **추천 질문 고르기 줄** 320×64(1c-D~D4). State = Default · Selected ·
/// > **Writing(직접 적는 중)** · **Add(빈 칸 "질문 직접 추가")** · **Focus(빈 칸 누름)**.
/// > 번호는 안쪽 `Number Badge`에서 바꾼다.
///
/// 상태별로 테두리와 번호 톤이 갈린다 — Default는 `border/subtle`, 고르거나 적는 중이면
/// `border/primary`, 빈 칸은 `border/default`에 번호가 Subtle이다.
struct MMQuestionRow: View {
    enum State { case `default`, selected, writing, add, focus }

    let number: Int
    let text: String
    var state: State = .default
    var action: (() -> Void)?

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: MMSpace.s10) {
                MMNumberBadge(number: number, tone: state.badgeTone)

                Text(text)
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(state.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                if state.showsCheckbox {
                    checkbox
                }
            }
            .padding(.leading, MMSpace.s16)
            .padding(.trailing, MMSpace.s14)
            .padding(.vertical, MMSpace.s12)
            .frame(height: QuestionRowMetrics.height)
            .frame(maxWidth: .infinity)
            .background(MMColor.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .strokeBorder(state.borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(state == .selected ? [.isSelected] : [])
    }

    private var checkbox: some View {
        RoundedRectangle(cornerRadius: MMRadius.xs)
            .fill(state == .selected ? MMColor.bgPrimary : MMColor.bgSurface)
            .overlay {
                if state == .selected {
                    MMIcon.check.view(size: 16).foregroundStyle(MMColor.fgOnPrimary)
                } else {
                    RoundedRectangle(cornerRadius: MMRadius.xs)
                        .strokeBorder(MMColor.borderStrong, lineWidth: 1.5)
                }
            }
            .frame(width: MMSize.iconLg, height: MMSize.iconLg)
    }
}

private enum QuestionRowMetrics {
    static let height: CGFloat = 64
}

private extension MMQuestionRow.State {
    var badgeTone: MMNumberBadge.Tone {
        switch self {
        case .add, .focus: .subtle
        case .default, .selected, .writing: .primary
        }
    }

    var borderColor: Color {
        switch self {
        case .default: MMColor.borderSubtle
        case .selected, .writing, .focus: MMColor.borderPrimary
        case .add: MMColor.borderDefault
        }
    }

    var textColor: Color {
        switch self {
        case .writing: MMColor.fgPrimary
        case .add: MMColor.fgMuted
        case .default, .selected, .focus: MMColor.fgDefault
        }
    }

    var showsCheckbox: Bool {
        switch self {
        case .default, .selected, .writing: true
        case .add, .focus: false
        }
    }
}

#Preview {
    VStack(spacing: MMSpace.s8) {
        MMQuestionRow(number: 1, text: "검사를 받아야 하나요?", state: .default, action: {})
        MMQuestionRow(number: 2, text: "검사를 받아야 하나요?", state: .selected, action: {})
        MMQuestionRow(number: 3, text: "작성 중…", state: .writing, action: {})
        MMQuestionRow(number: 4, text: "질문 직접 추가", state: .add, action: {})
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
