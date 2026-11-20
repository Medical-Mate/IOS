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
        let chiefComplaint: String?
        let clinicName: String?
        let visited: Bool?
        let createdAt: String?
    }

    struct Appointment: Decodable, Sendable {
        let appointmentId: Int64
        let date: String?
        let time: String?
        let clinicName: String?
        let department: String?
        let purpose: String?
    }

    struct OpenIntake: Decodable, Sendable {
        let sessionId: Int64
        let progressCurrent: Int?
        let progressTotal: Int?
    }

    let recentCards: [Card]?
    let upcomingAppointment: Appointment?
    let openIntake: OpenIntake?
}
