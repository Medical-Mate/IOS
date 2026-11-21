import Foundation
import Observation

/// `1j-3` 기록 상세의 상태.
///
/// **한 증상의 일대기를 한 화면에 잇는다** — 다음 예정 · 진료 후 기록 · 브리핑 카드.
/// 세 곳에서 읽는다(기록 · 카드 · 일정). 기록을 못 읽으면 실패이고, 카드와 일정은 못
/// 읽어도 그 칸만 빠진다 — 상세를 여는 사람이 보려는 것은 진료에서 들은 말이다.
///
/// **최신이 위다.** 시안 `1j-3`은 카드가 위이고 `1j-3-R`(재방문 누적)은 최신이 위인데,
/// 디자인 피드백이 "최신 기록이 맨 위로 가는 게 멘탈 모델"이라고 적어 둔 쪽을 Android가
/// 따랐고 여기도 같이 간다(COMPONENT-MAP 3장 #21).
/// 타임라인 칸의 갈래. **타입 안에 두 겹으로 넣지 않는다**(SwiftLint `nesting`).
enum RecordStepKind: Equatable {
    /// 브리핑 카드. 접었다 펼 수 있다.
    case card
    /// 진료 후 기록.
    case visit(id: Int64)
    /// 아직 오지 않은 칸.
    case scheduled
}

@MainActor
@Observable
final class RecordDetailModel {
    /// 타임라인의 한 칸.
    struct Step: Identifiable, Equatable {
        let id: String
        let kind: RecordStepKind
        /// "09.04 작성" · "09.12 · 진료 후 기록 · 재방문" · "09.26 예정".
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
        let opened = VisitMapping.visit(from: response, calendar: calendar)

        var card: BriefCard?
        var summaries: [VisitSummaryResponse] = []
        if let cardId = opened.cardId {
            if case .success(let cardResponse) = await cards.card(id: cardId) {
                card = BriefCardMapping.card(from: cardResponse, calendar: calendar)
            }
            if case .success(let list) = await visits.visits(cardId: cardId) {
                summaries = list
            }
        }
        self.card = card

        let history = summaries.count <= 1 ? [opened] : await self.history(summaries, opened: opened)
        // **가장 최근 기록**이 기준이다. 첫 기록에서 열어도 상세는 그 카드의 기록을 모두
        // 세우므로, 이미 다녀온 재방문이 예정으로 서면 안 된다.
        let latest = history.max { ($0.visitedOn ?? .distantPast) < ($1.visitedOn ?? .distantPast) } ?? opened

        let pending = await pendingStep(cardId: opened.cardId, latest: latest)
        let records = RecordDetailModel.visitSteps(history, calendar: calendar)
        let cardStep = card.map { RecordDetailModel.cardStep($0, calendar: calendar) }

        steps = [pending].compactMap(\.self) + records + [cardStep].compactMap(\.self)
        title = RecordDetailModel.title(card: card, summaries: summaries, newest: history.first ?? opened)
        meta = RecordDetailModel.clinicLine(history, calendar: calendar)
        badge = RecordDetailModel.headBadge(visitCount: history.count)
        isLoading = false
    }

    /// 이 카드에 쌓인 기록 전부. **최근 진료일이 앞이다.**
    ///
    /// 모아 주는 목록에는 축이 없어서 기록마다 한 번씩 더 읽는다. **읽지 못한 기록은 빼고
    /// 그린다** — 한 건 때문에 화면 전체를 실패로 두면 이미 읽은 기록까지 못 보게 된다.
    private func history(_ summaries: [VisitSummaryResponse], opened: Visit) async -> [Visit] {
        var result: [Visit] = []
        for summary in summaries {
            if summary.visitId == opened.id {
                result.append(opened)
            } else if case .success(let response) = await visits.visit(id: summary.visitId) {
                result.append(VisitMapping.visit(from: response, calendar: calendar))
            }
        }
        return result.isEmpty ? [opened] : result
    }

    /// 예정 칸. **잡아 둔 일정이 있으면 그것, 없으면 최신 기록의 재방문 날짜다** —
    /// 캘린더가 점을 찍는 값과 같다. 둘 다 없으면 칸을 두지 않는다.
    private func pendingStep(cardId: Int64?, latest: Visit) async -> Step? {
        if let appointment = await nextVisit(cardId: cardId, after: latest.visitedOn) {
            return RecordDetailModel.pending(appointment, calendar: calendar)
        }
        guard let followUp = latest.followUp,
              let on = latest.visitedOn, followUp.date > on
        else { return nil }
        return RecordDetailModel.pending(followUp, calendar: calendar)
    }

    /// 그 카드로 잡힌 다음 일정. **이 진료 자체의 일정은 다음이 아니다** — 서버의
    /// "앞으로의 일정"이 오늘 것을 하루 종일 담아서 진료한 날 열면 그 날 일정이 예정으로 섰다.
    private func nextVisit(cardId: Int64?, after: Date?) async -> Appointment? {
        guard let cardId, case .success(let list) = await appointments.upcoming() else { return nil }
        return list.compactMap(AppointmentMapping.appointment(from:)).first { appointment in
            appointment.cards.contains { $0.id == cardId }
                && appointment.status != .canceled
                && (after.map { appointment.on > $0 } ?? true)
        }
    }

    // MARK: - 칸 만들기

    /// 카드 칸.
    ///
    /// 시점 줄은 `09.04 작성`이다. **시안은 뒤에 `09.12 진료실에서 보여줌`을 잇지만** 그
    /// 날짜는 바로 위 진료 후 기록 칸이 이미 적고 있어서 같은 날이 두 줄에 서게 돼 뺐다
    /// (Android와 같다 · COMPONENT-MAP 3장 #21). 작성일이 없을 때만 이름을 적는다.
    nonisolated static func cardStep(_ card: BriefCard, calendar: Calendar) -> Step {
        let written = card.patientLine.split(separator: "·").last.map {
            $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " 작성", with: "")
        }
        let when = written.map { "\(shortDay($0)) 작성" } ?? "브리핑 카드"
        return Step(id: "card", kind: .card, when: when, title: "브리핑 카드", items: card.items)
    }

    /// "2026.09.04" · "9월 4일" 어느 쪽이 와도 "09.04"로 줄인다.
    nonisolated static func shortDay(_ text: String) -> String {
        let numbers = text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard numbers.count >= 2 else { return text }
        let month = numbers.count >= 3 ? numbers[1] : numbers[0]
        let day = numbers.count >= 3 ? numbers[2] : numbers[1]
        return String(format: "%02d.%02d", month, day)
    }

    /// 진료 후 기록 칸. **최신이 앞이고, 여러 번이면 가장 오래된 것이 초진이다**(`1j-3-R`).
    nonisolated static func visitSteps(_ history: [Visit], calendar: Calendar) -> [Step] {
        history.enumerated().map { index, visit in
            let day = visit.visitedOn.map { shortDay(VisitMapping.monthDay($0, calendar: calendar)) }
            let kind = visitKind(count: history.count, index: index)
            let when = [day, "진료 후 기록", kind].compactMap(\.self).joined(separator: " · ")
            return Step(
                id: "visit-\(visit.id)",
                kind: .visit(id: visit.id),
                when: when,
                title: "진료 후 기록",
                // **재방문 줄은 여기서도 강조한다.** `1j-3`(`3663:15567`)이 1q-1과 같이
                // 그 줄만 `fg/primary`로 세운다 — 타임라인에서 다음에 할 일이다.
                items: visit.items.map {
                    BriefCardItem(key: $0.label, value: $0.value, isEmphasized: $0.isEmphasized, axis: $0.axis)
                }
            )
        }
    }

    /// 몇 번째 진료인지. **한 건이면 붙이지 않는다.** 최신이 0이라 가장 오래된 것이 초진이다.
    nonisolated static func visitKind(count: Int, index: Int) -> String? {
        guard count > 1 else { return nil }
        return index == count - 1 ? "초진" : "재방문"
    }

    /// 잡아 둔 일정의 예정 칸. **병원은 적지 않는다** — 머리글 둘째 줄이 이미 말한다.
    nonisolated static func pending(_ appointment: Appointment, calendar: Calendar) -> Step {
        // 시각이 없으면 날짜만 적는다. 시간 미정인 일정이다.
        let detail = [CalendarMonth.dayTitle(appointment.on, calendar: calendar), appointment.time?.label]
            .compactMap(\.self)
            .joined(separator: " ")
        return Step(
            id: "scheduled-\(appointment.id)",
            kind: .scheduled,
            when: "\(shortDay(VisitMapping.monthDay(appointment.on, calendar: calendar))) 예정",
            title: "",
            items: [],
            notice: ("다음 진료가 예약돼 있어요", detail)
        )
    }

    /// 아직 일정으로 잡지 않은 재방문.
    ///
    /// 기록에 "일주일 뒤"라고 남긴 날짜다. 캘린더가 같은 값으로 점을 찍는데 상세에 없으면
    /// 달력과 상세가 다른 날을 가리킨다. **잡아 둔 일정이 아니라 예약됐다고 적지 않고,**
    /// 범위로 말한 것이면 "전후"를 붙인다.
    nonisolated static func pending(_ followUp: VisitFollowUp, calendar: Calendar) -> Step {
        let date = CalendarMonth.dayTitle(followUp.date, calendar: calendar)
        return Step(
            id: "follow-up",
            kind: .scheduled,
            when: "\(shortDay(VisitMapping.monthDay(followUp.date, calendar: calendar))) 예정",
            title: "",
            items: [],
            notice: ("재방문 예정이에요", date + (followUp.approximate ? " 전후" : ""))
        )
    }

    // MARK: - 머리

    /// 머리 제목. **카드 제목이 비면 목록이 든 제목으로, 그것도 없으면 병원으로 받친다** —
    /// 병원은 둘째 줄이 적는 값이라 제목에 서면 같은 말이 두 줄에 이어 나온다.
    nonisolated static func title(card: BriefCard?, summaries: [VisitSummaryResponse], newest: Visit) -> String {
        if let title = card?.title, !title.isEmpty { return title }
        if let listed = summaries.compactMap({ $0.cardTitle }).first(where: { !$0.isEmpty }) { return listed }
        return newest.clinicName ?? ""
    }

    /// 머리글 둘째 줄. **병원이 앞이고 날짜가 뒤다.**
    ///
    /// 한 번이면 "서울OO병원 내과 · 09.12 진료"(`1j-3`), 여러 번이면
    /// "서울OO병원 내과 · 09.12 초진 · 09.26 재방문"(`1j-3-R`)이다.
    /// **여러 번인 쪽은 오래된 차례다** — 타임라인은 최신이 위인데 이 줄만 반대인 이유는,
    /// 여기가 흘러온 순서를 한 줄로 읽는 자리이기 때문이다.
    nonisolated static func clinicLine(_ history: [Visit], calendar: Calendar) -> String {
        let clinic = history.compactMap { $0.clinicName }.first { !$0.isEmpty }
        let days: [String]
        if history.count == 1 {
            days = history[0].visitedOn
                .map { ["\(shortDay(VisitMapping.monthDay($0, calendar: calendar))) 진료"] } ?? []
        } else {
            days = history.reversed().enumerated().compactMap { index, visit in
                visit.visitedOn.map {
                    "\(shortDay(VisitMapping.monthDay($0, calendar: calendar))) \(index == 0 ? "초진" : "재방문")"
                }
            }
        }
        return ([clinic].compactMap(\.self) + days).joined(separator: " · ")
    }

    /// 한 번이면 "진료 완료", 여러 번이면 "진료 n회".
    ///
    /// **몇 번 다녀왔는지는 상태가 아니라 세어 봐야 아는 값이다.**
    nonisolated static func headBadge(visitCount: Int) -> (text: String, tone: MMBadge.Tone) {
        visitCount > 1 ? ("진료 \(visitCount)회", .success) : ("진료 완료", .success)
    }
}
