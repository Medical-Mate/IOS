import SwiftUI

/// 디자인 시스템 `Search Field` (Figma `590:1307`).
///
/// 규격은 ``MMTextField``와 같다 — 높이 56 · 반경 16 · `Body/L`. 앞에 검색 아이콘이
/// 서고 라벨과 도움말이 없다. 1m 병원 찾기와 인체도 부위 목록이 쓴다.
///
/// 마스터는 Empty에도 `bg/subtle` + `border/strong` 1px이다. 값이 들어오면 지우기가 선다.
struct MMSearchField: View {
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        HStack(spacing: MMSpace.s12) {
            MMIcon.search.view()
                .foregroundStyle(MMColor.fgDefault)

            // 플레이스홀더는 직접 그린다 — 마스터의 색이 시스템 기본보다 진하다.
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .mmTextStyle(MMFont.bodyL)
                        .foregroundStyle(MMColor.fgSubtle)
                        .allowsHitTesting(false)
                }
                TextField("", text: $text)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(MMColor.fgDefault)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
            }

            if text.isEmpty {
                Color.clear.frame(width: MMSize.controlMd, height: MMSize.controlMd)
            } else {
                Button { text = "" } label: {
                    MMIcon.close.view()
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(width: MMSize.controlMd, height: MMSize.controlMd)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("지우기")
            }
        }
        .padding(.leading, MMSpace.s20)
        .padding(.trailing, MMSpace.s4)
        .padding(.vertical, MMSpace.s4)
        .frame(height: MMSize.controlLg)
        .background(MMColor.bgSubtle)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: MMRadius.md)
                .strokeBorder(MMColor.borderStrong, lineWidth: 1)
        }
    }
}

/// 디자인 시스템 `Toggle` (Figma `334:1155`).
///
/// Figma 설명 그대로:
/// > **즉시 적용되는 켜기·끄기. 확인이 필요한 설정에는 쓰지 않는다** — 토글은 누르는
/// > 순간 반영되는 것이다. **Off 트랙은 `border/strong`(3.78:1)이다.** 더 옅은 회색을
/// > 쓰면 흰 노브의 경계가 사라져 비텍스트 3:1을 통과하지 못한다. **라벨은 컴포넌트
/// > 밖에 두고 행 전체를 터치 영역으로 잡는다.**
///
/// 52×32, 노브 지름 26. 마스터 내보내기에서 확인한 값이다.
struct MMToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? MMColor.bgPrimary : MMColor.borderStrong)
            .frame(width: ToggleMetrics.width, height: ToggleMetrics.height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(MMColor.bgSurface)
                    .frame(width: ToggleMetrics.knob, height: ToggleMetrics.knob)
                    .padding(.horizontal, ToggleMetrics.inset)
            }
            .animation(.snappy(duration: 0.2), value: isOn)
            .onTapGesture { isOn.toggle() }
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isOn ? "켜짐" : "꺼짐")
    }
}

private enum ToggleMetrics {
    static let width: CGFloat = 52
    static let height: CGFloat = 32
    static let knob: CGFloat = 26
    static let inset: CGFloat = 3
}

#Preview {
    @Previewable @State var query = ""
    @Previewable @State var filled = "서울OO병원"
    @Previewable @State var on = true
    @Previewable @State var off = false

    return VStack(spacing: MMSpace.s16) {
        MMSearchField(text: $query, placeholder: "병원 이름을 적어주세요")
        MMSearchField(text: $filled)
        HStack(spacing: MMSpace.s16) {
            MMToggle(isOn: $off)
            MMToggle(isOn: $on)
        }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
