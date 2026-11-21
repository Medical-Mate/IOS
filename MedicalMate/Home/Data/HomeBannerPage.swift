import Foundation

/// 홈 맨 위 사진 배너 한 장. Figma `Home Banner`(`Banner = 1`~`5`).
///
/// **첫 장만 상황에 따라 바뀌고 2~5장은 그대로다.** 처음 온 사람은 환영 한 장뿐이고
/// 넘기지 않는다(`1n-2` — 장 수도 링크도 없다). 규칙은 `docs/FEATURE-SPEC.md` 2.9이고
/// Android `HomeViewModel.banners()`와 같다.
enum HomeBannerPage: Sendable, Equatable, Identifiable {
    /// `Banner=1 · CTA=None`. 처음 온 사람.
    case welcome
    /// `Banner=1`. 오늘 진료 — "진료 후 기록하기".
    case today(clinic: String?, cardId: Int64, cardTitle: String, clinicName: String?)
    /// `Banner=1`. 내일 진료 — "카드 다시 보기".
    case tomorrow(time: String?, clinic: String?, cardId: Int64)
    /// `Banner=1`. 일정 없는 카드 — "진료 일정 잡기".
    case cardReady(cardId: Int64, symptom: String)
    /// `Banner=2`. 예약 문자.
    case message
    /// `Banner=3`. 일정 알림.
    case schedule
    /// `Banner=4`. 카드 이미지 저장. **카드가 없으면 목록으로 간다.**
    case saveCard(cardId: Int64?)
    /// `Banner=5`. 헤이 메이트.
    case mate

    var id: String {
        switch self {
        case .welcome: "welcome"
        case .today: "today"
        case .tomorrow: "tomorrow"
        case .cardReady: "cardReady"
        case .message: "message"
        case .schedule: "schedule"
        case .saveCard: "saveCard"
        case .mate: "mate"
        }
    }

    /// 2~5장. 차례가 고정이다.
    static func rest(latestCardId: Int64?) -> [HomeBannerPage] {
        [.message, .schedule, .saveCard(cardId: latestCardId), .mate]
    }

    /// 배너 다섯 장.
    ///
    /// **`.other`면 2~5장 가운데 하나를 첫 장에 올린다.** 어느 것을 올릴지는 화면이
    /// 살아 있는 동안 바뀌지 않아야 해서 고른 자리를 밖에서 들고 온다.
    static func pages(lead: HomeLead, latestCardId: Int64?, restIndex: Int) -> [HomeBannerPage] {
        let rest = rest(latestCardId: latestCardId)
        let first: HomeBannerPage
        switch lead {
        case .firstVisit:
            // 처음 온 사람은 한 장뿐이다. 넘길 것이 없다.
            return [.welcome]
        case .todayVisit(let clinic, let cardId, let cardTitle, let clinicName):
            first = .today(clinic: clinic, cardId: cardId, cardTitle: cardTitle, clinicName: clinicName)
        case .tomorrowVisit(let time, let clinic, let cardId):
            first = .tomorrow(time: time, clinic: clinic, cardId: cardId)
        case .cardReady(let cardId, let symptom):
            first = .cardReady(cardId: cardId, symptom: symptom)
        case .other:
            first = rest[min(max(restIndex, 0), rest.count - 1)]
        }
        return [first] + rest
    }

    /// 에셋 이름. **첫 장과 2~5장이 사진이 다르고, 첫 장의 네 갈래는 한 장을 같이 쓴다.**
    var photo: String {
        switch self {
        case .welcome: "home-banner-first"
        case .today, .tomorrow, .cardReady: "home-banner-today"
        case .message: "home-banner-message"
        case .schedule: "home-banner-schedule"
        case .saveCard: "home-banner-save"
        case .mate: "home-banner-mate"
        }
    }
}
