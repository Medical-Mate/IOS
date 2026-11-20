import Foundation

/// 홈을 읽는 자리.
///
/// 날짜·시각 꾸미기를 여기서 한다. 화면은 이미 꾸며진 글을 받아 그리기만 한다 —
/// 같은 규칙을 화면마다 다시 쓰면 갈린다.
struct HomeRepository: Sendable {
    let client: ApiClient
    var calendar: Calendar = .current
    var today: @Sendable () -> Date = { Date() }

    func summary() async -> ApiResult<HomeSummary> {
        await client.send(.get("api/me/home"), as: HomeResponse.self).map(summary(from:))
    }

    func summary(from response: HomeResponse) -> HomeSummary {
        HomeSummary(
            recentCards: (response.recentCards ?? []).map(card(from:)),
            upcoming: response.upcomingAppointment.map(schedule(from:)),
            openIntake: response.openIntake.map {
                HomeOpenIntake(
                    sessionId: $0.sessionId,
                    step: $0.progressCurrent ?? 0,
                    total: $0.progressTotal ?? 3
                )
            }
        )
    }

    private func card(from card: HomeResponse.Card) -> HomeCard {
        // 서버가 title을 아직 안 주면 환자가 말한 원문을 쓴다. 길 수 있어 줄인다 —
        // 한 줄짜리라 넘치면 잘리기만 하고 무엇인지 알 수 없게 된다.
        let title = (card.title ?? card.chiefComplaint).map(Self.shorten) ?? ""
        return HomeCard(
            id: String(card.cardId),
            title: title,
            meta: [Self.day(from: card.createdAt), card.clinicName]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
                .joined(separator: " · "),
            visited: card.visited ?? false
        )
    }

    private func schedule(from appointment: HomeResponse.Appointment) -> HomeSchedule {
        let date = appointment.date.flatMap(Self.date(from:))
        // 제목은 서버가 주지 않는다. 병원 · 진료과 · 목적을 앱이 조합한다.
        let title = [appointment.department, appointment.purpose]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " ")

        return HomeSchedule(
            id: appointment.appointmentId,
            month: date.map { "\(calendar.component(.month, from: $0))월" } ?? "",
            day: date.map { String(calendar.component(.day, from: $0)) } ?? "",
            meta: [appointment.clinicName, weekdayAndTime(date: date, time: appointment.time)]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
                .joined(separator: " · "),
            title: title.isEmpty ? (appointment.clinicName ?? "") : title,
            dday: date.map(dday(for:))
        )
    }

    /// "금 오전 10:30". 시각이 없으면 요일만 — 시간 미정인 일정이 있다.
    private func weekdayAndTime(date: Date?, time: String?) -> String? {
        guard let date else { return nil }
        let weekday = Self.weekdays[calendar.component(.weekday, from: date) - 1]
        guard let time, let parsed = Self.time(from: time) else { return weekday }
        return "\(weekday) \(parsed)"
    }

    /// "D-7" · "D-DAY" · 지난 것은 "D+3".
    func dday(for date: Date) -> String {
        let start = calendar.startOfDay(for: today())
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        if days == 0 { return "D-DAY" }
        return days > 0 ? "D-\(days)" : "D+\(-days)"
    }

    // MARK: - 글 꾸미기

    static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    static func date(from text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(text.prefix(10)))
    }

    /// "2026.09.04".
    static func day(from text: String?) -> String? {
        guard let text, let date = date(from: text) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    /// "오전 10:30".
    static func time(from text: String) -> String? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: String(text.prefix(5))) else { return nil }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ko_KR")
        out.dateFormat = "a h:mm"
        return out.string(from: date)
    }

    /// 목록 제목의 길이 상한. 넘으면 말줄임을 붙인다.
    static func shorten(_ text: String) -> String {
        text.count <= titleMax ? text : String(text.prefix(titleMax)).trimmingCharacters(in: .whitespaces) + "…"
    }

    static let titleMax = 24
}
