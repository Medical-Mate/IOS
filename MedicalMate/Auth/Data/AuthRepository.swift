import Foundation

/// 로그인 한 번의 결과.
enum LoginOutcome: Sendable, Equatable {
    /// 서버 토큰까지 받았다. `onboardingRequired`는 서버가 말한 값이다.
    case loggedIn(onboardingRequired: Bool)
    case cancelled
    case failed(LoginFailure, message: String?)
}

/// 로그인이 어디서 막혔는지. **할 일이 갈래마다 다르다.**
enum LoginFailure: Sendable, Equatable {
    /// 카카오 단계. 다시 눌러 보는 것이 할 일이다.
    case kakao
    /// 닿지 못했다. 연결을 보라고 한다.
    case network
    /// 서버가 거절했다. 잠시 뒤 다시 한다.
    case server

    /// 서버가 준 코드로 가른다.
    ///
    /// **서버가 상위 서비스(카카오 · AI)에 닿지 못한 것은 연결 갈래로 묶는다** — 앱
    /// 잘못이 아니고 사용자가 할 일이 "잠시 뒤 다시"라서 서버 거절과 다른 말을 해야 한다.
    static func of(_ error: ApiError) -> LoginFailure {
        switch error.code {
        case "UPSTREAM_ERROR", "UPSTREAM_TIMEOUT": .network
        default: .server
        }
    }

    /// 갈래마다 다른 안내.
    var message: String {
        switch self {
        case .kakao: "카카오 로그인에 실패했어요. 다시 시도해주세요"
        case .network: "인터넷 연결을 확인해주세요"
        case .server: "로그인에 실패했어요. 잠시 후 다시 시도해주세요"
        }
    }
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
            return .failed(.kakao, message: message)
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
            return .failed(LoginFailure.of(error), message: error.message)
        case .networkUnavailable:
            return .failed(.network, message: nil)
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
