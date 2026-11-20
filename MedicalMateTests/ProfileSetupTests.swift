import Testing
@testable import MedicalMate

/// 신상정보 3단계가 와이어프레임의 내용을 그대로 들고 있는지, 그리고 비어 있는 갈래를
/// "없다"로 단정하지 않는지 본다.
struct ProfileSetupTests {
    @Test("세 단계의 질문이 와이어프레임과 같다 (3663:6919 · 6938 · 6957)")
    func questions() {
        #expect(ProfileSetupStep.all.count == 3)
        #expect(ProfileSetupStep.all[0].question == "지금 드시는 약이 있나요?")
        #expect(ProfileSetupStep.all[1].question == "진단받은 병이 있나요?")
        #expect(ProfileSetupStep.all[2].question == "알러지가 있나요?")
    }

    @Test("칩 목록이 와이어프레임과 같다 (3663:6926 · 6945 · 6986)")
    func options() {
        #expect(ProfileSetupStep.all[0].options == ["혈압약", "당뇨약", "진통제", "위장약", "영양제", "한약", "피임약", "수면제"])
        #expect(ProfileSetupStep.all[1].options == ["고혈압", "당뇨", "고지혈증", "천식", "갑상선", "위염·역류", "관절염", "우울·불안"])
        #expect(ProfileSetupStep.all[2].options == ["페니실린", "아스피린", "조개·갑각류", "땅콩", "계란", "꽃가루", "먼지·진드기"])
    }

    @Test("툴팁은 알러지 단계에만 있다 (3663:6977)")
    func tooltip() {
        #expect(ProfileSetupStep.all[0].tooltip == nil)
        #expect(ProfileSetupStep.all[1].tooltip == nil)
        #expect(ProfileSetupStep.all[2].tooltip == "브리핑 카드 맨 위에 항상 표시돼요")
    }

    @Test("비어 있는 갈래는 UNKNOWN이다. NONE으로 단정하지 않는다")
    func emptyIsUnknown() {
        // 알러지에서 "없음"과 "모름"은 처방이 달라지는 값이다. 화면에 그 둘을 말할
        // 자리가 없으므로 아무것도 고르지 않은 것을 "없다"로 보내면 안 된다.
        #expect(HealthField().status == .unknown)
        #expect(HealthField(items: []).status == .unknown)
        #expect(HealthField(items: ["페니실린"]).status == .known)
    }

    @Test("서버가 말한 상태는 그대로 들고 있는다")
    func serverStatusKept() {
        // 서버에 NONE으로 있던 갈래를 손대지 않고 읽으면 NONE이어야 한다.
        // 케이스 이름이 `absent`인 이유는 `.none`이 Optional.none으로 해석되기 때문이다.
        #expect(HealthField(items: [], status: .absent).status == .absent)
        #expect(ListFieldDTO(HealthField(items: [], status: .absent)).status == "NONE")
        #expect(HealthStatus.absent.rawValue == "NONE")
    }

    @Test("저장 요청은 카카오에서 온 값도 되돌려 보낸다")
    func requestKeepsIdentity() {
        var profile = HealthProfile()
        profile.name = "김OO"
        profile.birthYear = 1990
        profile.sex = "F"
        let request = HealthProfileRequest(profile: profile)
        #expect(request.name == "김OO")
        #expect(request.birthYear == 1990)
        #expect(request.sex == "F")
    }
}
