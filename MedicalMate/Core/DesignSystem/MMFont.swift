import SwiftUI

/// DESIGN.md의 타이포그래피 16종.
///
/// 이름은 Figma 스타일 이름을 camelCase로 옮겼다. `Body/L Strong` → `bodyLStrong`.
/// `Strong`은 크기를 바꾸지 않고 같은 크기의 SemiBold로 강조한다.
///
/// **자간이 퍼센트다.** Figma가 `-2%`처럼 적고 Android도 `em`으로 옮겼다. iOS는 `.tracking`이
/// pt라서 `크기 × 퍼센트 / 100`으로 환산한다. 글자 크기가 다르면 pt 값도 달라진다.
///
/// **행간은 `.lineSpacing`이 아니다.** `lineSpacing`은 줄 사이에 더하는 여백이라
/// Figma의 line-height와 뜻이 다르다. ``MMTextStyle/lineSpacing``이 `행간 - 글자 크기`를
/// 계산해 넘긴다.
struct MMTextStyle: Sendable, Equatable {
    let weight: PretendardWeight
    let size: CGFloat
    /// Figma의 line-height(pt).
    let lineHeight: CGFloat
    /// Figma의 letter-spacing(%).
    let letterSpacingPercent: CGFloat

    var font: Font { .pretendard(weight, size: size) }
    var tracking: CGFloat { size * letterSpacingPercent / 100 }
    /// SwiftUI `.lineSpacing`에 넘길 값. 줄 사이 여백이라 글자 크기를 뺀다.
    var lineSpacing: CGFloat { max(0, lineHeight - size) }
}

enum PretendardWeight: String, Sendable {
    case regular = "Pretendard-Regular"
    case medium = "Pretendard-Medium"
    case semibold = "Pretendard-SemiBold"
    case bold = "Pretendard-Bold"
}

extension Font {
    static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

enum MMFont {
    static let displayM = MMTextStyle(weight: .bold, size: 30, lineHeight: 40, letterSpacingPercent: -2.0)
    static let headingL = MMTextStyle(weight: .bold, size: 24, lineHeight: 34, letterSpacingPercent: -2.0)
    static let headingM = MMTextStyle(weight: .semibold, size: 20, lineHeight: 28, letterSpacingPercent: -1.5)
    static let headingS = MMTextStyle(weight: .semibold, size: 17, lineHeight: 24, letterSpacingPercent: -1.0)

    static let bodyL = MMTextStyle(weight: .regular, size: 17, lineHeight: 26, letterSpacingPercent: 0)
    static let bodyLStrong = MMTextStyle(weight: .semibold, size: 17, lineHeight: 26, letterSpacingPercent: 0)
    static let bodyM = MMTextStyle(weight: .regular, size: 15, lineHeight: 24, letterSpacingPercent: 0)
    static let bodyMStrong = MMTextStyle(weight: .semibold, size: 15, lineHeight: 24, letterSpacingPercent: 0)
    static let bodyS = MMTextStyle(weight: .regular, size: 13, lineHeight: 20, letterSpacingPercent: 0)
    static let bodySStrong = MMTextStyle(weight: .semibold, size: 13, lineHeight: 20, letterSpacingPercent: 0)

    static let labelL = MMTextStyle(weight: .semibold, size: 15, lineHeight: 20, letterSpacingPercent: 0)
    static let labelM = MMTextStyle(weight: .semibold, size: 13, lineHeight: 18, letterSpacingPercent: 0)
    /// **Regular다.** Figma 스타일 정의가 `Pretendard Regular 400`이고 Badge · Card가 그
    /// 스타일을 쓴다. Android는 Medium으로 들고 있어 두 플랫폼이 갈린다 — Figma가 정본이라
    /// 여기서는 Regular로 둔다. 디자인 트랙에 Android 쪽을 올려야 한다.
    static let labelS = MMTextStyle(weight: .regular, size: 11, lineHeight: 16, letterSpacingPercent: 2.0)
    static let labelXS = MMTextStyle(weight: .bold, size: 11, lineHeight: 16, letterSpacingPercent: 0)

    static let numericL = MMTextStyle(weight: .bold, size: 24, lineHeight: 30, letterSpacingPercent: -1.5)
    static let numericM = MMTextStyle(weight: .semibold, size: 17, lineHeight: 22, letterSpacingPercent: -1.0)
}

extension View {
    /// 글자 스타일 하나를 통째로 입힌다. 글꼴 · 자간 · 행간이 따로 놀지 않게 한 자리에서 건다.
    func mmTextStyle(_ style: MMTextStyle) -> some View {
        font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}
