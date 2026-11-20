import SwiftUI

/// 디자인 시스템 아이콘.
///
/// **에셋 이름을 화면에서 문자열로 쓰지 않는다.** Figma에서 내보낸 PDF를 에셋 카탈로그에
/// 넣고 여기서만 가리킨다. 이름이 바뀌면 고칠 자리가 하나다.
///
/// Figma 규격: 24×24 격자 · 라이브 20 · 획 1.75 · 라운드 캡/조인. 획 색이 `fg/default`에
/// 묶여 있어 **템플릿으로 넣고 색은 쓰는 쪽이 정한다.**
///
/// 아직 `check` 하나만 들어왔다. 나머지 45종은 쓰는 화면을 만들 때 같은 방법으로 더한다.
enum MMIcon: String {
    case check = "icon-check"

    var image: Image { Image(rawValue).renderingMode(.template) }
}

extension MMIcon {
    /// 아이콘을 주어진 크기로 그린다. 기본값은 `MMSize.iconLg`(24)다.
    @MainActor
    func view(size: CGFloat = MMSize.iconLg) -> some View {
        image.resizable().frame(width: size, height: size)
    }
}
