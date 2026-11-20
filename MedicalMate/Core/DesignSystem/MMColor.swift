import SwiftUI

/// DESIGN.md의 시맨틱 색 토큰.
///
/// 화면은 이것만 읽는다. ``Palette``를 직접 쓰지 않는다 — 원시 팔레트를 화면에서 쓰면
/// 디자인 시스템과 이름이 갈리고, 값이 바뀔 때 고칠 자리를 찾을 수 없다.
///
/// **다크 모드가 없다.** 디자인 시스템에 다크 값이 없어서 분기하지 않는다. 색이 하나뿐이라
/// Android처럼 테마를 타고 내려갈 이유도 없어서 `enum`의 정적 값으로 둔다.
enum MMColor {
    // 배경
    static let bgCanvas = Palette.neutral50
    static let bgSurface = Palette.neutral0
    static let bgSubtle = Palette.neutral100
    static let bgPrimary = Palette.primary500
    static let bgPrimaryPressed = Palette.primary600
    static let bgPrimarySubtle = Palette.primary100
    static let bgPrimaryFaint = Palette.primary50
    static let bgPrimaryStrong = Palette.primary800
    static let bgInfo = Palette.primary50
    static let bgSuccess = Palette.green50
    static let bgWarning = Palette.amber50
    static let bgDanger = Palette.red50
    static let bgInverse = Palette.neutral900
    static let bgInverseSoft = Palette.neutral700
    static let bgScrim = Palette.neutral900
    /// 사진 위에 얹는 반투명 면.
    static let bgOnDark = Color(hex: 0xFFFFFF, opacity: 0.2)

    // 글자·아이콘
    static let fgDefault = Palette.neutral900
    static let fgSubtle = Palette.neutral600
    static let fgMuted = Palette.neutral500
    static let fgDisabled = Palette.neutral300
    static let fgOnPrimary = Palette.neutral0
    static let fgOnInverse = Palette.neutral0
    static let fgPrimary = Palette.primary700
    static let fgLink = Palette.primary700
    static let fgInfo = Palette.primary700
    static let fgSuccess = Palette.green700
    static let fgWarning = Palette.amber700
    static let fgDanger = Palette.red700

    // 테두리
    static let borderSubtle = Palette.neutral200
    static let borderDefault = Palette.neutral300
    static let borderStrong = Palette.neutral500
    static let borderFocus = Palette.primary500
    static let borderPrimary = Palette.primary500
    static let borderOnDark = Color(hex: 0xFFFFFF, opacity: 0.32)

    // 통증 강도 1~5. 서열척도라 순서가 뜻을 가진다.
    // 원색은 칩·트랙 채움에, tint는 판독 영역의 면에 쓴다.

    /// `severity/1` ~ `severity/5`. 1~5 밖의 값은 가장 가까운 끝으로 잡는다.
    static func severity(_ level: Int) -> Color {
        Palette.severityBase[clampedIndex(level)]
    }

    /// `severity/1-tint` ~ `severity/5-tint`.
    static func severityTint(_ level: Int) -> Color {
        Palette.severityTint[clampedIndex(level)]
    }

    private static func clampedIndex(_ level: Int) -> Int {
        min(max(level, 1), 5) - 1
    }
}

/// 브랜드가 고정한 색.
///
/// **테마에서 분리한다.** 각 제공자의 디자인 가이드가 변경을 금지하므로 다크 모드나
/// 테마에 따라 바뀌면 안 된다. 그래서 ``MMColor``가 아니라 여기 있다.
enum BrandColor {
    static let kakaoContainer = Color(hex: 0xFEE500)
    static let kakaoSymbol = Color.black
    static let kakaoLabel = Color(hex: 0x191600)

    static let naverContainer = Color(hex: 0x03C75A)
    static let naverLabel = Color(hex: 0xFFFFFF)

    static let appleContainer = Color(hex: 0x000000)
    static let appleLabel = Color(hex: 0xFFFFFF)

    static let googleContainer = Color(hex: 0xFFFFFF)
    static let googleLabel = Color(hex: 0x1F1F1F)
    static let googleBorder = Color(hex: 0x747775)
}
