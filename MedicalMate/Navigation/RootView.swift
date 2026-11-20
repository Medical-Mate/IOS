import SwiftUI

/// 세션 상태에 따라 무엇을 보일지 정하는 자리.
///
/// **스택을 로그인용과 본문용으로 쪼개지 않는다.** 아래 `MainTabView` 안의
/// `NavigationStack`이 유일한 스택이고, 로그인 경계는 이 `switch`가 넘는다. 스택 자체를
/// 갈아치우면 화면 상태가 정리되지 않고 쌓인다.
struct RootView: View {
    @Environment(SessionModel.self) private var session

    var body: some View {
        Group {
            switch session.state {
            case .checking:
                SplashView()
            case .loggedOut:
                LoginView()
            case .needsOnboarding:
                // ONB-00~03. M1에서 붙인다.
                PlaceholderView(title: "온보딩", note: "M1에서 Figma `ONB-00`~`ONB-03`을 그린다")
            case .ready:
                MainTabView()
            }
        }
        .task { await session.restore() }
    }
}

/// 1a-1 스플래시.
///
/// 세션을 확인하는 동안만 보인다. **로고와 배경만 있고 그 밖의 것을 그리지 않는다** —
/// Figma 마스터를 아직 대조하지 않았다.
struct SplashView: View {
    var body: some View {
        ZStack {
            MMColor.bgSurface.ignoresSafeArea()
            ProgressView()
        }
    }
}

/// 아직 그리지 않은 화면 자리.
///
/// **디자인이 아니다.** Figma 마스터를 열어 해당 화면을 그릴 때 통째로 지운다. 임의로
/// 만든 모양이 진짜 화면으로 굳지 않게 하려고 한눈에 알아볼 수 있게 둔다.
struct PlaceholderView: View {
    let title: String
    let note: String

    var body: some View {
        VStack(spacing: MMSpace.s12) {
            Text(title).mmTextStyle(MMFont.headingM)
            Text(note)
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgMuted)
                .multilineTextAlignment(.center)
        }
        .padding(MMSpace.s20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MMColor.bgCanvas)
    }
}
