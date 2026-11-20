import Foundation

/// 응답을 화면 값으로 옮긴다.
///
/// **한 곳에 모았다.** 서버가 카드 본문을 고정 필드에서 `axes` 맵으로 바꿨을 때 Android가
/// 고친 곳은 이 자리뿐이었다 — 화면과 모델은 그대로였다.
enum BriefCardMapping {
    /// 카드에서 읽는 차례. **SOCRATES 8축**이고 강도는 빠진다(눈금으로 그린다).
    ///
    /// 서버가 준 순서가 아니라 이 차례다. 맵이라 순서가 보장되지 않고, 카드에서 부위가
    /// 먼저 오는 것은 읽는 차례의 문제다.
    static let axisOrder = [
        "site",
        "onset",
        "character",
        "radiation",
        "associated",
        "time_course",
        "exacerbating_relieving",
    ]

    static let severityAxis = "severity"

    /// 축 이름.
    ///
    /// 서버 계약에 묶인 값이라 화면 카피와 성격이 다르다. 모르는 축은 id를 그대로 보인다 —
    /// 서버가 축을 늘려도 줄이 사라지지 않게.
    ///
    /// **`onset`을 "기간"이라고 적는다.** Android는 "시작"인데 1e-1의 마스터가 "기간"이고
    /// 값도 "3주 전 시작 · 최근 악화"라 기간으로 읽힌다. 화면 문구는 Figma를 따른다 —
    /// COMPONENT-MAP 3장 14번.
    static func label(for axis: String) -> String {
        switch axis {
        case "site": "부위"
        case "onset": "기간"
        case "character": "양상"
        case "radiation": "뻗치는 곳"
        case "associated": "동반증상"
        case "time_course": "경과"
        case "exacerbating_relieving": "심해질 때"
        case "severity": "강도"
        default: axis
        }
    }

    static let unknownLabel = "잘 모르겠어요"
    static let ambiguousSuffix = "(확실하지 않아요)"

    // MARK: - 카드

    static func card(from response: CardResponse, calendar: Calendar = .current) -> BriefCard {
        BriefCard(
            id: response.cardId,
            title: (response.title ?? response.chiefComplaint) ?? "",
            patientLine: patientLine(response, calendar: calendar),
            maskedPatientLine: maskedPatientLine(response, calendar: calendar),
            items: items(from: response.axes) + healthRows(response.patient),
            severity: severity(from: response.axes?[severityAxis]),
            allergies: allergies(response.patient?.allergies),
            questions: response.questions ?? [],
            hospital: hospital(from: response.clinic),
            appointment: appointment(from: response.appointment),
            status: response.status,
            visited: response.visited ?? false
        )
    }

    /// 축을 KV 줄로 편다.
    ///
    /// **아직 묻지 않은 축은 줄을 만들지 않는다.** 8축이 늘 자리를 차지하고 1턴째는
    /// 대부분 `NOT_ASKED`라, 그대로 그리면 빈 줄 여덟 개가 먼저 보인다. 건너뛴 축도 같다 —
    /// 환자가 넘어가기로 한 것을 카드에 남길 이유가 없다.
    ///
    /// `UNKNOWN`("잘 모르겠다")은 **남긴다.** 확인하지 못했다는 것이 의사에게는 정보다.
    /// `AMBIGUOUS`는 값이 있어도 확실하지 않다는 뜻이라 그 사실을 함께 적는다.
    static func items(from axes: [String: AxisResponse]?) -> [BriefCardItem] {
        guard let axes else { return [] }
        return axisOrder.compactMap { axis in
            guard let field = axes[axis], let value = value(of: field) else { return nil }
            return BriefCardItem(key: label(for: axis), value: value, axis: axis)
        }
    }

    private static func value(of field: AxisResponse) -> String? {
        switch field.status {
        case "FILLED": field.value ?? ""
        case "UNKNOWN": unknownLabel
        case "AMBIGUOUS": field.value.map { "\($0) \(ambiguousSuffix)" } ?? unknownLabel
        default: nil
        }
    }

    /// 강도 축을 눈금으로.
    ///
    /// 값이 "3 (꽤 아파요)"처럼 숫자와 낱말이 함께 온다. **앞의 숫자만 읽는다** — 낱말은
    /// 화면이 단계에서 가져오고, 문자열을 맞춰 보면 서버가 표현을 바꿀 때마다 갈린다.
    /// 1~5 밖이거나 숫자가 없으면 그리지 않는다.
    static func severity(from field: AxisResponse?) -> Int? {
        guard let field, field.status == "FILLED", let text = field.value else { return nil }
        let digits = text.drop { !$0.isNumber }.prefix { $0.isNumber }
        guard let level = Int(digits), (1...5).contains(level) else { return nil }
        return level
    }

    // MARK: - 건강 정보

    /// 카드 안에 줄로 서는 건강 정보. **복용약과 기저질환만이다** — 알러지는 카드 밖
    /// 경고로 따로 간다.
    ///
    /// **적은 것이 없으면 줄을 만들지 않는다.** "없어요"와 "잘 모르겠어요"를 카드에 적지
    /// 않는다. 비어 있다는 사실은 그 자리에 아무것도 없는 것으로 충분히 전해진다.
    static func healthRows(_ patient: PatientResponse?) -> [BriefCardItem] {
        [
            row(patient?.medications, key: "복용약"),
            row(patient?.conditions, key: "기저질환"),
        ].compactMap(\.self)
    }

    private static func row(_ field: CardListFieldResponse?, key: String) -> BriefCardItem? {
        let items = field?.items ?? []
        guard isKnown(field?.status, hasValue: !items.isEmpty), !items.isEmpty else { return nil }
        return BriefCardItem(key: key, value: items.joined(separator: " · "), axis: nil)
    }

    /// 알러지 한 줄을 칩으로 나눈다. 저장할 때 쉼표로 이어 보낸 그대로 온다.
    static func allergies(_ field: CardTextFieldResponse?) -> [String] {
        let items = (field?.text ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return isKnown(field?.status, hasValue: !items.isEmpty) ? items : []
    }

    /// 적어 둔 것이 있다고 볼지.
    ///
    /// **서버가 상태를 빼고 보낼 때가 있다** — `{"items":[]}`처럼. 그때 상태만 보고
    /// 자르면 값이 있는데도 줄이 사라진다. **값이 있으면 있는 것으로 본다.**
    private static func isKnown(_ status: String?, hasValue: Bool) -> Bool {
        guard let status else { return hasValue }
        return status == "KNOWN"
    }

    // MARK: - 머리 줄

    /// "김OO · 32세 여 · 2026.09.18 작성".
    static func patientLine(_ response: CardResponse, calendar: Calendar) -> String {
        [
            response.patient?.name,
            response.patient?.age.map { age in
                "\(age)세 \(sexLabel(response.patient?.sex))".trimmingCharacters(in: .whitespaces)
            },
            writtenOn(response.createdAt, calendar: calendar),
        ].compactMap(\.self).joined(separator: " · ")
    }

    /// 이름·나이를 가린 줄. "김OO · 여 · 2026.09.18 작성".
    ///
    /// 이름은 **성만 남긴다**. 나이는 뺀다 — 숫자를 바꿔 적으면 틀린 정보가 찍힌다.
    static func maskedPatientLine(_ response: CardResponse, calendar: Calendar) -> String {
        let name = response.patient?.name.flatMap { value -> String? in
            guard let first = value.first else { return nil }
            return "\(first)\(nameMask)"
        }
        let sex = sexLabel(response.patient?.sex)
        return [
            name,
            sex.isEmpty ? nil : sex,
            writtenOn(response.createdAt, calendar: calendar),
        ].compactMap(\.self).joined(separator: " · ")
    }

    /// 가린 이름에서 성 뒤에 붙는 글자. 서버가 가릴 때와 같은 모양이다.
    static let nameMask = "OO"

    private static func sexLabel(_ sex: String?) -> String {
        switch sex {
        case "FEMALE": "여"
        case "MALE": "남"
        default: ""
        }
    }

    private static func writtenOn(_ createdAt: String?, calendar: Calendar) -> String? {
        guard let date = createdAt.flatMap(HomeRepository.date(from:)) else { return nil }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }
        return String(format: "%d.%02d.%02d 작성", year, month, day)
    }

    // MARK: - 편집

    /// 고친 축만 간다.
    ///
    /// **지운 줄은 빈 값으로 보낸다** — 서버에 "줄을 지운다"는 요청이 없고, 값을 비우면
    /// 축이 `UNKNOWN`으로 내려와 줄이 사라진다. 축이 없는 줄(복용약 · 기저질환)은
    /// 보낼 곳이 없어 건너뛴다.
    static func changedAxes(from original: [BriefCardItem], to edited: [BriefCardItem]) -> [AxisEditRequest]? {
        var requests: [AxisEditRequest] = []
        for item in original {
            guard let axis = item.axis else { continue }
            let now = edited.first { $0.axis == axis }
            let value = now?.value ?? ""
            if value != item.value {
                requests.append(AxisEditRequest(axis: axis, value: value))
            }
        }
        return requests.isEmpty ? nil : requests
    }

    /// 빈 줄은 보내지 않는다. 질문 추가로 열어 두고 안 적은 칸이다.
    static func cleaned(_ questions: [String]) -> [String] {
        questions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - 병원 · 일정

    /// **이름이 없으면 없는 것으로 본다.** 안 골랐을 때 서버가 빈 객체를 줄 수 있고,
    /// 이름 없는 병원 블록은 그릴 것이 없다.
    static func hospital(from clinic: ClinicResponse?) -> BriefCardHospital? {
        guard let name = clinic?.name, !name.isEmpty else { return nil }
        let address = clinic?.address
        return BriefCardHospital(name: name, address: (address?.isEmpty == false) ? address : nil)
    }

    static func appointment(from response: CardAppointmentResponse?) -> BriefCardAppointment? {
        guard let response, let date = HomeRepository.date(from: response.scheduledOn) else { return nil }
        return BriefCardAppointment(id: response.appointmentId, date: date, clinicName: response.clinicName)
    }

    /// 하단 버튼을 고른다. **당일은 진료를 다녀왔을 수 있어 기록하기다.**
    static func footerAction(for card: BriefCard, today: Date, calendar: Calendar) -> BriefCardFooterAction {
        guard let date = card.appointment?.date else { return .schedule }
        let day = calendar.startOfDay(for: date)
        let now = calendar.startOfDay(for: today)
        return day > now ? .viewSchedule : .recordVisit
    }
}
