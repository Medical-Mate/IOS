import Foundation

/// 한 갈래의 요청·응답 모양. `{"status": "KNOWN", "items": [...]}`.
struct ListFieldDTO: Codable, Sendable {
    var status: String
    var items: [String]

    init(_ field: HealthField) {
        self.status = field.status.rawValue
        self.items = field.items
    }

    var field: HealthField {
        HealthField(items: items, status: HealthStatus(rawValue: status) ?? .unknown)
    }
}

struct HealthProfileResponse: Decodable, Sendable {
    let name: String?
    let birthYear: Int?
    let birthMonthDay: String?
    let sex: String?
    let medications: ListFieldDTO?
    let conditions: ListFieldDTO?
    let allergies: ListFieldDTO?
    let onboardingCompleted: Bool?
    let canStartIntake: Bool?

    var profile: HealthProfile {
        HealthProfile(
            name: name,
            birthYear: birthYear,
            birthMonthDay: birthMonthDay,
            sex: sex,
            health: HealthEdit(
                medications: medications?.field ?? HealthField(),
                conditions: conditions?.field ?? HealthField(),
                allergies: allergies?.field ?? HealthField()
            ),
            onboardingCompleted: onboardingCompleted ?? false,
            canStartIntake: canStartIntake ?? false
        )
    }
}

/// 저장 요청. **카카오에서 온 값도 그대로 되돌려 보낸다.**
struct HealthProfileRequest: Encodable, Sendable {
    let name: String?
    let birthYear: Int?
    let birthMonthDay: String?
    let sex: String?
    let medications: ListFieldDTO
    let conditions: ListFieldDTO
    let allergies: ListFieldDTO

    init(profile: HealthProfile) {
        self.name = profile.name
        self.birthYear = profile.birthYear
        self.birthMonthDay = profile.birthMonthDay
        self.sex = profile.sex
        self.medications = ListFieldDTO(profile.health.medications)
        self.conditions = ListFieldDTO(profile.health.conditions)
        self.allergies = ListFieldDTO(profile.health.allergies)
    }
}
