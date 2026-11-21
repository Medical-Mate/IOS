import SwiftUI

/// Figma 그림자 한 겹.
///
/// `blur`는 **Figma의 blur 값 그대로** 적는다. SwiftUI `.shadow(radius:)`는 블러 반경의
/// 절반에 가까우므로 ``swiftUIRadius``가 환산한다. Figma 값을 손으로 반으로 나눠 적으면
/// 원본과 대조할 때 무엇이 틀렸는지 알 수 없게 된다.
struct MMShadow: Sendable, Equatable {
    let color: Color
    let blur: CGFloat
    let x: CGFloat
    let y: CGFloat

    init(hex: UInt32, opacity: Double, blur: CGFloat, x: CGFloat = 0, y: CGFloat) {
        self.color = Color(hex: hex, opacity: opacity)
        self.blur = blur
        self.x = x
        self.y = y
    }

    var swiftUIRadius: CGFloat { blur / 2 }
}

/// DESIGN.md의 고도. Figma 원본 값(2026-09-07 확인)을 그대로 옮긴 것이다.
///
/// ```text
/// Elevation/Card   #1B255A 8%  (0,  3) blur 10  +  #1B255A 5% (0, 1) blur 2
/// Elevation/Float  #1B255A 9%  (0,  4) blur 14  +  #1B255A 6% (0, 1) blur 3
/// Elevation/Sheet  #1B255A 10% (0, -4) blur 24  +  #1B255A 5% (0, 0) blur 2
/// ```
///
/// **Android는 이 값을 그대로 옮기지 못했다.** `Modifier.shadow`가 elevation dp와 shape만
/// 받아 한 겹으로 근사했고, Sheet의 위쪽(-4) 방향은 아예 재현할 수 없었다. SwiftUI는
/// `.shadow`를 겹칠 수 있고 음수 오프셋도 받으므로 **iOS는 Figma 값을 그대로 낸다.**
///
/// 겹치는 차례는 **넓은 것 먼저, 좁은 것 나중**이다.
///
/// 그림자 색은 순수 검정이 아니라 브랜드 틴트 `#1B255A`다. 이 시스템은 모든 요소에
/// 테두리를 두르지 않는다. 선은 목록 구분 · 선택 · 포커스 · 접근성 경계에만 쓰고
/// 나머지 층은 그림자로 표현한다.
enum MMElevation {
    /// Card, 선택된 행.
    static let card: [MMShadow] = [
        MMShadow(hex: 0x1B255A, opacity: 0.08, blur: 10, y: 3),
        MMShadow(hex: 0x1B255A, opacity: 0.05, blur: 2, y: 1)
    ]

    /// 하단 고정 바, Toast, 플로팅.
    static let float: [MMShadow] = [
        MMShadow(hex: 0x1B255A, opacity: 0.09, blur: 14, y: 4),
        MMShadow(hex: 0x1B255A, opacity: 0.06, blur: 3, y: 1)
    ]

    /// Bottom Sheet, Dialog, 홈의 흰 시트. **위로 떠오르는 그림자라 y가 음수다.**
    static let sheet: [MMShadow] = [
        MMShadow(hex: 0x1B255A, opacity: 0.10, blur: 24, y: -4),
        MMShadow(hex: 0x1B255A, opacity: 0.05, blur: 2, y: 0)
    ]

    /// 사진 위 흰 글자(`Shadow/On Image · Text`). 두 겹이다.
    ///
    /// Android는 `TextStyle`이 그림자를 한 겹만 받아 **글자를 두 번 겹쳐 그렸다.**
    /// iOS는 `.shadow`를 중첩할 수 있어 그럴 필요가 없다.
    static let onImageText: [MMShadow] = [
        MMShadow(hex: 0x131722, opacity: 0.40, blur: 16, y: 2),
        MMShadow(hex: 0x131722, opacity: 0.50, blur: 2, y: 1)
    ]

    /// 사진 위 흰 아이콘(`Shadow/On Image · Icon`). 한 겹이다.
    static let onImageIcon: [MMShadow] = [
        MMShadow(hex: 0x131722, opacity: 0.50, blur: 3, y: 1)
    ]

    /// `Elevation/Primary` — `bg/primary` 채움 카드 · 큰 버튼(홈의 `Card / Action`).
    ///
    /// Figma: `#3B4FC0 28% (0, 8) blur 30 spread -18`.
    ///
    /// **아직 쓰지 않는다.** SwiftUI `.shadow`에 `spread`가 없다. spread가 -18이라 그림자가
    /// 도형보다 크게 작아지는데, 그것을 빼고 그리면 번져 보인다. 이 고도를 쓰는 컴포넌트를
    /// 만들 때 축소한 도형을 뒤에 깔아 직접 그리는 방법을 검토한다.
    static let primaryUnavailable = "spread -18을 SwiftUI .shadow로 표현할 수 없다"
}

/// DESIGN.md의 Glass surface.
///
/// 콘텐츠 위에 떠 있다는 의미가 있을 때만 쓴다. 본문 Card와 Button에는 쓰지 않는다.
/// Glass에는 테두리를 추가하지 않는다. 한 화면에서 떠 있는 층은 최대 두 단계다.
///
/// **Android는 블러가 API 31부터라 Opaque 변형이 필수 경로였다.** iOS는 전 지원 버전에서
/// 블러가 동작하므로 그 분기가 필요 없다. 다만 Figma가 적은 알파 값과 시스템 재질의
/// 두께가 다르므로 컴포넌트를 만들 때 원본과 대조한다.
enum MMGlass {
    static let blurRadius: CGFloat = 24
    static let bottomCtaOpacity: Double = 0.78
    static let navBarOpacity: Double = 0.82
    static let tabBarOpacity: Double = 0.86
}

extension View {
    /// 고도 한 벌을 입힌다.
    func mmShadow(_ shadows: [MMShadow]) -> some View {
        shadows.reduce(AnyView(self)) { view, shadow in
            AnyView(view.shadow(color: shadow.color, radius: shadow.swiftUIRadius, x: shadow.x, y: shadow.y))
        }
    }
}
