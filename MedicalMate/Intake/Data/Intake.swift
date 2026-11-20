import Foundation

/// 문답 한 줄.
struct IntakeMessage: Sendable, Equatable, Identifiable {
    let seq: Int64
    let fromPatient: Bool
    let text: String

    var id: Int64 { seq }
}

/// 3단계 추천 질문 한 줄(1c-D~D4).
struct IntakeQuestionRow: Sendable, Equatable, Identifiable {
    let id: UUID
    var text: String
    var isSelected: Bool
    /// 환자가 직접 적은 줄인지. 추천과 갈라 둔다 — **서버 후보로 덮을 때 이 줄은 남긴다.**
    let isOwn: Bool

    init(id: UUID = UUID(), text: String, isSelected: Bool = false, isOwn: Bool = false) {
        self.id = id
        self.text = text
        self.isSelected = isSelected
        self.isOwn = isOwn
    }
}

/// 증상 정리 세 단계. 진행 표시는 `n / 3`이다.
enum IntakeStep: Int, Sendable, CaseIterable {
    case site = 1
    case severity = 2
    case chat = 3

    static let total = 3
    /// 진행 표시 왼쪽에 서는 말.
    static let label = "증상 정리"
}

/// 짚은 부위. 1단계가 넘겨준다.
///
/// 1단계(인체도)는 D 섹션 밖이라 아직 그리지 않았다. 그때까지는 이 값을 밖에서 받는다.
struct IntakeSite: Sendable, Equatable {
    /// 온톨로지 id. 구역까지면 `SUR:*`, 앵커까지면 `ANC:*`.
    let nodeId: String?
    /// 사람이 읽는 표현. 3단계 머리의 칩에 그대로 선다.
    let text: String
    /// `LEFT` · `RIGHT`. **좌우가 있는 부위에만 채운다.**
    let side: String?

    init(nodeId: String? = nil, text: String, side: String? = nil) {
        self.nodeId = nodeId
        self.text = text
        self.side = side
    }
}

/// 입력 수단. **음성이었다는 사실만 남기고 오디오는 기기 밖으로 나가지 않는다.**
enum IntakeInputMethod: String, Sendable {
    case text = "TEXT"
    case voice = "STT"
}
