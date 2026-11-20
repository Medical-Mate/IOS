import SwiftUI

/// `Card` 마스터의 고정 수치. 제네릭 타입 안에 정적 저장 프로퍼티를 둘 수 없어 밖에 있다.
private enum CardMetrics {
    static let padding: CGFloat = MMSpace.s20
    static let gap: CGFloat = MMSpace.s6
}

/// 카드의 강조. 제네릭 바깥에 두어 쓰는 쪽이 `MMCardEmphasis.brand`로 가리킨다.
enum MMCardEmphasis: Hashable {
    case `default`, brand, quiet
}

/// 디자인 시스템 `Card` (Figma `293:656`).
///
/// Figma 설명 그대로:
/// > 350 · 반경 20 · 패딩 20. **테두리를 없애고 그림자로 띄운다** — 카드·필드·알림이 모두
/// > 1px 테두리를 쓰면 화면이 선으로 가득 찬다. `Default`=흰 면 + `Elevation/Card` ·
/// > `Brand`=brand-faint(환자의 것) · `Quiet`=bg/subtle(보조 정보, **그림자 없음**).
/// > 그림자는 브랜드 틴트다. 흰 화면 위의 검정 그림자는 회색 때처럼 보인다.
///
/// 폭 350은 Figma 캔버스(390) 기준이다. 화면은 fill-width라 폭을 고정하지 않고 거터가
/// 정하게 둔다.
struct MMCard<Content: View>: View {
    var emphasis: MMCardEmphasis = .default
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: CardMetrics.gap) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CardMetrics.padding)
        .background(emphasis.container)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .mmShadow(emphasis == .default ? MMElevation.card : [])
    }
}

private extension MMCardEmphasis {
    var container: Color {
        switch self {
        case .default: MMColor.bgSurface
        case .brand: MMColor.bgPrimaryFaint
        case .quiet: MMColor.bgSubtle
        }
    }
}

#Preview {
    VStack(spacing: MMSpace.s16) {
        ForEach([MMCardEmphasis.default, .brand, .quiet], id: \.self) { emphasis in
            MMCard(emphasis: emphasis) {
                Text("진료 전 정리")
                    .mmTextStyle(MMFont.labelS)
                    .foregroundStyle(MMColor.fgSubtle)
                Text("복부 통증 · 3주")
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)
                Text("3주 전 시작 · 최근 악화. 식후 30분 뒤 심해짐.")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
            }
        }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
