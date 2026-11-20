import Foundation

/// 홈 한 화면이 쓰는 것.
///
/// `GET /api/me/home` 한 번으로 채운다. 화면이 더 필요하면 그때 따로 읽는다 —
/// 예컨대 "그 카드로 잡은 일정이 있는지"는 홈 응답에 없어서 카드를 한 번 더 읽어야 한다.
struct HomeSummary: Sendable, Equatable {
    var recentCards: [HomeCard] = []
    var upcoming: HomeSchedule?
    /// 아직 카드를 만들지 않은 문답. 있으면 "이어서 하기"가 선다.
    var openIntake: HomeOpenIntake?

    var isEmpty: Bool {
        recentCards.isEmpty && upcoming == nil && openIntake == nil
    }
}

/// 홈의 최근 브리핑 카드 한 줄.
///
/// **"작성 중"은 여기 오지 않는다.** 카드는 만들 때부터 확정돼 있어서 홈에 서는 것은
/// 진료 전 · 진료 완료 둘이다.
struct HomeCard: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    /// "2026.09.04 · 서울OO병원 내과".
    let meta: String
    let visited: Bool

    var badge: (text: String, tone: MMBadge.Tone)? {
        visited ? ("진료 완료", .success) : ("진료 전", .brand)
    }

    static func == (lhs: HomeCard, rhs: HomeCard) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.meta == rhs.meta && lhs.visited == rhs.visited
    }
}

/// 다가오는 일정 하나.
struct HomeSchedule: Sendable, Equatable {
    let id: Int64
    let month: String
    let day: String
    /// "서울OO병원 · 금 오전 10:30".
    let meta: String
    /// "내과 재진". 서버가 제목을 주지 않아 앱이 병원·진료과·목적을 조합한다.
    let title: String
    let dday: String?
}

/// 이어서 할 문답.
struct HomeOpenIntake: Sendable, Equatable {
    let sessionId: Int64
    /// 어디까지 왔는지. 증상 정리는 세 단계다.
    let step: Int
    let total: Int
}
