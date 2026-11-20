import Foundation

/// `GET /api/cards/{cardId}`.
struct CardResponse: Decodable, Sendable {
    let cardId: Int64
    let status: String?
    let patient: PatientResponse?
    /// **아직 서버가 내려주지 않는다.** 제목은 `chiefComplaint`를 쓴다.
    let title: String?
    let chiefComplaint: String?
    /// SOCRATES 8축. **없는 축을 만들지 않고 늘 자리를 차지한다.**
    let axes: [String: AxisResponse]?
    let questions: [String]?
    let visited: Bool?
    let createdAt: String?
    /// 진료받을 병원. **응답에 병원이 셋이고 이것만 쓴다** — `appointment`는 일정의
    /// 병원이고 진료를 받은 병원은 또 다르다. 셋이 다 다를 수 있다.
    let clinic: ClinicResponse?
    /// 이 카드로 잡은 일정. 없으면 일정을 잡지 않은 카드다.
    let appointment: CardAppointmentResponse?
}

/// `status`는 `NOT_ASKED` · `FILLED` · `UNKNOWN` · `SKIPPED` · `AMBIGUOUS`.
struct AxisResponse: Decodable, Sendable {
    let status: String?
    let value: String?
}

struct ClinicResponse: Decodable, Sendable {
    let name: String?
    let address: String?
}

/// `scheduledOn`은 `yyyy-MM-dd`다.
struct CardAppointmentResponse: Decodable, Sendable {
    let appointmentId: Int64
    let scheduledOn: String
    let clinicName: String?
}

/// 카드 머리의 환자. **건강 정보가 여기 실린다** — 보는 시점이 아니라 **카드를 만든
/// 시점의 프로필**이 찍힌다.
struct PatientResponse: Decodable, Sendable {
    let name: String?
    let age: Int?
    let sex: String?
    let allergies: CardTextFieldResponse?
    let medications: CardListFieldResponse?
    let conditions: CardListFieldResponse?
}

/// `status`가 `KNOWN`일 때만 값이 있다. `NONE`은 없다고 답한 것, `UNKNOWN`은 모른다는 것.
struct CardTextFieldResponse: Decodable, Sendable {
    let status: String?
    let text: String?
}

struct CardListFieldResponse: Decodable, Sendable {
    let status: String?
    let items: [String]?
}

/// `PATCH /api/cards/{cardId}`. **보낸 필드만 바뀐다.**
///
/// 제목과 진료과는 고칠 수 없다. 서버가 받지 않는다.
struct UpdateCardRequest: Encodable, Sendable {
    var axes: [AxisEditRequest]?
    var questions: [String]?
    var clinic: ClinicRequest?
}

/// 고친 축 하나. 서버가 `{"axis":"onset","value":"3주 전"}`으로 받는다.
struct AxisEditRequest: Encodable, Sendable {
    let axis: String
    let value: String
}
