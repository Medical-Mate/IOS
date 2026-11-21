import Foundation

/// `GET /api/me/home` 응답.
///
/// **없는 값에 너그럽게 받는다.** 서버가 아직 다 내려주지 않는 자리가 있고, 홈은 한
/// 자리가 비어도 나머지를 보여야 하는 화면이다. 계약이 어긋난 것과 값이 없는 것은
/// 다르다 — 모양이 틀리면 디코딩이 터지고, 값이 없으면 그 줄만 빠진다.
struct HomeResponse: Decodable, Sendable {
    struct Card: Decodable, Sendable {
        let cardId: Int64
        let title: String?
        /// 주 호소. 배너가 "복부 통증 카드가 기다리고 있어요"라고 부를 때 쓴다.
        let chiefComplaint: String?
        let status: String?
        let clinicName: String?
        let visited: Bool?
        let createdAt: String?
    }

    /// 일정에 붙은 카드.
    struct LinkedCard: Decodable, Sendable {
        let cardId: Int64
        let title: String?
    }

    /// 다음 일정.
    ///
    /// **날짜와 시각이 따로 온다.** `scheduledTime`이 없으면 시간 미정이다. **카드도 한
    /// 장이 아니라 목록이다** — 전에는 `scheduledAt` 하나에 `cardId`였고, 서버가 모양을
    /// 바꾸면서 Android 홈이 죽었다. 캘린더 도메인이 쓰는 모양과 같다.
    struct Appointment: Decodable, Sendable {
        let appointmentId: Int64
        let clinicName: String?
        let department: String?
        let purpose: String?
        let scheduledOn: String
        let scheduledTime: String?
        let status: String?
        let origin: String?
        let cards: [LinkedCard]?
    }

    /// 임시저장된 문답. **진행도가 숫자 둘로 온다** — 서버가 문자열을 만들지 않는다.
    struct InProgressSession: Decodable, Sendable {
        let sessionId: Int64
        let siteText: String?
        let progressCurrent: Int?
        let progressTotal: Int?
        /// 질문 고르기에서 "다음"을 눌렀는지. 눌렀으면 세 단계를 다 마치고 카드를 만들기
        /// 전인 "임시 저장"이다. **서버의 `ended`로 가르지 않는다** — 그것은 AI 채팅이
        /// 끝난 순간이라 질문 고르기 도중에 나간 문답도 참이다.
        let questionsConfirmed: Bool?
    }

    /// 마지막 진료일. 없으면 아직 진료 기록이 없는 사람이다.
    let lastVisitedOn: String?
    let nextAppointment: Appointment?
    /// 진료 후 기록이 아직 없는 지난 일정 가운데 가장 최근 날.
    ///
    /// 서버가 일정 날짜로 남긴 기록이 있는지를 보고 14일까지만 거슬러 찾으며, 취소한
    /// 일정은 세지 않는다. **일정과 기록을 잇는 열쇠가 없어서** — 기록은 카드에 붙는데
    /// 일정은 카드 없이도 만들 수 있다 — 날짜로 견주는 것이 서버가 할 수 있는 전부다.
    let pendingRecordOn: String?
    let inProgressSession: InProgressSession?
    let recentCards: [Card]?
}

/// `GET /api/cards/{cardId}` 가운데 **홈이 보는 것만.**
///
/// 일정이 걸렸는지만 알면 된다. 카드 도메인의 응답 타입을 쓰지 않는 이유는 한 도메인이
/// 다른 도메인을 직접 참조하지 않기 때문이다 — Android도 홈에 따로 두었다.
struct HomeCardProbe: Decodable, Sendable {
    /// 카드에 잡힌 일정. **안 지난 것 중 가장 가까운 것**, 다 지났으면 가장 최근 것이다.
    struct Appointment: Decodable, Sendable {
        let appointmentId: Int64
        let scheduledOn: String
    }

    let cardId: Int64
    let appointment: Appointment?
}
