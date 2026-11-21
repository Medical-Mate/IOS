import Foundation

/// 계정 설정을 읽고 쓰는 자리. 경로는 Android `profile/data/SettingsApi`와 같다.
struct SettingsRepository: Sendable {
    let client: ApiClient

    func reminders() async -> ApiResult<ReminderSettings> {
        await client.send(.get("api/me/settings"), as: SettingsResponse.self).map(\.settings)
    }

    /// **바꿀 것만 보낸다.** `untimedTime`은 전날·당일 두 시각에 함께 걸린다 —
    /// 알림 시간 화면(1s-3)의 휠이 하나라서다.
    func update(
        beforeVisit: Bool? = nil,
        afterVisit: Bool? = nil,
        untimedTime: ReminderTime? = nil
    ) async -> ApiResult<ReminderSettings> {
        let time = untimedTime?.wire
        let body = SettingsRequest(
            visitReminderEnabled: beforeVisit,
            recordReminderEnabled: afterVisit,
            visitReminderTime: time,
            recordReminderTime: time
        )
        return await client.send(.patch("api/me/settings", body: body), as: SettingsResponse.self)
            .map(\.settings)
    }
}
