import SwiftUI

/// DESIGN.md의 원시 팔레트.
///
/// **화면 코드에서 직접 쓰지 않는다.** 시맨틱 토큰(``MMColor``)을 정의하는 곳에서만
/// 참조한다(DESIGN.md의 구현 규칙). 그래서 전부 `internal`이고 파일 밖으로 나가지 않는다.
///
/// 값은 Android `core/designsystem/Palette.kt`와 같다. 양쪽 모두 Figma가 정본이다.
enum Palette {
    static let primary50 = Color(hex: 0xF2F4FE)
    static let primary100 = Color(hex: 0xE3E7FC)
    static let primary200 = Color(hex: 0xC7CFF8)
    static let primary300 = Color(hex: 0xA3AFF1)
    static let primary400 = Color(hex: 0x7484E3)
    static let primary500 = Color(hex: 0x5566D2)
    static let primary600 = Color(hex: 0x3B4FC0)
    static let primary700 = Color(hex: 0x2E3E9E)
    static let primary800 = Color(hex: 0x242F79)
    static let primary900 = Color(hex: 0x1A2154)

    static let neutral0 = Color(hex: 0xFFFFFF)
    static let neutral25 = Color(hex: 0xFAFBFD)
    static let neutral50 = Color(hex: 0xF5F6FA)
    static let neutral100 = Color(hex: 0xEDEFF5)
    static let neutral200 = Color(hex: 0xDEE1EB)
    static let neutral300 = Color(hex: 0xC6CAD8)
    static let neutral400 = Color(hex: 0x989EB1)
    static let neutral500 = Color(hex: 0x7C8397)
    static let neutral600 = Color(hex: 0x585F73)
    static let neutral700 = Color(hex: 0x3A4053)
    static let neutral900 = Color(hex: 0x131722)

    static let amber50 = Color(hex: 0xFFF4D6)
    static let amber100 = Color(hex: 0xFFE9B3)
    static let amber500 = Color(hex: 0xE0A227)
    static let amber700 = Color(hex: 0x8A5A0B)

    static let green50 = Color(hex: 0xE4F7ED)
    static let green100 = Color(hex: 0xC6F0DC)
    static let green500 = Color(hex: 0x12A05F)
    static let green700 = Color(hex: 0x0E7A4A)

    static let red50 = Color(hex: 0xFFEDEB)
    static let red100 = Color(hex: 0xFFD8D4)
    static let red500 = Color(hex: 0xE5504A)
    static let red700 = Color(hex: 0xC4302B)

    /// 통증 강도 1~5. 서열척도라 순서가 뜻을 가진다.
    static let severityBase: [Color] = [
        Color(hex: 0xFFE3A8),
        Color(hex: 0xFFC79B),
        Color(hex: 0xFFA894),
        Color(hex: 0xF58079),
        Color(hex: 0xDC5A55)
    ]

    static let severityTint: [Color] = [
        Color(hex: 0xFFF6E4),
        Color(hex: 0xFFEFE4),
        Color(hex: 0xFFE9E3),
        Color(hex: 0xFDE4E2),
        Color(hex: 0xF9DEDD)
    ]
}

extension Color {
    /// `0xRRGGBB` 정수로 색을 만든다. 디자인 토큰을 Figma 표기 그대로 적기 위한 것이다.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
