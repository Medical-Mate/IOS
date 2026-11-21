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
            // **시안의 최근 브리핑 카드가 두 장이다.** 서버는 세 장을 준다.
            recentCards: (response.recentCards ?? []).prefix(Self.recentCards).map(card(from:)),
            upcoming: response.nextAppointment.map(schedule(from:)),
            openIntake: response.inProgressSession.map {
                HomeOpenIntake(
                    sessionId: $0.sessionId,
                    step: $0.progressCurrent ?? 0,
                    total: $0.progressTotal ?? 3
                )
            },
            lead: leadInput(from: response)
        )
    }

    /// 시안 `1n-1`의 최근 브리핑 카드 장 수.
    static let recentCards = 2

    /// 배너를 가르는 재료만 추린다.
    func leadInput(from response: HomeResponse) -> HomeLeadInput {
        let next = response.nextAppointment
        let card = next?.cards?.first
        return HomeLeadInput(
            lastVisitedOn: response.lastVisitedOn.flatMap(Self.date(from:)),
            nextOn: next.flatMap { Self.date(from: $0.scheduledOn) },
            nextTime: next?.scheduledTime.flatMap { Self.time(from: $0) },
            nextClinicLabel: next.flatMap(Self.clinicLabel),
            nextClinicName: next?.clinicName.flatMap { $0.isEmpty ? nil : $0 },
            nextCard: card.map { (id: $0.cardId, title: $0.title ?? "") }
        )
    }

    /// "서울OO병원 내과". 비면 `nil`이다.
    static func clinicLabel(_ appointment: HomeResponse.Appointment) -> String? {
        let joined = [appointment.clinicName, appointment.department]
            .compactMap(\.self)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    /// 맨 위 배너를 고른다.
    ///
    /// 차례가 곧 우선순위다 — 오늘 진료 · 내일 진료 · 일정 없는 카드 · 처음 · 그 밖.
    /// **일정이 있는지는 홈 응답에 없어** 가장 최근 카드를 한 번 더 읽는다. 못 읽으면 그
    /// 갈래를 건너뛴다 — 배너 한 장 때문에 홈을 실패로 만들지 않는다.
    func lead(for summary: HomeSummary) async -> HomeLead {
        let today = calendar.startOfDay(for: today())
        if let decided = HomeRepository.timedLead(summary.lead, today: today, calendar: calendar) {
            return decided
        }
        if let ready = await cardReady(summary) { return ready }
        return summary.isEmpty ? .firstVisit : .other
    }

    /// 날짜만으로 가를 수 있는 둘. **카드가 걸린 일정만 본다** — 기록도 "카드 다시 보기"도
    /// 카드가 있어야 갈 곳이 있다.
    nonisolated static func timedLead(_ input: HomeLeadInput, today: Date, calendar: Calendar) -> HomeLead? {
        guard let on = input.nextOn, let card = input.nextCard else { return nil }
        let day = calendar.startOfDay(for: on)
        // **오늘 진료를 이미 기록했으면 오늘 배너를 띄우지 않는다.**
        let recorded = input.lastVisitedOn.map { calendar.isDate($0, inSameDayAs: today) } ?? false
        if calendar.isDate(day, inSameDayAs: today), !recorded {
            return .todayVisit(
                clinic: input.nextClinicLabel,
                cardId: card.id,
                cardTitle: card.title,
                clinicName: input.nextClinicName
            )
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
           calendar.isDate(day, inSameDayAs: tomorrow) {
            return .tomorrowVisit(time: input.nextTime, clinic: input.nextClinicLabel, cardId: card.id)
        }
        return nil
    }

    private func cardReady(_ summary: HomeSummary) async -> HomeLead? {
        guard let latest = summary.recentCards.first, !latest.visited,
              let id = Int64(latest.id),
              case .success(let probe) = await client.send(.get("api/cards/\(id)"), as: HomeCardProbe.self),
              probe.appointment == nil
        else { return nil }
        return .cardReady(cardId: id, symptom: latest.title)
    }

    private func card(from card: HomeResponse.Card) -> HomeCard {
        // 서버가 title을 아직 안 주면 환자가 말한 원문을 쓴다. 길 수 있어 줄인다 —
        // 한 줄짜리라 넘치면 잘리기만 하고 무엇인지 알 수 없게 된다.
        let title = (card.title ?? card.chiefComplaint).map(Self.shorten) ?? ""
        return HomeCard(
            id: String(card.cardId),
            title: title,
            meta: Self.cardMeta(day: Self.day(from: card.createdAt), clinic: card.clinicName),
            visited: card.visited ?? false
        )
    }

    /// 다가오는 일정의 제목. "내과 재진".
    ///
    /// **초진인지 재진인지는 `origin`이 말한다** — 진료 후 기록에서 잡힌 재방문이면
    /// 재진이다. 전에는 서버의 `purpose`를 그대로 썼는데, 그 값은 비어 올 때가 많아
    /// 제목이 "내과"로 끝나거나 통째로 비었다. Android도 `origin`으로 가른다
    /// (`HomeRepository.kt`의 `FOLLOW_UP_ORIGIN`).
    nonisolated static func scheduleTitle(department: String?, origin: AppointmentOrigin) -> String {
        let visit = origin == .visitFollowUp ? "재진" : "초진"
        guard let department, !department.isEmpty else { return visit }
        return "\(department) \(visit)"
    }

    /// 카드 줄의 둘째 줄. "2026.08.21 · 서울OO병원 내과".
    ///
    /// **병원이 없으면 빈 자리를 두지 않고 "카드만 작성됨"이라고 적는다**(`3663:7014`).
    /// 아직 병원을 안 정한 것이지 날짜만 있는 줄이 아니다. Android도 같다
    /// (`home_card_meta_draft`).
    nonisolated static func cardMeta(day: String?, clinic: String?) -> String {
        let day = day?.isEmpty == false ? day : nil
        let clinic = clinic?.isEmpty == false ? clinic : nil
        return [day, clinic ?? "카드만 작성됨"].compactMap(\.self).joined(separator: " · ")
    }

    private func schedule(from appointment: HomeResponse.Appointment) -> HomeSchedule {
        let date = Self.date(from: appointment.scheduledOn)
        let title = Self.scheduleTitle(
            department: appointment.department,
            origin: AppointmentOrigin.of(appointment.origin)
        )

        return HomeSchedule(
            id: appointment.appointmentId,
            month: date.map { "\(calendar.component(.month, from: $0))월" } ?? "",
            day: date.map { String(calendar.component(.day, from: $0)) } ?? "",
            meta: [appointment.clinicName, weekdayAndTime(date: date, time: appointment.scheduledTime)]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
                .joined(separator: " · "),
            // 제목은 비지 않는다 — 진료과가 없어도 "초진"·"재진"은 남는다.
            title: title,
            dday: date.flatMap(dday(for:))
        )
    }

    /// "금 오전 10:30". 시각이 없으면 요일만 — 시간 미정인 일정이 있다.
    private func weekdayAndTime(date: Date?, time: String?) -> String? {
        guard let date else { return nil }
        let weekday = Self.weekdays[calendar.component(.weekday, from: date) - 1]
        guard let time, let parsed = Self.time(from: time) else { return weekday }
        return "\(weekday) \(parsed)"
    }

    /// "D-7" · 당일은 **"D-day"**.
    ///
    /// **지난 것은 배지를 달지 않는다.** "D+3"은 남은 날을 세는 말이 아니라 지난 날을
    /// 세는 말이라, 앞으로 할 일을 가리키는 자리에 서면 안 된다. Android도 같다
    /// (`ddayLabel`을 `days >= 0`에서만 부른다).
    func dday(for date: Date) -> String? {
        let start = calendar.startOfDay(for: today())
        let target = calendar.startOfDay(for: date)
        return HomeRepository.dday(days: calendar.dateComponents([.day], from: start, to: target).day ?? 0)
    }

    /// 대문자 `D-DAY`가 아니라 **`D-day`**다 — 시안의 `Card / Schedule` 설명이 그렇게
    /// 적고 Android도 같다.
    nonisolated static func dday(days: Int) -> String? {
        guard days >= 0 else { return nil }
        return days == 0 ? "D-day" : "D-\(days)"
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
