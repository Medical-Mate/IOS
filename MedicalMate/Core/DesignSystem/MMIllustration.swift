import SwiftUI

/// 디자인 시스템 일러스트.
///
/// `Onboarding Illustration`(Figma `3610:10270`)의 네 장과 일정 추가 시트의
/// `Illustration / Share Sheet`(`3645:2450`)다. Figma에서 내보낸 PDF라 **손으로 고치지
/// 않는다.** 바뀌면 원본에서 다시 내보낸다.
///
/// 원본 크기가 장마다 달라서(326 · 342×228 · 340 · 307 · 320×160) 크기를 지정하지 않고
/// 원본 비율로 그린다. 화면이 폭을 정하면 높이가 따라온다.
enum MMIllustration: String, CaseIterable {
    case onboarding1 = "onboarding-1"
    case onboarding2 = "onboarding-2"
    case onboarding3 = "onboarding-3"
    case onboarding4 = "onboarding-4"
    /// 예약 문자 방법 안내 시트(1r-4-S).
    case shareSheet = "share-sheet"

    /// 온보딩 n번째 장(1~4).
    static func onboarding(step: Int) -> MMIllustration {
        switch min(max(step, 1), 4) {
        case 1: .onboarding1
        case 2: .onboarding2
        case 3: .onboarding3
        default: .onboarding4
        }
    }
}

extension MMIllustration {
    /// 원본 비율을 지키며 주어진 폭에 맞춘다. 높이를 정하고 싶으면 `.frame`을 바깥에 건다.
    @MainActor
    func view() -> some View {
        Image(rawValue)
            .resizable().scaledToFit()
            .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: MMSpace.s20) {
            ForEach(MMIllustration.allCases, id: \.self) { illustration in
                illustration.view().frame(height: 160)
            }
        }
        .padding(MMSize.gutter)
    }
    .background(MMColor.bgCanvas)
}
