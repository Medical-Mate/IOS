import Foundation
import Observation

/// 지금 로그인되어 있는가.
///
/// **화면이 아니라 앱 수명에 묶인다.** 세션은 특정 화면에 속한 상태가 아니다. Android도
/// `SessionViewModel`만 Activity 스코프로 둔다.
@MainActor
@Observable
final class SessionModel {
    enum State: Equatable {
        /// 저장된 토큰을 확인하는 중. 이 동안은 스플래시만 보인다.
        case checking
        case loggedOut
        case needsOnboarding
        case ready
    }

    private(set) var state: State = .checking

    private let tokens: TokenStore
    private let auth: AuthRepository

    init(tokens: TokenStore, auth: AuthRepository) {
        self.tokens = tokens
        self.auth = auth
    }

    /// 앱이 뜰 때 한 번 부른다.
    ///
    /// refresh 토큰이 있으면 로그인된 것으로 본다. access 토큰이 만료됐어도 첫 API 호출이
    /// 401을 받고 ``ApiClient``가 다시 받아온다. 여기서 미리 재발급하지 않는 이유는 앱을
    /// 열 때마다 왕복을 하나 더 하게 되기 때문이다.
    func restore() async {
        state = await tokens.hasSession ? .ready : .loggedOut
    }

    func logIn(onboardingRequired: Bool) {
        state = onboardingRequired ? .needsOnboarding : .ready
    }

    func completeOnboarding() {
        state = .ready
    }

    func logOut() async {
        await auth.logout()
        state = .loggedOut
    }

    func withdraw() async -> Bool {
        let done = await auth.withdraw()
        if done { state = .loggedOut }
        return done
    }
}
