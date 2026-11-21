import Foundation
import Testing
@testable import MedicalMate

/// I 섹션 — 내 정보 · 건강 정보 수정 · 알림 시간의 규칙.
struct MyProfileTests {
    // MARK: - 1s-1 내 정보

    @Test func 아바타는_이름의_첫_글자다() {
        #expect(MyProfileModel.initial("김OO") == "김")
    }

    @Test func 이름이_없으면_나로_적는다() {
        // 카카오 동의를 거부한 계정은 이름이 빈 채로 온다.
        #expect(MyProfileModel.initial(nil) == "나")
        #expect(MyProfileModel.initial("  ") == "나")
    }

    @Test func 생년과_성별을_한_줄로_묶는다() {
        #expect(MyProfileModel.birthLine(year: 1994, sex: "FEMALE") == "1994년생 · 여")
        #expect(MyProfileModel.birthLine(year: 1994, sex: "MALE") == "1994년생 · 남")
    }

    @Test func 밝히지_않은_성별은_적지_않는다() {
        // "밝히지 않음"을 적을 자리가 시안에 없다.
        #expect(MyProfileModel.birthLine(year: 1994, sex: "UNSPECIFIED") == "1994년생")
        #expect(MyProfileModel.birthLine(year: nil, sex: nil).isEmpty)
    }

    @Test func 건강_정보가_비어도_까닭을_적는다() {
        // "없어요"와 "잘 모르겠어요"는 처방이 달라지는 값이라 뭉개지 않는다.
        #expect(MyProfileModel.summary(HealthField(items: ["혈압약", "진통제"])) == "혈압약 · 진통제")
        #expect(MyProfileModel.summary(HealthField(items: [], status: .absent)) == "없어요")
        #expect(MyProfileModel.summary(HealthField(items: [], status: .unknown)) == "잘 모르겠어요")
    }

    @Test func 토글_설명이_정한_시각을_그대로_적는다() {
        let time = ReminderTime(hour: 7, minute: 30)
        #expect(MyProfileModel.beforeVisitDescription(time) == "확정시 24시간 전, 미정이면 전날 오전 7시 30분")
        #expect(MyProfileModel.afterVisitDescription(time) == "진료 2시간 뒤, 미정이면 당일 오전 7시 30분")
    }

    // MARK: - 알림 시각

    @Test func 서버의_HH_mm을_읽는다() {
        #expect(ReminderTime.parse("19:00") == ReminderTime(hour: 19, minute: 0))
        #expect(ReminderTime.parse("07:30:00") == ReminderTime(hour: 7, minute: 30))
    }

    @Test func 못_읽으면_서버_기본값인_오후_7시로_본다() {
        // 알림 하나 때문에 설정 전체를 잃지 않는다.
        #expect(ReminderTime.parse(nil) == .default)
        #expect(ReminderTime.parse("25:00") == .default)
        #expect(ReminderTime.parse("저녁") == .default)
    }

    @Test func 정오와_자정은_12시로_적는다() {
        #expect(ReminderTime(hour: 0, minute: 0).value == "오전 12:00")
        #expect(ReminderTime(hour: 12, minute: 0).value == "오후 12:00")
    }

    @Test func 값과_말은_표기가_다르다() {
        let time = ReminderTime(hour: 19, minute: 0)
        #expect(time.value == "오후 7:00")
        #expect(time.words == "오후 7시")
        #expect(ReminderTime(hour: 19, minute: 30).words == "오후 7시 30분")
        #expect(time.wire == "19:00")
    }

    @Test func 안내는_전날과_당일_둘_다를_적는다() {
        let hint = ReminderTimeModel.hint(ReminderTime(hour: 19, minute: 0), day: 5)
        #expect(hint == "5일 진료라면 4일 · 5일 오후 7:00에 알려요")
    }

    // MARK: - 1s-2 건강 정보 수정

    @Test func 목록에_없이_저장돼_있던_것도_칩으로_세운다() {
        // 1b에서 직접 적은 "한방차"가 여기서 사라지면 저장할 때 지워진다.
        #expect(HealthEditModel.extras(["혈압약", "한방차"], step: 0) == ["한방차"])
    }

    @Test func 보내는_차례는_보이는_차례다() {
        // Set은 순서가 없어 저장할 때마다 카드의 항목 차례가 흔들린다.
        let field = HealthEditModel.field(["진통제", "혈압약"], step: 0, extras: [])
        #expect(field.items == ["혈압약", "진통제"])
        #expect(field.status == .known)
    }

    @Test func 아무것도_고르지_않은_것을_없다로_보지_않는다() {
        let field = HealthEditModel.field([], step: 2, extras: [])
        #expect(field.items.isEmpty)
        #expect(field.status == .unknown)
    }
}
