import Foundation

/// `GET /api/me/settings` 응답. **진료 알림 설정만 있다.**
struct SettingsResponse: Decodable, Sendable {
    var visitReminderEnabled = true
    var recordReminderEnabled = true
    var visitReminderTime: String?
    var recordReminderTime: String?

    var settings: ReminderSettings {
        ReminderSettings(
            beforeVisit: visitReminderEnabled,
            afterVisit: recordReminderEnabled,
            beforeVisitTime: ReminderTime.parse(visitReminderTime),
            afterVisitTime: ReminderTime.parse(recordReminderTime)
        )
    }
}

/// `PATCH /api/me/settings` 본문. **보낸 필드만 바뀐다.**
struct SettingsRequest: Encodable, Sendable {
    var visitReminderEnabled: Bool?
    var recordReminderEnabled: Bool?
    var visitReminderTime: String?
    var recordReminderTime: String?
}
