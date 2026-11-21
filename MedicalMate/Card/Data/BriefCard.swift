import Foundation

/// 브리핑 카드 한 장(1e-1).
struct BriefCard: Sendable, Equatable {
    let id: Int64
    let title: String
    /// "김OO · 32세 여 · 2026.09.18 작성".
    let patientLine: String
    /// 이름·나이를 가린 줄. 내보내기 시트의 토글이 이것으로 바꾼다.
    let maskedPatientLine: String
    var items: [BriefCardItem]
    /// 통증 강도. **KV 줄이 아니라 눈금이라** 축에서 빼 따로 든다 — 칩·낱말·NRS를 한 줄로
    /// 그리는 모양은 줄 하나로 낼 수 없다.
    let severity: Int?
    /// 카드 밖 경고로 나가는 알러지. **처방을 바꾸는 값이라 다른 정보와 같은 무게로 두지
    /// 않는 것이 시안의 판단이다.**
    let allergies: [String]
    var questions: [String]
    let hospital: BriefCardHospital?
    let appointment: BriefCardAppointment?
    let status: String?
    /// 진료를 마쳤는지. **상세 응답에 없을 수 있어** 목록에서 채워 넣는다
    /// (Android `Backend#101`). 그래서 `var`다.
    var visited: Bool

    /// 제목 옆 배지(FEATURE-SPEC 2.4).
    var badge: (text: String, tone: MMBadge.Tone) {
        visited ? ("진료 완료", .success) : ("진료 전", .brand)
    }
}

/// 카드의 항목 한 줄. Figma `KV Row`.
struct BriefCardItem: Sendable, Equatable, Identifiable {
    let key: String
    var value: String
    /// 그 진료에서 가장 중요한 한 항목. **카드마다 하나를 넘기지 않는다** — 전부
    /// 강조하면 아무것도 강조되지 않는다.
    var isEmphasized: Bool = false
    /// 서버의 축 id(`onset` · `site` 같은 것).
    ///
    /// 고친 값을 보낼 때 어느 축인지 알아야 한다. 줄 이름("시작")은 우리가 붙인 표시용이라
    /// 그것으로는 못 찾는다. **축에서 오지 않은 줄(복용약 · 기저질환)은 `nil`이고, 그런
    /// 줄은 고쳐도 보낼 곳이 없다.**
    let axis: String?

    var id: String { axis ?? key }
}

struct BriefCardHospital: Sendable, Equatable {
    let name: String
    let address: String?
}

/// 이 카드로 잡은 일정. 하단 버튼이 이 값으로 갈린다.
struct BriefCardAppointment: Sendable, Equatable {
    let id: Int64
    let date: Date
    let clinicName: String?
}

/// 하단 버튼. 일정이 있는지, 그 날이 지났는지로 갈린다.
enum BriefCardFooterAction: Sendable, Equatable {
    /// 일정이 없다.
    case schedule
    /// 아직 안 지났다.
    case viewSchedule
    /// 지났다. **당일도 여기다** — 진료를 다녀왔을 수 있다.
    case recordVisit

    var title: String {
        switch self {
        case .schedule: "진료 일정 잡기"
        case .viewSchedule: "진료 일정 보기"
        case .recordVisit: "진료 후 기록하기"
        }
    }

    /// 버튼의 모양. **셋이 다 다르다.**
    ///
    /// 시안이 일정 잡기는 채운 면(`3663:7335`), 일정 보기는 테두리(`3663:7393`),
    /// 진료 후 기록은 옅은 면(`3663:7428`)으로 그린다. 지금 할 일이 무엇인지에 따라
    /// 무게가 갈리는 자리다 — 아직 안 잡은 일정이 가장 급하다.
    var kind: MMButtonKind {
        switch self {
        case .schedule: .primary
        case .viewSchedule: .outline
        case .recordVisit: .tonal
        }
    }
}

/// 편집 중인 사본.
///
/// **원본을 그대로 고치지 않는다.** 편집 중에 취소를 누르면 카드가 그대로 남아 있어야
/// 한다. 값만 담지 않고 목록째로 담는 이유: 항목과 질문을 지울 수 있게 되면서 순번을
/// 열쇠로 쓰는 방식이 깨졌다 — 두 번째를 지우면 그 뒤가 하나씩 밀린다.
struct BriefCardDraft: Sendable, Equatable {
    var items: [BriefCardItem]
    var questions: [String]

    init(card: BriefCard) {
        items = card.items
        questions = card.questions
    }
}
