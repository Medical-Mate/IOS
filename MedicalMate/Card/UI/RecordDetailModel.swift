import Foundation
import Observation

/// `1j-3` 기록 상세의 상태.
///
/// **한 증상의 일대기를 시간 순으로 편다** — 카드를 만든 날, 진료받은 날, 다음 예정.
@MainActor
@Observable
final class RecordDetailModel {
    /// 타임라인의 한 칸.
    struct Step: Identifiable, Equatable {
        enum Kind: Equatable {
            /// 브리핑 카드. 접었다 펼 수 있다.
            case card
            /// 진료 후 기록.
            case visit(id: Int64)
            /// 아직 오지 않은 일정.
            case scheduled
        }

        let id: String
        let kind: Kind
        /// "09.04 작성 · 09.12 진료실에서 보여줌".
        let when: String
        let title: String
        var items: [BriefCardItem]
        /// 예정 칸의 안내.
        var notice: (title: String, message: String)?

        static func == (lhs: Step, rhs: Step) -> Bool { lhs.id == rhs.id && lhs.items == rhs.items }
    }

    private(set) var title = ""
    private(set) var meta = ""
    private(set) var badge: (text: String, tone: MMBadge.Tone)?
    private(set) var steps: [Step] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 카드 칸을 펼쳤는지(`1j-3-X`).
    private(set) var isCardExpanded = false
    private(set) var card: BriefCard?

    private let visitId: Int64
    private let visits: VisitRepository
    private let cards: CardRepository
    private let appointments: AppointmentRepository
    private let calendar: Calendar

    init(
        visitId: Int64,
        visits: VisitRepository,
        cards: CardRepository,
        appointments: AppointmentRepository,
        calendar: Calendar = .current
    ) {
        self.visitId = visitId
        self.visits = visits
        self.cards = cards
        self.appointments = appointments
        self.calendar = calendar
    }

    /// 접었을 때 보이는 줄 수. **시안이 부위 · 기간 · 양상 셋을 남긴다.**
    nonisolated static let collapsedItemCount = 3

    var cardItems: [BriefCardItem] {
        guard let card else { return [] }
        return isCardExpanded ? card.items : Array(card.items.prefix(Self.collapsedItemCount))
    }

    var disclosureTitle: String { isCardExpanded ? "접기" : "카드 전체 보기" }

    func toggleCard() { isCardExpanded.toggle() }

    func load() async {
        errorMessage = nil

        guard case .success(let response) = await visits.visit(id: visitId) else {
            errorMessage = "기록을 불러오지 못했어요."
            isLoading = false
            return
        }
        let visit = VisitMapping.visit(from: response, calendar: calendar)

        var cardStep: Step?
        var history: [VisitSummaryResponse] = []
        if let cardId = visit.cardId {
            if case .success(let cardResponse) = await cards.card(id: cardId) {
                let card = BriefCardMapping.card(from: cardResponse, calendar: calendar)
                self.card = card
                title = card.title
                cardStep = RecordDetailModel.cardStep(card, visit: visit, calendar: calendar)
            }
            if case .success(let list) = await visits.visits(cardId: cardId) {
                history = list
            }
        }
        if title.isEmpty { title = visit.clinicName ?? "" }

        var visitSteps = RecordDetailModel.visitSteps(
            current: visit,
            history: history,
            calendar: calendar
        )
        // **일어난 차례대로** 편다. 1j-3이 카드 → 기록 → 예정으로 그린다.
        visitSteps.sort { $0.id < $1.id }

        var all: [Step] = []
        if let cardStep { all.append(cardStep) }
        all.append(contentsOf: visitSteps)
        if let scheduled = await scheduledStep(for: visit) { all.append(scheduled) }

        steps = all
        meta = RecordDetailModel.headMeta(visit, visitCount: max(history.count, 1), calendar: calendar)
        badge = RecordDetailModel.headBadge(visitCount: max(history.count, 1))
        isLoading = false
    }

    // MARK: - 칸 만들기

    /// 카드 칸. 언제 만들었고 언제 보여 줬는지를 함께 적는다.
    nonisolated static func cardStep(_ card: BriefCard, visit: Visit, calendar: Calendar) -> Step {
        let made = card.patientLine.split(separator: "·").last.map {
            $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " 작성", with: "")
        }
        let shown = visit.visitedOn.map { VisitMapping.monthDay($0, calendar: calendar) }
        let when = [
            made.map { "\(Self.shortDay($0)) 작성" },
            shown.map { "\(Self.shortDay($0)) 진료실에서 보여줌" },
        ].compactMap(\.self).joined(separator: " · ")

        return Step(
            id: "card",
            kind: .card,
            when: when,
            title: "브리핑 카드",
            items: card.items
        )
    }

    /// "2026.09.04" · "9월 4일" 어느 쪽이 와도 "09.04"로 줄인다.
    nonisolated static func shortDay(_ text: String) -> String {
        let numbers = text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard numbers.count >= 2 else { return text }
        let month = numbers.count >= 3 ? numbers[1] : numbers[0]
        let day = numbers.count >= 3 ? numbers[2] : numbers[1]
        return String(format: "%02d.%02d", month, day)
    }

    /// 진료 후 기록 칸. **여러 번 진료받았으면 칸이 여럿이다**(`1j-3-R`).
    nonisolated static func visitSteps(current: Visit, history: [VisitSummaryResponse], calendar: Calendar) -> [Step] {
        let isRepeat = history.count > 1
        let day = current.visitedOn.map { VisitMapping.monthDay($0, calendar: calendar) } ?? ""
        let suffix = isRepeat ? " · 재방문" : ""
        return [
            Step(
                id: "visit-\(current.id)",
                kind: .visit(id: current.id),
                when: "\(shortDay(day)) · 진료 후 기록\(suffix)",
                title: "진료 후 기록",
                items: current.items.map { BriefCardItem(key: $0.label, value: $0.value, axis: $0.axis) }
            ),
        ]
    }

    /// 예정 칸. 아직 오지 않은 일정이 있을 때만 선다.
    private func scheduledStep(for visit: Visit) async -> Step? {
        guard case .success(let list) = await appointments.upcoming() else { return nil }
        let linked = visit.cardId
        guard let next = list
            .compactMap(AppointmentMapping.appointment(from:))
            .first(where: { appointment in
                guard let linked else { return true }
                return appointment.cards.contains { $0.id == linked }
            })
        else { return nil }

        let day = VisitMapping.monthDay(next.on, calendar: calendar)
        let detail = [CalendarMonth.dayTitle(next.on, calendar: calendar), next.time?.label]
            .compactMap(\.self)
            .joined(separator: " ")
        return Step(
            id: "scheduled-\(next.id)",
            kind: .scheduled,
            when: "\(RecordDetailModel.shortDay(day)) 예정",
            title: "",
            items: [],
            notice: ("다음 진료가 예약돼 있어요", detail)
        )
    }

    // MARK: - 머리

    /// "서울OO병원 내과 · 09.12 진료". 여러 번이면 "초진 · 재방문"으로 적는다.
    nonisolated static func headMeta(_ visit: Visit, visitCount: Int, calendar: Calendar) -> String {
        let day = visit.visitedOn.map { shortDay(VisitMapping.monthDay($0, calendar: calendar)) }
        let label = visitCount > 1 ? "초진" : "진료"
        return [visit.clinicName, day.map { "\($0) \(label)" }].compactMap(\.self).joined(separator: " · ")
    }

    /// 한 번이면 "진료 완료", 여러 번이면 "진료 n회".
    nonisolated static func headBadge(visitCount: Int) -> (text: String, tone: MMBadge.Tone) {
        visitCount > 1 ? ("진료 \(visitCount)회", .success) : ("진료 완료", .success)
    }
}
