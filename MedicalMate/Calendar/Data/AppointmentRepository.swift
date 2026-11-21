import Foundation

/// 캘린더 일정.
///
/// **날짜 경계는 서버가 한국 시각으로 자른다** — UTC로 자르면 오전 9시 이전 일정이
/// 전날로 밀린다. **D-day는 앱이 센다**: 서버가 계산하면 사용자 시간대와 어긋날 때
/// 하루 틀린다.
struct AppointmentRepository: Sendable {
    let client: ApiClient

    /// `date`를 주면 그 하루, `year`·`month`를 주면 그 달이다.
    func appointments(year: Int? = nil, month: Int? = nil, date: String? = nil) async
    -> ApiResult<[AppointmentResponse]> {
        var query: [String: String] = [:]
        if let year { query["year"] = String(year) }
        if let month { query["month"] = String(month) }
        if let date { query["date"] = date }
        return await client.send(.get("api/me/appointments", query: query), as: [AppointmentResponse].self)
    }

    /// 아직 안 지났고 취소되지 않은 것만 가까운 순으로 온다.
    func upcoming() async -> ApiResult<[AppointmentResponse]> {
        await client.send(.get("api/me/appointments/upcoming"), as: [AppointmentResponse].self)
    }

    /// **카드 연결은 선택이다.** 카드 없이 "다음 주 치과"만 적을 수 있다.
    func create(_ request: CreateAppointmentRequest) async -> ApiResult<AppointmentResponse> {
        await client.send(.post("api/me/appointments", body: request), as: AppointmentResponse.self)
    }

    func update(id: Int64, _ request: UpdateAppointmentRequest) async -> ApiResult<AppointmentResponse> {
        await client.send(.patch("api/me/appointments/\(id)", body: request), as: AppointmentResponse.self)
    }

    func delete(id: Int64) async -> ApiResult<Void> {
        await client.send(.delete("api/me/appointments/\(id)"))
    }
}
