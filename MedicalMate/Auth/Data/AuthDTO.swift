import Foundation

/// `POST /api/auth/kakao` 요청.
struct KakaoLoginRequest: Encodable, Sendable {
    let accessToken: String
}

/// `POST /api/auth/refresh` 요청.
struct RefreshRequest: Encodable, Sendable {
    let refreshToken: String
}

/// 토큰 교환·재발급의 응답.
///
/// `onboardingRequired`는 **`refresh` 응답에서 항상 false다.** 서버가 그렇게 내려준다.
/// 온보딩을 보여줄지는 이 값 하나로 정하지 않고 프로필 저장 여부와 함께 본다.
struct TokenResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let onboardingRequired: Bool?
}
