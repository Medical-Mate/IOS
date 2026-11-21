import Foundation

/// 진료 후 기록 한 건(1q-1).
struct Visit: Sendable, Equatable {
    let id: Int64
    let cardId: Int64?
    let clinicName: String?
    let visitedOn: Date?
    var items: [VisitItem]
    let followUp: VisitFollowUp?
    /// 어느 항목에도 들어가지 않은 문장.
    let patientNotes: [String]
    /// 환자가 적은 원문. **상세에만 온다.**
    let rawNote: String?
}

/// 기록의 항목 한 줄.
///
/// **항목이 가변이다.** 전에는 소견·검사·약 셋으로 고정이었는데 지금은 브리핑 카드와 같은
/// 모양의 축 맵이고 AI가 축을 늘려도 실린다.
struct VisitItem: Sendable, Equatable, Identifiable {
    let axis: String
    let label: String
    var value: String

    var id: String { axis }
    /// 재방문 줄만 강조한다 — 1q-1이 그 줄을 `Type=Emphasis`로 그린다.
    var isEmphasized: Bool { axis == VisitAxis.followUp }
}

/// 재방문.
struct VisitFollowUp: Sendable, Equatable {
    let date: Date
    let text: String?
    /// "2주 뒤"처럼 **범위로 말한 것.** 화면이 "전후"를 붙인다.
    let approximate: Bool
}

/// 메모를 나눈 결과. **저장되지 않는다** — 저장 전에 미리 볼 수 있다.
struct VisitClassification: Sendable, Equatable {
    var items: [VisitItem]
    let followUp: VisitFollowUp?
    let patientNotes: [String]
    /// 직전 응답의 분류. **다시 부를 때 함께 보낸다** — 안 보내면 줄 하나를 옮길 때마다
    /// AI 모델 호출이 나간다.
    let labels: [String: String]
}

/// 기록 목록의 한 줄(H 섹션이 쓴다).
struct VisitListItem: Sendable, Equatable, Identifiable {
    let id: Int64
    let cardId: Int64?
    let cardTitle: String
    let clinicName: String?
    let visitedOn: Date
    let followUp: VisitFollowUp?
}

/// 기록의 축 id. 서버 계약에 묶인 값이다.
enum VisitAxis {
    static let findings = "findings"
    static let tests = "tests"
    static let medication = "medication_instructions"
    /// 생활 지침. **서버가 기능을 켜야 나온다.** 꺼져 있으면 약 칸에 접혀 온다.
    static let lifestyle = "lifestyle_instructions"
    static let followUp = "follow_up"

    /// 1q-1이 그리는 차례.
    static let order = [findings, tests, medication, lifestyle, followUp]
}
