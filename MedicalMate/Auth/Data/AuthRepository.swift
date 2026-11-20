import Foundation

/// 로그인 한 번의 결과.
enum LoginOutcome: Sendable, Equatable {
    /// 서버 토큰까지 받았다. `onboardingRequired`는 서버가 말한 값이다.
    case loggedIn(onboardingRequired: Bool)
    case cancelled
    case failed(message: String?)
}

/// 세션을 여닫는 자리.
///
/// 카카오 인가 → 서버 토큰 교환 → 저장까지 한 흐름으로 묶는다. 화면은 이 결과만 본다.
struct AuthRepository: Sendable {
    let remote: AuthRemote
    let kakao: any KakaoLoginClient
    let tokens: TokenStore

    func login() async -> LoginOutcome {
        switch await kakao.login() {
        case .cancelled:
            return .cancelled
        case .failed(let message):
            return .failed(message: message)
        case .success(let kakaoAccessToken):
            return await exchange(kakaoAccessToken)
        }
    }

    private func exchange(_ kakaoAccessToken: String) async -> LoginOutcome {
        switch await remote.loginWithKakao(accessToken: kakaoAccessToken) {
        case .success(let token):
            await tokens.update(access: token.accessToken, refresh: token.refreshToken)
            return .loggedIn(onboardingRequired: token.onboardingRequired ?? false)
        case .rejected(let error):
            return .failed(message: error.message)
        case .networkUnavailable:
            return .failed(message: nil)
        }
    }

    /// 로그아웃.
    ///
    /// **서버 호출이 실패해도 기기의 토큰은 지운다.** 지우지 않으면 사용자는 로그아웃을
    /// 눌렀는데 계속 로그인 상태로 남는다. 서버 세션은 TTL로 끝난다.
    func logout() async {
        _ = await remote.logout()
        await kakao.logout()
        await tokens.clear()
    }

    func withdraw() async -> Bool {
        let result = await remote.withdraw()
        guard case .success = result else { return false }
        await kakao.logout()
        await tokens.clear()
        return true
    }
}
