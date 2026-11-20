import Testing
import SwiftUI
@testable import MedicalMate

/// 화면이 Figma 와이어프레임의 내용을 그대로 들고 있는지 본다.
///
/// 배치는 눈으로 대조한다. 여기서 잡는 것은 **문구와 장 수처럼 조용히 틀어지는 것**이다.
struct ScreenSpecTests {
    @Test("온보딩은 네 장이고 마지막만 시작하기다 (3663:6862~6904)")
    func onboardingPages() {
        #expect(OnboardingPage.all.count == 4)
        #expect(OnboardingPage.all.map(\.id) == [1, 2, 3, 4])
    }

    @Test("온보딩 문구가 와이어프레임과 같다 (3663:6862~6904)")
    func onboardingCopy() {
        #expect(OnboardingPage.all[0].title == "말하기 어려웠던 증상,\n함께 준비해요.")
        #expect(OnboardingPage.all[1].title == "짚어요.")
        #expect(OnboardingPage.all[2].title == "정리해요.")
        #expect(OnboardingPage.all[3].title == "이어가요.")
        #expect(OnboardingPage.all[1].body.hasPrefix("정확한 의학 용어를 몰라도 괜찮아요."))
    }

    @Test("온보딩 일러스트는 장마다 다르다 (3610:10270)")
    func onboardingIllustrations() {
        let used = OnboardingPage.all.map(\.illustration)
        #expect(used == [.onboarding1, .onboarding2, .onboarding3, .onboarding4])
        #expect(Set(used).count == 4)
    }

    @Test("일러스트 에셋 다섯 종이 모두 있다")
    func illustrationsExist() {
        #expect(MMIllustration.allCases.count == 5)
        #expect(MMIllustration.onboarding(step: 0) == .onboarding1)
        #expect(MMIllustration.onboarding(step: 9) == .onboarding4)
    }
}
