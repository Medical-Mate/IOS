import Foundation

/// 캘린더가 아는 카드 한 장.
///
/// `1r-1`의 기록 점과 `1r-1-S`(카드만 있는 날 시트)가 읽는다. 목록 응답에 있는 값만
/// 담는다. **항목 수는 목록의 `axes`에서 센다** — Android는 이 값이 없어 카드를 한 번 더
/// 읽는데, iOS 목록 응답에는 항목 이름이 함께 와서 왕복이 필요 없다.
struct CalendarDayCard: Sendable, Equatable, Identifiable {
    let id: Int64
    let title: String
    /// 카드를 쓴 날.
    let writtenOn: Date
    /// 이 카드로 진료를 마쳤는지. 줄의 배지가 읽는 값이다.
    let visited: Bool
    let clinicName: String?
    /// 카드에 담긴 항목 수. 목록이 이름을 주지 않으면 `nil`이다.
    let itemCount: Int?

    /// 이 카드로 이미 만들어진 일정. 있으면 시트가 "만들기"가 아니라 "보러가기"가 된다.
    var scheduled: Appointment?

    init?(from card: CardSummaryResponse, calendar: Calendar) {
        guard let createdAt = card.createdAt,
              let written = HomeRepository.date(from: createdAt)
        else { return nil }
        id = card.cardId
        title = card.title ?? card.chiefComplaint ?? ""
        writtenOn = written
        visited = card.visited ?? false
        clinicName = card.clinicName
        itemCount = card.axes?.count
        scheduled = nil
    }

    /// 줄의 둘째 줄. "2026.09.04 작성 · 5항목"(`3663:14570`). 항목 수를 모르면 날짜만
    /// 적는다 — 지어내지 않는다.
    func meta(calendar: Calendar) -> String {
        let written = CalendarDayCard.writtenLabel(writtenOn, calendar: calendar) + " 작성"
        guard let itemCount, itemCount > 0 else { return written }
        return "\(written) · \(itemCount)항목"
    }

    /// "2026.09.04". 홈의 카드 줄과 같은 형식이다.
    nonisolated static func writtenLabel(_ date: Date, calendar: Calendar) -> String {
        String(
            format: "%04d.%02d.%02d",
            calendar.component(.year, from: date),
            calendar.component(.month, from: date),
            calendar.component(.day, from: date)
        )
    }
}

/// 캘린더가 아는 진료 후 기록 한 줄. 기록 점과 아직 확정하지 않은 재방문만 본다.
struct CalendarVisitDay: Sendable, Equatable {
    let visitedOn: Date
    /// 진료 후 기록에서 뽑아 둔 재방문 날. 일정으로는 아직 없다.
    let followUpOn: Date?

    init?(from visit: VisitSummaryResponse) {
        guard let on = HomeRepository.date(from: visit.visitedOn) else { return nil }
        visitedOn = on
        followUpOn = visit.followUp?.date.flatMap { HomeRepository.date(from: $0) }
    }

    init(visitedOn: Date, followUpOn: Date?) {
        self.visitedOn = visitedOn
        self.followUpOn = followUpOn
    }
}
