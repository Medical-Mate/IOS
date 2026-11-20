import Foundation

/// 인증 API 호출.
///
/// 경로는 Android `auth/data/AuthApi`와 같다.
struct AuthRemote: Sendable {
    let client: ApiClient

    func loginWithKakao(accessToken: String) async -> ApiResult<TokenResponse> {
        await client.send(
            .post("api/auth/kakao", body: KakaoLoginRequest(accessToken: accessToken)),
            as: TokenResponse.self
        )
    }

    func logout() async -> ApiResult<Void> {
        await client.send(.post("api/auth/logout"))
    }

    func withdraw() async -> ApiResult<Void> {
        await client.send(.delete("api/me"))
    }
}

/// 토큰 재발급.
///
/// **인증을 붙이지 않는 요청으로 나간다**(`authFree`). 만료된 access 토큰을 달고 나가면
/// 그 401이 다시 재발급을 불러 끝나지 않는다.
///
/// ``ApiClient``를 쓰면서도 순환이 생기지 않는 이유는 `authFree` 요청이 재발급 분기를
/// 타지 않기 때문이다. Android는 같은 문제를 `@AuthFree` 클라이언트를 따로 만들어 풀었다.
struct ServerTokenRefresher: TokenRefreshing {
    /// `ApiClient`가 자기 자신을 만들 때 이 값을 넣어야 해서 나중에 꽂는다.
    let client: @Sendable () -> ApiClient?

    func refresh(using refreshToken: String) async -> TokenPair? {
        guard let client = client() else { return nil }

        var request = HTTPRequest.post("api/auth/refresh", body: RefreshRequest(refreshToken: refreshToken))
        request.authFree = true

        let result = await client.send(request, as: TokenResponse.self)
        guard case .success(let token) = result else { return nil }
        return TokenPair(access: token.accessToken, refresh: token.refreshToken)
    }
}
