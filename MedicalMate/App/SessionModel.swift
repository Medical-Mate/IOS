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

    /// 화면 밖에서 세션이 끝났다. 재발급이 실패해 더 쓸 수 없는 토큰이다.
    ///
    /// **로그인 화면으로 보낸다.** 그대로 두면 환자는 앱 안에 남아 화면마다 "불러오지
    /// 못했어요"만 보고, 왜 안 되는지도 어떻게 빠져나가는지도 알 수 없다.
    ///
    /// 이미 로그인 화면이면 아무것도 하지 않는다 — 복구 중(`checking`)에 들어오는 401이
    /// 스플래시를 흔들면 안 된다.
    func sessionExpired() async {
        guard SessionModel.endsSession(from: state) else { return }
        await tokens.clear()
        state = .loggedOut
    }

    /// 지금 상태에서 로그인 화면으로 보내야 하는지.
    ///
    /// **들어와 있을 때만 보낸다.** 복구 중(`checking`)에 들어오는 401이 스플래시를
    /// 흔들면 안 되고, 이미 로그인 화면이면 할 일이 없다.
    nonisolated static func endsSession(from state: State) -> Bool {
        state == .ready || state == .needsOnboarding
    }

    func withdraw() async -> Bool {
        let done = await auth.withdraw()
        if done { state = .loggedOut }
        return done
    }
}
