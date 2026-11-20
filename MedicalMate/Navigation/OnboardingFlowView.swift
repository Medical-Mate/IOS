import SwiftUI

/// 처음 들어온 사람이 지나는 길.
///
/// 와이어프레임 A · B 섹션 순서다 — 온보딩 4장(`V2-00`~`V2-03`) → 신상정보 3단계
/// (`1b-1`~`1b-3`) → 완료(`1b-4`) → 홈.
///
/// 온보딩의 "건너뛰기"는 소개만 건너뛰고 신상정보로 간다. 신상정보는 건너뛸 수 없다 —
/// 복용약 · 기저질환 · 알러지가 브리핑 카드 맨 위에 늘 실리는 값이다.
struct OnboardingFlowView: View {
    private enum Step { case intro, profile }

    @State private var step: Step = .intro

    var body: some View {
        switch step {
        case .intro:
            OnboardingIntroView { step = .profile }
        case .profile:
            ProfileSetupView()
        }
    }
}
