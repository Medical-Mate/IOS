import Foundation

/// 응답을 화면 값으로 옮긴다.
///
/// 카드의 `BriefCardMapping`과 같은 자리다. 서버가 계약을 바꾸면 고칠 곳이 여기 하나가
/// 되도록 모아 둔다 — Android는 실제로 고정 세 필드가 축 맵으로 바뀌었을 때 이 파일만
/// 고쳤고 화면과 모델은 손대지 않았다.
enum VisitMapping {
    static func visit(from response: VisitResponse, calendar: Calendar = .current) -> Visit {
        let followUp = self.followUp(from: response.followUp)
        return Visit(
            id: response.visitId,
            cardId: response.cardId,
            clinicName: response.clinicName,
            visitedOn: response.visitedOn.flatMap(HomeRepository.date(from:)),
            items: withRevisitDate(items(from: response.axes), followUp: followUp, calendar: calendar),
            followUp: followUp,
            patientNotes: response.patientNotes ?? [],
            rawNote: response.rawNote
        )
    }

    static func classification(
        from response: ClassifyMemoResponse,
        calendar: Calendar = .current
    ) -> VisitClassification {
        let followUp = self.followUp(from: response.followUp)
        return VisitClassification(
            items: withRevisitDate(items(from: response.axes), followUp: followUp, calendar: calendar),
            followUp: followUp,
            patientNotes: response.patientNotes ?? [],
            labels: response.labels ?? [:]
        )
    }

    static func listItem(from response: VisitSummaryResponse) -> VisitListItem? {
        guard let date = HomeRepository.date(from: response.visitedOn) else { return nil }
        return VisitListItem(
            id: response.visitId,
            cardId: response.cardId,
            cardTitle: response.cardTitle ?? "",
            clinicName: response.clinicName,
            visitedOn: date,
            followUp: followUp(from: response.followUp)
        )
    }

    /// 축을 줄로 편다.
    ///
    /// **값이 있는 축만 남긴다.** 서버가 못 찾은 항목은 키가 없고, 값이 비었다는 것은
    /// 환자가 지웠다는 뜻이다. 어느 쪽이든 그릴 줄이 아니다.
    ///
    /// 차례는 `VisitAxis.order`다. **모르는 축은 뒤에 그 순서대로 붙인다** — 항목 이름이
    /// 닫힌 목록이 아니라 AI가 늘릴 수 있고, 아는 것만 그리면 환자가 적은 줄이 사라진다.
    static func items(from axes: [String: VisitAxisResponse]?) -> [VisitItem] {
        guard let axes else { return [] }
        let known = VisitAxis.order.filter { axes[$0] != nil }
        let rest = axes.keys.filter { !VisitAxis.order.contains($0) }.sorted()
        return (known + rest).compactMap { axis in
            guard let value = axes[axis]?.value, !value.trimmingCharacters(in: .whitespaces).isEmpty else {
                return nil
            }
            return VisitItem(axis: axis, label: label(for: axis), value: value)
        }
    }

    /// 축 이름. **모르는 축은 축 id를 그대로 쓴다** — 빈 이름으로 두면 값만 떠 있는 줄이
    /// 되고, 그 줄이 무엇을 적은 것인지 알 수 없다.
    static func label(for axis: String) -> String {
        switch axis {
        case VisitAxis.findings: "소견"
        case VisitAxis.tests: "검사"
        case VisitAxis.medication: "약"
        case VisitAxis.lifestyle: "지침"
        case VisitAxis.followUp: "재방문"
        default: axis
        }
    }

    // MARK: - 재방문 줄

    /// 재방문 줄에 날짜를 덧붙인다.
    ///
    /// 축의 값은 환자가 말한 그대로다("2주 뒤"). **그것만으로는 달력의 어느 날인지 알 수
    /// 없고, 날짜만 적으면 환자가 한 말이 사라진다.** 둘을 함께 적어 시안의
    /// "2주 뒤 재방문 (9월 26일 전후)"가 된다.
    ///
    /// **이미 붙어 있으면 다시 붙이지 않는다** — 붙인 값을 그대로 저장한 기록이 있어서,
    /// 그것을 읽을 때 또 붙이면 "(9월 26일 전후) (9월 26일 전후)"가 된다.
    static func withRevisitDate(
        _ items: [VisitItem],
        followUp: VisitFollowUp?,
        calendar: Calendar
    ) -> [VisitItem] {
        guard let note = revisitNote(followUp, calendar: calendar) else { return items }
        return items.map { item in
            guard item.axis == VisitAxis.followUp, !item.value.hasSuffix(note) else { return item }
            var copy = item
            copy.value = "\(item.value) \(note)"
            return copy
        }
    }

    /// 재방문 줄 뒤에 붙는 "(9월 26일 전후)". 괄호까지 포함한다.
    ///
    /// **범위로 말한 것이면 "전후"를 붙인다.** "2주 뒤"는 날짜가 아니라서, 정확한 날짜처럼
    /// 그리면 그날이 아니면 안 되는 것으로 읽힌다.
    static func revisitNote(_ followUp: VisitFollowUp?, calendar: Calendar) -> String? {
        guard let followUp else { return nil }
        let components = calendar.dateComponents([.month, .day], from: followUp.date)
        guard let month = components.month, let day = components.day else { return nil }
        return "(\(month)월 \(day)일\(followUp.approximate ? " 전후" : ""))"
    }

    /// 저장할 값에서 붙인 날짜를 뗀다.
    ///
    /// **서버에는 환자가 말한 값만 가야 한다** — 날짜는 `followUp`이 따로 나르고, 값에
    /// 박아 보내면 다시 읽을 때 붙이는 날짜와 겹친다.
    static func withoutRevisitNote(_ value: String, followUp: VisitFollowUp?, calendar: Calendar) -> String {
        guard let note = revisitNote(followUp, calendar: calendar) else { return value }
        if value.hasSuffix(" \(note)") { return String(value.dropLast(note.count + 1)) }
        if value.hasSuffix(note) { return String(value.dropLast(note.count)) }
        return value
    }

    static func followUp(from response: FollowUpResponse?) -> VisitFollowUp? {
        guard let response, let date = response.date.flatMap(HomeRepository.date(from:)) else { return nil }
        return VisitFollowUp(date: date, text: response.text, approximate: response.approximate ?? false)
    }

    /// 저장할 기록 한 건. **인자를 묶어 둔다** — 일곱 개를 늘어놓으면 부르는 쪽에서
    /// 차례가 헷갈린다.
    struct Draft {
        var clinicName: String?
        var visitedOn: Date?
        var items: [VisitItem]
        var followUp: VisitFollowUp?
        var patientNotes: [String]
        var rawNote: String?
    }

    /// 저장 요청으로 옮긴다.
    static func createRequest(_ draft: Draft, calendar: Calendar) -> CreateVisitRequest {
        let clinicName = draft.clinicName
        let visitedOn = draft.visitedOn
        let items = draft.items
        let followUp = draft.followUp
        let patientNotes = draft.patientNotes
        let rawNote = draft.rawNote
        return CreateVisitRequest(
            clinicName: clinicName,
            visitedOn: visitedOn.map { day($0, calendar: calendar) },
            axes: items.map {
                VisitAxisRequest(
                    axis: $0.axis,
                    value: withoutRevisitNote($0.value, followUp: followUp, calendar: calendar)
                )
            },
            followUp: followUp.map {
                FollowUpRequest(
                    date: day($0.date, calendar: calendar),
                    text: $0.text,
                    approximate: $0.approximate
                )
            },
            patientNotes: patientNotes,
            rawNote: rawNote
        )
    }

    /// 서버가 받는 `yyyy-MM-dd`.
    static func day(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    /// 화면이 쓰는 "9월 12일".
    static func monthDay(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.month, .day], from: date)
        return "\(components.month ?? 0)월 \(components.day ?? 0)일"
    }

    /// 기록 머리의 "서울OO병원 내과 · 2026.09.18".
    static func recordMeta(clinicName: String?, visitedOn: Date?, calendar: Calendar) -> String {
        let day = visitedOn.map { date -> String in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return String(format: "%d.%02d.%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
        }
        return [clinicName, day].compactMap(\.self).joined(separator: " · ")
    }
}
