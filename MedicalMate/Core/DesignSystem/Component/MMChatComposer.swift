import SwiftUI

/// 문답 아래 고정되는 입력 줄.
///
/// 디자인 시스템 `Text Field`(`295:692`)의 인스턴스다 — 라벨과 도움말을 끄고 `Actions`
/// 슬롯(`631:1294`)에 **마이크와 보내기**를 넣은 모양이다(1c-2 · 1c-3 · 1c-D2 · 1c-D3).
/// 필드 자체의 면·테두리·치수는 `Text Field`와 같은 것을 쓴다.
///
/// **받아쓰기가 불가능한 기기에서는 마이크를 그리지 않는다**(FEATURE-SPEC 2.3).
struct MMChatComposer: View {
    @Binding var text: String
    var placeholder: String = "메시지 입력"
    /// 마이크를 그릴지. 받아쓰기를 못 하는 기기에서는 끈다.
    var showsMic: Bool = true
    var onMic: () -> Void = {}
    let onSend: (String) -> Void

    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var isFocused: Bool

    private var state: FieldState {
        if !isEnabled { return .disabled }
        if isFocused { return .focus }
        return text.isEmpty ? .default : .filled
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(spacing: MMSpace.s12) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .mmTextStyle(MMFont.bodyL)
                        .foregroundStyle(MMColor.fgSubtle)
                        .allowsHitTesting(false)
                }
                TextField("", text: $text)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(state.valueColor)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .submitLabel(.send)
                    .onSubmit(send)
            }

            HStack(spacing: 0) {
                if showsMic {
                    Button(action: onMic) {
                        MMIcon.mic.view()
                            .foregroundStyle(MMColor.fgDefault)
                            .frame(width: ComposerMetrics.action, height: ComposerMetrics.action)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("말로 적기")
                }

                Button(action: send) {
                    MMIcon.arrowUp.view()
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(width: ComposerMetrics.action, height: ComposerMetrics.action)
                        .contentShape(Rectangle())
                }
                .disabled(trimmed.isEmpty)
                .accessibilityLabel("보내기")
            }
        }
        .padding(.leading, MMSpace.s20)
        .padding(.trailing, MMSpace.s4)
        .padding(.vertical, MMSpace.s4)
        .frame(height: MMSize.controlLg)
        .background(state.container)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
        .overlay {
            if let border = state.border {
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .strokeBorder(border.color, lineWidth: border.width)
            }
        }
    }

    private func send() {
        let value = trimmed
        guard !value.isEmpty else { return }
        text = ""
        onSend(value)
    }
}

enum ComposerMetrics {
    /// `Actions` 안의 한 칸. 마스터는 48이다.
    static let action: CGFloat = MMSize.controlMd
}

#Preview {
    @Previewable @State var empty = ""
    @Previewable @State var typed = "공복으로 가야 하나요?"

    return VStack(spacing: MMSpace.s16) {
        MMChatComposer(text: $empty) { _ in }
        MMChatComposer(text: $typed) { _ in }
        MMChatComposer(text: $empty, showsMic: false) { _ in }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgSurface)
}
