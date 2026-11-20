import SwiftUI

/// 디자인 시스템 `Divider` (Figma `333:1088`).
///
/// Figma 설명 그대로:
/// > 1px 구분선. **목록 항목 사이에만 쓴다. 인터랙션이 있는 행과 구분선을 함께 쓰지
/// > 않는다** — 눌리는 영역의 경계가 흐려진다. 단순 나열에는 여백으로 충분하고,
/// > 정보 밀도가 높아질 때만 선을 넣는다.
struct MMDivider: View {
    var body: some View {
        Rectangle()
            .fill(MMColor.borderSubtle)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

/// 디자인 시스템 `Overlay Scrim` (Figma `335:1189`).
///
/// Figma 설명 그대로:
/// > 모달·바텀시트 뒤에 까는 딤. 불투명도 50%. **50%인 이유**: 뒤 화면의 맥락은 남기되
/// > 앞 시트의 흰 면이 확실히 떠 보이는 지점이다. 바텀시트는 메인 콘텐츠에 대한
/// > 접근성을 유지하면서 임시 정보를 주는 요소라 완전히 가리면 안 된다. **딤을 탭하면
/// > 닫힌다. 되돌릴 수 없는 선택을 시트에서 받을 때만 이 동작을 막는다.**
struct MMOverlayScrim: View {
    /// 딤을 탭했을 때. 되돌릴 수 없는 선택을 받는 시트에서는 `nil`로 둔다.
    var onTap: (() -> Void)?

    var body: some View {
        Color(hex: 0x131722, opacity: 0.5)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }
            .accessibilityHidden(onTap == nil)
    }
}
