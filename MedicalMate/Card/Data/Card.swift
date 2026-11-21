import Foundation

/// 브리핑 카드 목록의 한 줄.
///
/// **카드와 아직 카드가 되지 않은 문답이 한 목록에 선다**(1j-4). 둘은 들어가는 곳이
/// 다르다 — 카드는 카드 화면으로, 문답은 하던 자리로 이어진다.
struct CardListItem: Sendable, Identifiable, Equatable {
    enum Kind: Sendable, Equatable {
        /// 만들어진 카드.
        case card(id: Int64, visited: Bool)
        /// 아직 카드가 아닌 문답. `tempSaved`면 질문 고르기까지 마친 것이다.
        case openIntake(sessionId: Int64, tempSaved: Bool, step: Int, total: Int)
        /// 진료를 마친 기록(1j-1). 카드가 아니라 진료 후 기록으로 들어간다.
        case visit(id: Int64, cardId: Int64?)
    }

    let kind: Kind
    let title: String
    /// "09.04 작성 · 서울OO병원 내과" · "오늘 · 3단계 중 2단계".
    let meta: String
    /// 셋째 줄. 카드는 담긴 항목, 문답은 "이어서 정리하기".
    let summary: String?
    /// 이 카드에 적힌 병원. **일정 추가가 빈 병원 칸을 이것으로 채운다**(`1r-4-B`).
    /// 메타 줄에서 되읽지 않는다 — 거기에는 "병원 미정"이 섞여 있다.
    let clinic: String?
    /// 묶이는 달. "2026년 9월".
    let month: String
    let writtenOn: Date

    var id: String {
        switch kind {
        case .card(let id, _): "card-\(id)"
        case .openIntake(let sessionId, _, _, _): "intake-\(sessionId)"
        case .visit(let id, _): "visit-\(id)"
        }
    }

    /// 제목 옆 배지.
    ///
    /// **네 가지다**(FEATURE-SPEC 2.4) — 작성 중 · 임시 저장 · 진료 전 · 진료 완료.
    /// "진료 완료"는 `visited`로 판단한다. 병원명은 선택 입력이라 진료를 마쳤어도
    /// 비어 있을 수 있어서 그것으로 판단하면 안 된다.
    var badge: (text: String, tone: MMBadge.Tone) {
        switch kind {
        case .card(_, let visited):
            visited ? ("진료 완료", .success) : ("진료 전", .brand)
        case .openIntake(_, let tempSaved, _, _):
            tempSaved ? ("임시 저장", .warning) : ("작성 중", .neutral)
        case .visit:
            ("진료 완료", .success)
        }
    }

    var summaryTone: MMListRow.SummaryTone {
        switch kind {
        case .card, .visit: .subtle
        // 이어서 할 것은 눈에 띄어야 한다.
        case .openIntake: .warning
        }
    }

    var isCard: Bool {
        if case .card = kind { return true }
        return false
    }
}

/// 달로 묶은 한 덩이.
struct CardMonthSection: Sendable, Identifiable, Equatable {
    var id: String { month }
    let month: String
    var items: [CardListItem]
}
