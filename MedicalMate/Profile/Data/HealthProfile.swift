import Foundation

/// 한 갈래의 답.
///
/// **비어 있는 것을 "없다"로 보지 않는다.** 서버는 `NONE`("없다")과 `UNKNOWN`("모른다")을
/// 가르는데 화면에는 그 둘을 말할 자리가 없다. 아무것도 고르지 않고 넘어간 것이
/// "없어요"인지 "그냥 넘겼어요"인지 알 수 없어서 ``HealthStatus/unknown``으로 보낸다.
/// **알러지에서 "없음"과 "모름"은 처방이 달라지는 값이라 단정하면 안 된다.**
///
/// Android도 같은 자리에서 같은 판단을 했고, 그쪽은 디자인 트랙에 "없어요 · 모르겠어요"
/// 보조 버튼을 요청해 둔 상태다.
struct HealthField: Sendable, Equatable {
    var items: [String] = []
    var status: HealthStatus = .unknown

    init(items: [String] = [], status: HealthStatus? = nil) {
        self.items = items
        self.status = status ?? (items.isEmpty ? .unknown : .known)
    }
}

/// 서버가 가르는 세 상태.
///
/// **"없다"를 `none`이 아니라 `absent`로 둔다.** Swift에서 `.none`은 `Optional.none`과
/// 이름이 겹쳐서, `HealthField(items: [], status: .none)`이라고 적으면 `nil`로 해석돼
/// 조용히 `unknown`이 된다. 알러지에서 "없음"과 "모름"은 처방이 달라지는 값이라
/// 그렇게 틀릴 수 있는 이름을 두지 않는다. 서버로 가는 글자는 `NONE` 그대로다.
enum HealthStatus: String, Sendable, Codable {
    case known = "KNOWN"
    case absent = "NONE"
    case unknown = "UNKNOWN"
}

/// 화면이 고치는 세 갈래.
struct HealthEdit: Sendable, Equatable {
    var medications = HealthField()
    var conditions = HealthField()
    var allergies = HealthField()
}

/// 서버에 있는 건강 프로필.
///
/// `name` · `birthYear` · `sex`는 카카오에서 온다. **저장할 때 그대로 되돌려 보내야 해서
/// 화면이 쓰지 않아도 들고 있는다.**
struct HealthProfile: Sendable, Equatable {
    var name: String?
    var birthYear: Int?
    var birthMonthDay: String?
    var sex: String?
    var health = HealthEdit()
    var onboardingCompleted = false
    var canStartIntake = false
}
