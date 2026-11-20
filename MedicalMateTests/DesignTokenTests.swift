import Testing
import SwiftUI
@testable import MedicalMate

/// 디자인 토큰이 Figma 값과 어긋나지 않는지 본다.
///
/// 값을 바꾸는 것 자체를 막지는 못한다. **Figma가 바뀌어 토큰을 고칠 때 이 테스트도 함께
/// 고치게 해서, 값이 조용히 흘러내리는 것을 막는 것이 목적이다.**
struct DesignTokenTests {
    @Test("자간은 퍼센트를 pt로 환산한다")
    func tracking() {
        // Figma `Display/M`: 30pt · -2%
        #expect(MMFont.displayM.tracking == 30 * -2.0 / 100)
        // 자간이 0인 스타일은 환산해도 0이다.
        #expect(MMFont.bodyL.tracking == CGFloat(0))
    }

    @Test("행간은 글자 크기를 뺀 여백으로 넘어간다")
    func lineSpacing() {
        // Figma `Body/L`: 17pt 글자에 26pt 행간
        #expect(MMFont.bodyL.lineSpacing == CGFloat(26 - 17))
    }

    @Test("행간이 글자 크기보다 작아도 음수가 되지 않는다")
    func lineSpacingNeverNegative() {
        let tight = MMTextStyle(weight: .regular, size: 20, lineHeight: 16, letterSpacingPercent: 0)
        #expect(tight.lineSpacing == CGFloat(0))
    }

    @Test("Figma blur는 SwiftUI 반경의 두 배다")
    func shadowRadius() {
        // Figma `Elevation/Card` 넓은 겹: blur 10
        #expect(MMElevation.card[0].blur == CGFloat(10))
        #expect(MMElevation.card[0].swiftUIRadius == CGFloat(5))
    }

    @Test("Sheet 그림자는 위로 뜬다")
    func sheetShadowRisesUp() {
        // Figma `Elevation/Sheet`: (0, -4). Android는 이 방향을 재현하지 못했다.
        #expect(MMElevation.sheet[0].y == CGFloat(-4))
    }

    @Test("고도는 넓은 겹이 먼저다")
    func shadowOrder() {
        for shadows in [MMElevation.card, MMElevation.float, MMElevation.sheet] {
            #expect(shadows[0].blur > shadows[1].blur)
        }
    }
}
