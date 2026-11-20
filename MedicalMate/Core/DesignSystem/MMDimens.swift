import SwiftUI

/// DESIGN.md의 간격 스케일.
///
/// **임의의 pt 값을 쓰지 않는다.** 새 값이 필요하면 하드코딩하기 전에 토큰을 추가할지
/// 검토한다. 화면 폭이나 테마에 따라 달라지지 않아서 Environment가 아니라 상수다.
enum MMSpace {
    static let s2: CGFloat = 2
    static let s4: CGFloat = 4
    static let s6: CGFloat = 6
    static let s8: CGFloat = 8
    static let s10: CGFloat = 10
    static let s12: CGFloat = 12
    static let s14: CGFloat = 14
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s40: CGFloat = 40
}

/// 크기 토큰.
///
/// **최소 터치 영역이 48이다.** HIG는 44를 말하지만 Figma가 48로 그려져 있고 Android도
/// 48이다. 44로 줄이면 두 플랫폼의 조작 영역이 갈린다. 디자인 트랙 확인 전까지 48을 쓴다.
enum MMSize {
    static let touchMin: CGFloat = 48
    static let iconSm: CGFloat = 18
    static let iconMd: CGFloat = 20
    static let iconLg: CGFloat = 24
    static let controlSm: CGFloat = 40
    static let controlMd: CGFloat = 48
    static let controlLg: CGFloat = 56
    static let mic: CGFloat = 88

    /// 디자인 캔버스 폭. 화면은 fill-width라 레이아웃이 이 값에 묶이지 않는다.
    static let canvasWidth: CGFloat = 360
    static let gutter: CGFloat = 20
    static let contentWidth: CGFloat = 320
    static let safeBottom: CGFloat = 24
    static let navBarHeight: CGFloat = 56
    static let tabBarHeight: CGFloat = 79
}

/// 반경 토큰.
///
/// `buttonM`(14)과 `dateCell`(13)은 스케일 밖 값이다. DESIGN.md 3.0이 각각 `sm` 12 ·
/// `md` 16으로 통일하자고 적었으나 Figma 마스터가 아직 13 · 14다. **Figma가 정본이라
/// 그대로 둔다.** 통일안이 Figma에 반영되면 지운다.
enum MMRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 28
    static let buttonM: CGFloat = 14
    static let dateCell: CGFloat = 13
    static let sheetTop: CGFloat = 28
    /// 알약 모양. 높이의 절반보다 크면 되는 값이면 무엇이든 되지만 한 자리에 둔다.
    static let pill: CGFloat = 999
}
