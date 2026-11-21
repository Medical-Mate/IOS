import SwiftUI

/// 디자인 시스템 `Text Area` (Figma `334:1102`).
///
/// Figma 설명 그대로:
/// > 자유 서술. **최소 높이 120에서 내용에 따라 늘어난다.** 본문 `Body/L`(17).
/// > **15가 아니라 17인 이유: 환자가 진료실에서 직접 읽고 말할 문장이라 판독성이
/// > 우선이다.** Empty는 `bg/subtle` 면 — 빈 상태에 테두리를 두르면 화면이 상자로
/// > 가득 찬다. **플레이스홀더에 `fg/muted`를 쓰지 않는다.** 이 화면에서 플레이스홀더는
/// > 무엇을 적어야 하는지 알려주는 유일한 안내라 장식이 아니다. **카운터는 상한 경고가
/// > 아니라 여유를 알리는 용도다.**
struct MMTextArea: View {
    @Binding var text: String
    var placeholder: String = ""
    var limit: Int = 300
    /// 마이크. 받아쓰기가 불가능한 기기에서는 그리지 않는다.
    var onMic: (() -> Void)?

    @FocusState private var isFocused: Bool

    private var state: FieldState {
        if isFocused { return .focus }
        return text.isEmpty ? .default : .filled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpace.s10) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .mmTextStyle(MMFont.bodyL)
                        .foregroundStyle(MMColor.fgSubtle)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(MMColor.fgDefault)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            footer
        }
        .padding(.horizontal, MMSpace.s16)
        .padding(.vertical, MMSpace.s14)
        .frame(minHeight: TextAreaMetrics.minHeight, alignment: .top)
        .background(state.container)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
        .overlay {
            if let border = state.border {
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .strokeBorder(border.color, lineWidth: border.width)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: MMSpace.s8) {
            Text("\(text.count) / \(limit)")
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let onMic {
                Button(action: onMic) {
                    MMIcon.mic.view()
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(width: MMSize.controlMd, height: MMSize.controlMd)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("말로 적기")
            }
        }
        // **세던 수를 실제로 지킨다.** 전에는 "412 / 300"처럼 넘긴 수를 적기만 하고
        // 그대로 받았다. 세어 보이는 자리가 막지 않으면 세는 뜻이 없다.
        .onChange(of: text) { _, new in
            let clamped = MMTextArea.clamped(new, limit: limit)
            if clamped != new { text = clamped }
        }
    }

    /// 상한까지만 남긴다.
    nonisolated static func clamped(_ text: String, limit: Int) -> String {
        text.count <= limit ? text : String(text.prefix(limit))
    }
}

private enum TextAreaMetrics {
    static let minHeight: CGFloat = 120
}

#Preview {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "지난번에 받은 약을 먹고 속이 쓰렸어요. 바꿀 수 있는지 묻고 싶어요."

    return VStack(spacing: MMSpace.s16) {
        MMTextArea(text: $empty, placeholder: "진료실에서 꼭 묻고 싶은 것을 적어두세요")
        MMTextArea(text: $filled, onMic: {})
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
