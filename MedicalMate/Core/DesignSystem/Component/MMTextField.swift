import SwiftUI

/// 디자인 시스템 `Text Field` (Figma `295:692`).
///
/// Figma 설명 그대로:
/// > 한 줄 입력. 높이 56 · 값은 `Body/L`(17). **Default는 테두리 없이 `bg/subtle` 면이다**
/// > — 빈 필드에 테두리를 두르면 화면이 상자로 가득 차고, 면만으로도 "여기 적는다"가
/// > 전달된다. 값이 들어오거나 포커스되면 흰 면 + 테두리로 올라온다. **Error는 테두리만
/// > 빨갛게 하지 않고 면까지 `bg/danger`로 바꾼다.** 스크롤 중에도 어느 필드가 틀렸는지
/// > 보여야 한다. **Description은 오류 시 실패 사유로 교체된다** — 무엇이 잘못됐는지가
/// > 아니라 **무엇을 하면 되는지**를 적는다.
///
/// 설명은 반경을 14로 적었는데 마스터는 16이다. 마스터를 따랐다.
///
/// Default에도 `border/strong` 1px이 있다 — 설명의 "테두리 없이"는 Disabled 기준이다.
struct MMTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    /// 아래 도움말. 오류일 때는 `errorMessage`가 이 자리를 대신한다.
    var description: String?
    var errorMessage: String?

    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var isFocused: Bool

    private var state: FieldState {
        if !isEnabled { return .disabled }
        if errorMessage != nil { return .error }
        if isFocused { return .focus }
        return text.isEmpty ? .default : .filled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpace.s6) {
            Text(label)
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            field

            if let helper {
                Text(helper)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(state.helperColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var helper: String? { errorMessage ?? description }

    private var field: some View {
        HStack(spacing: MMSpace.s12) {
            TextField(placeholder, text: $text)
                .mmTextStyle(MMFont.bodyL)
                .foregroundStyle(state.valueColor)
                .focused($isFocused)
                .textFieldStyle(.plain)

            if state.showsClear && !text.isEmpty {
                Button { text = "" } label: {
                    MMIcon.close.view()
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(width: FieldMetrics.clear, height: FieldMetrics.clear)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("지우기")
            } else {
                Color.clear.frame(width: FieldMetrics.clear, height: FieldMetrics.clear)
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
}

/// 입력 계열이 함께 쓰는 상태. Text Field · Text Area · Search Field가 같은 규칙이다.
enum FieldState {
    case `default`, focus, filled, error, disabled

    var container: Color {
        switch self {
        case .default, .disabled: MMColor.bgSubtle
        case .focus, .filled: MMColor.bgSurface
        case .error: MMColor.bgDanger
        }
    }

    var border: (color: Color, width: CGFloat)? {
        switch self {
        case .default, .filled: (MMColor.borderStrong, 1)
        case .focus: (MMColor.borderFocus, 2)
        case .error: (MMColor.fgDanger, 2)
        case .disabled: nil
        }
    }

    var valueColor: Color {
        switch self {
        case .disabled: MMColor.fgDisabled
        case .default: MMColor.fgSubtle
        case .focus, .filled, .error: MMColor.fgDefault
        }
    }

    var helperColor: Color {
        switch self {
        case .error: MMColor.fgDanger
        case .disabled: MMColor.fgDisabled
        default: MMColor.fgSubtle
        }
    }

    var showsClear: Bool {
        switch self {
        case .focus, .filled, .error: true
        case .default, .disabled: false
        }
    }
}

private enum FieldMetrics {
    static let clear: CGFloat = MMSize.controlMd
}

#Preview {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "명치 쪽이 쓰려요"
    @Previewable @State var bad = "명"

    return VStack(spacing: MMSpace.s16) {
        MMTextField(label: "어떻게 아프신가요", text: $empty, placeholder: "증상을 입력하세요", description: "짧게 적어도 괜찮아요")
        MMTextField(label: "어떻게 아프신가요", text: $filled, description: "짧게 적어도 괜찮아요")
        MMTextField(label: "어떻게 아프신가요", text: $bad, errorMessage: "두 글자 이상 적어주세요")
        MMTextField(label: "어떻게 아프신가요", text: $empty, placeholder: "증상을 입력하세요", description: "지금은 입력할 수 없어요")
            .disabled(true)
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
