import Foundation

/// 브리핑 카드 목록을 읽고 지우는 자리.
struct CardRepository: Sendable {
    let client: ApiClient
    var calendar: Calendar = .current
    var today: @Sendable () -> Date = { Date() }

    func cards() async -> ApiResult<[CardSummaryResponse]> {
        await client.send(.get("api/me/cards"), as: [CardSummaryResponse].self)
    }

    func delete(cardId: Int64) async -> ApiResult<Void> {
        await client.send(.delete("api/cards/\(cardId)"))
    }

    /// 아직 카드를 만들지 않은 문답을 버린다.
    func deleteIntake(sessionId: Int64) async -> ApiResult<Void> {
        await client.send(.delete("api/sessions/\(sessionId)"))
    }

    /// 카드와 열린 문답을 한 목록으로 묶고 달로 가른다.
    ///
    /// 최신이 위다. 같은 달 안에서도 최신이 위다.
    func sections(cards: [CardSummaryResponse], openIntake: OpenIntakeResponse?) -> [CardMonthSection] {
        var items = cards.map(item(from:))
        if let openIntake { items.append(item(from: openIntake)) }

        let sorted = items.sorted { $0.writtenOn > $1.writtenOn }
        var sections: [CardMonthSection] = []
        for item in sorted {
            if let index = sections.firstIndex(where: { $0.month == item.month }) {
                sections[index].items.append(item)
            } else {
                sections.append(CardMonthSection(month: item.month, items: [item]))
            }
        }
        return sections
    }

    private func item(from card: CardSummaryResponse) -> CardListItem {
        let date = card.createdAt.flatMap(HomeRepository.date(from:)) ?? today()
        let clinic = card.clinicName.flatMap { $0.isEmpty ? nil : $0 } ?? "병원 미정"
        return CardListItem(
            kind: .card(id: card.cardId, visited: card.visited ?? false),
            title: HomeRepository.shorten((card.title ?? card.chiefComplaint) ?? ""),
            meta: "\(Self.writtenOn(date, calendar: calendar)) 작성 · \(clinic)",
            summary: card.axes.flatMap { $0.isEmpty ? nil : $0.joined(separator: " · ") },
            month: Self.month(date, calendar: calendar),
            writtenOn: date
        )
    }

    private func item(from intake: OpenIntakeResponse) -> CardListItem {
        let date = intake.startedAt.flatMap(HomeRepository.date(from:)) ?? today()
        let step = intake.progressCurrent ?? 0
        let total = intake.progressTotal ?? 3
        return CardListItem(
            kind: .openIntake(
                sessionId: intake.sessionId,
                tempSaved: intake.questionsConfirmed ?? false,
                step: step,
                total: total
            ),
            title: intake.siteText.flatMap { $0.isEmpty ? nil : $0 } ?? "정리 중인 증상",
            meta: "\(relativeDay(date)) · \(total)단계 중 \(step)단계",
            summary: "이어서 정리하기",
            month: Self.month(date, calendar: calendar),
            writtenOn: date
        )
    }

    /// 오늘 쓴 것은 날짜 대신 "오늘"이라고 적는다(1j-4).
    private func relativeDay(_ date: Date) -> String {
        calendar.isDate(date, inSameDayAs: today()) ? "오늘" : Self.writtenOn(date, calendar: calendar)
    }

    /// "09.04".
    static func writtenOn(_ date: Date, calendar: Calendar) -> String {
        String(format: "%02d.%02d", calendar.component(.month, from: date), calendar.component(.day, from: date))
    }

    /// "2026년 9월".
    static func month(_ date: Date, calendar: Calendar) -> String {
        "\(calendar.component(.year, from: date))년 \(calendar.component(.month, from: date))월"
    }

    /// "2장" · "1장 선택됨" · "2건" · "1건 선택됨".
    ///
    /// **기록은 "건", 카드는 "장"으로 센다.** Android가 세는 말을 화면마다 나눠 두었고
    /// (`record_count` · `brief_card_list_count`) 같은 목록이 두 화면을 겸하는 iOS도
    /// 그 자리를 따라간다.
    static func countLabel(_ count: Int, unit: String, selected: Bool) -> String {
        selected ? "\(count)\(unit) 선택됨" : "\(count)\(unit)"
    }
}

extension CardRepository {
    /// 카드 한 장을 읽는다(1e-1).
    func card(id: Int64) async -> ApiResult<CardResponse> {
        await client.send(.get("api/cards/\(id)"), as: CardResponse.self)
    }

    /// 카드를 고친다. **보낸 필드만 바뀐다.**
    ///
    /// **확정된 카드를 고치면 서버가 새 버전을 만든다**(FEATURE-SPEC 2.4). 앱은 응답의
    /// 카드를 다시 그린다 — 고친 값을 화면에 그대로 두면 서버가 버린 값이 남는다.
    func update(
        cardId: Int64,
        axes: [AxisEditRequest]? = nil,
        questions: [String]? = nil,
        clinic: ClinicRequest? = nil
    ) async -> ApiResult<CardResponse> {
        let body = UpdateCardRequest(axes: axes, questions: questions, clinic: clinic)
        let first = await client.send(.patch("api/cards/\(cardId)", body: body), as: CardResponse.self)
        // **이미 고친 카드라고 막히면 최신 카드로 갈아타고 한 번만 다시 보낸다.**
        // 그대로 두면 버전이 가지를 치고, 그 가지에 넣은 편집은 어느 화면에도 나오지
        // 않는다. 서버가 갈아탈 카드를 알려주므로 고친 값을 잃지 않는다.
        //
        // **한 번만 따라간다.** 계속 따라가면 어디서 멈출지 알 수 없고, 다른 데서 고치고
        // 있는 중이라면 그 편집을 덮어쓰기를 반복하게 된다.
        guard case .rejected(let error) = first, let latest = CardRepository.latestCardId(error) else {
            return first
        }
        return await client.send(.patch("api/cards/\(latest)", body: body), as: CardResponse.self)
    }

    /// 갈아탈 카드. `CARD_ALREADY_EDITED`일 때만 온다.
    nonisolated static func latestCardId(_ error: ApiError) -> Int64? {
        guard error.code == "CARD_ALREADY_EDITED" else { return nil }
        return error.details["latestCardId"]?.intValue
    }
}

extension CardRepository {
    /// 기록 목록(1j-1)의 한 줄.
    ///
    /// **진료를 마친 기록은 카드가 아니라 기록으로 들어간다** — 카드는 진료 전에 보여
    /// 주는 것이고, 기록은 끝난 뒤에 읽는 것이다.
    func item(from visit: VisitSummaryResponse) -> CardListItem? {
        guard let date = HomeRepository.date(from: visit.visitedOn) else { return nil }
        let clinic = visit.clinicName.flatMap { $0.isEmpty ? nil : $0 } ?? "병원 미정"
        return CardListItem(
            kind: .visit(id: visit.visitId, cardId: visit.cardId),
            title: HomeRepository.shorten(visit.cardTitle ?? ""),
            meta: "\(Self.writtenOn(date, calendar: calendar)) 진료 · \(clinic)",
            summary: CardRepository.visitSummary(visit, calendar: calendar),
            month: Self.month(date, calendar: calendar),
            writtenOn: date
        )
    }

    /// 기록 줄의 셋째 줄. 재방문이 있으면 날짜를 덧붙인다.
    ///
    /// 목록 응답에 축이 담기지 않아 **재방문만** 적는다 — 줄 하나를 위해 상세를
    /// 한 건씩 부르지 않는다.
    static func visitSummary(_ visit: VisitSummaryResponse, calendar: Calendar) -> String? {
        guard let date = visit.followUp?.date.flatMap(HomeRepository.date(from:)) else { return nil }
        let parts = calendar.dateComponents([.month, .day], from: date)
        return String(format: "%02d.%02d 재방문", parts.month ?? 0, parts.day ?? 0)
    }

    /// 카드 · 문답 · 기록을 한 목록으로 묶고 달로 가른다(1j-1).
    func sections(
        cards: [CardSummaryResponse],
        visits: [VisitSummaryResponse],
        openIntake: OpenIntakeResponse?
    ) -> [CardMonthSection] {
        // 기록이 있는 카드는 기록 줄로만 선다. 같은 진료가 두 줄이 되면 안 된다.
        let recorded = Set(visits.compactMap(\.cardId))
        let base = sections(cards: cards.filter { !recorded.contains($0.cardId) }, openIntake: openIntake)
        let visitItems = visits.compactMap(item(from:))
        return CardRepository.merge(base, adding: visitItems)
    }

    /// 달 묶음에 줄을 꽂는다. 최신이 위다.
    static func merge(_ sections: [CardMonthSection], adding items: [CardListItem]) -> [CardMonthSection] {
        var all = sections.flatMap(\.items) + items
        all.sort { $0.writtenOn > $1.writtenOn }

        var merged: [CardMonthSection] = []
        for item in all {
            if let index = merged.firstIndex(where: { $0.month == item.month }) {
                merged[index].items.append(item)
            } else {
                merged.append(CardMonthSection(month: item.month, items: [item]))
            }
        }
        return merged
    }
}
