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
        let clinic = card.clinicName?.isEmpty == false ? card.clinicName! : "병원 미정"
        return CardListItem(
            kind: .card(id: card.cardId, visited: card.visited ?? false),
            title: HomeRepository.shorten((card.title ?? card.chiefComplaint) ?? ""),
            meta: "\(Self.writtenOn(date, calendar: calendar)) 작성 · \(clinic)",
            summary: (card.axes?.isEmpty == false) ? card.axes!.joined(separator: " · ") : nil,
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
            title: intake.siteText?.isEmpty == false ? intake.siteText! : "정리 중인 증상",
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

    /// "2장" · "1장 선택됨".
    static func countLabel(_ count: Int, selected: Bool) -> String {
        selected ? "\(count)장 선택됨" : "\(count)장"
    }
}
