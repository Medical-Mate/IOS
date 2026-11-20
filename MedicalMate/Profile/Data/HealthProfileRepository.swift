import Foundation

/// 건강 프로필을 읽고 쓰는 자리.
///
/// 경로는 Android `profile/data/HealthProfileApi`와 같다 —
/// `GET /api/me/health-profile` · `PUT /api/me/health-profile`.
struct HealthProfileRepository: Sendable {
    let client: ApiClient

    func profile() async -> ApiResult<HealthProfile> {
        await client.send(.get("api/me/health-profile"), as: HealthProfileResponse.self)
            .map(\.profile)
    }

    func save(_ profile: HealthProfile) async -> ApiResult<HealthProfile> {
        await client.send(
            .put("api/me/health-profile", body: HealthProfileRequest(profile: profile)),
            as: HealthProfileResponse.self
        )
        .map(\.profile)
    }
}
