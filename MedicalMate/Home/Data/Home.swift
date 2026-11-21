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
    /// 맨 위 배너를 가르는 데 쓰는 값.
    var lead: HomeLeadInput = HomeLeadInput()

    var isEmpty: Bool {
        recentCards.isEmpty && upcoming == nil && openIntake == nil
    }
}

/// 배너 첫 장을 가르는 재료.
///
/// **꾸민 글이 아니라 값이다.** 어떤 배너를 세울지는 `HomeLead`가 정하고, 그 판단에
/// 필요한 것만 담는다.
struct HomeLeadInput: Sendable, Equatable {
    /// 마지막 진료일. 없으면 아직 진료 기록이 없는 사람이다.
    var lastVisitedOn: Date?
    /// 다음 일정 날짜.
    var nextOn: Date?
    /// 다음 일정의 시각. 없으면 시간 미정이다.
    var nextTime: String?
    /// "서울OO병원 내과"처럼 합친 이름.
    var nextClinicLabel: String?
    /// 일정에 등록한 병원 이름. 비어 있으면 병원 찾기부터 간다.
    var nextClinicName: String?
    /// 다음 일정에 붙은 첫 카드.
    var nextCard: (id: Int64, title: String)?

    static func == (lhs: HomeLeadInput, rhs: HomeLeadInput) -> Bool {
        lhs.lastVisitedOn == rhs.lastVisitedOn && lhs.nextOn == rhs.nextOn
            && lhs.nextTime == rhs.nextTime && lhs.nextClinicLabel == rhs.nextClinicLabel
            && lhs.nextClinicName == rhs.nextClinicName
            && lhs.nextCard?.id == rhs.nextCard?.id && lhs.nextCard?.title == rhs.nextCard?.title
    }
}

/// 배너 첫 장이 무엇을 말할지. Figma `Home Banner`의 `Banner=1` 네 갈래다.
///
/// 규칙은 `docs/FEATURE-SPEC.md` 2.9이고 Android `HomeLead`와 같다.
enum HomeLead: Sendable, Equatable {
    /// 카드도 일정도 진료도 없는 사람(`1n-2`).
    case firstVisit
    /// 오늘 카드가 걸린 진료가 있고 **아직 기록하지 않았다**(`1n-1`).
    case todayVisit(clinic: String?, cardId: Int64, cardTitle: String, clinicName: String?)
    /// 내일 카드가 걸린 진료가 있다(`1n-1-4`).
    case tomorrowVisit(time: String?, clinic: String?, cardId: Int64)
    /// 가장 최근 카드가 아직 진료 전이고 **그 카드로 잡은 일정이 없다**(`1n-1-5`).
    case cardReady(cardId: Int64, symptom: String)
    /// 그 밖. 배너 2~5 자리인데 사진을 못 받아 한 장으로 둔다.
    case other
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
    /// 어디가 아프다고 했는지. `Card / Resume`의 아랫줄이 이것으로 시작한다.
    var siteText: String = ""
    /// 질문 고르기에서 "다음"까지 눌렀는지. **서버가 주는 값을 그대로 든다** —
    /// 진행도가 끝에 닿았는지로 짐작하면 안 된다. 3/3은 AI 문답이 끝난 것이고,
    /// 거기서 질문을 고르다 나간 사람도 3/3이다(`HomeDTO`가 못박아 둔 자리다).
    var questionsConfirmed: Bool = false
    /// 어디까지 왔는지. 증상 정리는 세 단계다.
    let step: Int
    let total: Int
}
