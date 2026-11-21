import Foundation
import Testing
@testable import MedicalMate

/// I 섹션 — 내 정보 · 건강 정보 수정 · 알림 시간의 규칙.
struct MyProfileTests {
    // MARK: - 1s-1 내 정보

    @Test func 아바타는_이름의_첫_글자다() {
        #expect(MyProfileModel.initial("김OO") == "김")
    }

    @Test func 이름이_없으면_아바타_글자도_없다() {
        // 카카오 동의를 거부한 계정은 이름이 빈 채로 온다. 아무 글자나 채우면 그것이
        // 이름의 첫 자로 읽힌다 — 빈 동그라미로 둔다.
        #expect(MyProfileModel.initial(nil).isEmpty)
        #expect(MyProfileModel.initial("  ").isEmpty)
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

    @MainActor
    @Test func 직접_추가를_다시_누르면_닫는다() {
        // 열어 둔 것을 닫을 길이 없으면 적다 만 입력 칸이 화면에 남는다.
        let model = HealthEditModel(repository: HealthProfileRepository(client: AppEnvironment().client))
        model.startAdding(0)
        #expect(model.adding == 0)
        model.startAdding(0)
        #expect(model.adding == nil)
        model.startAdding(1)
        #expect(model.adding == 1)
    }

    @MainActor
    @Test func 이미_있는_항목은_칩을_두_번_세우지_않는다() {
        let model = HealthEditModel(repository: HealthProfileRepository(client: AppEnvironment().client))
        model.startAdding(0)
        // 1b의 기본 목록에 있는 말이다.
        model.draft = "혈압약"
        model.commitDraft()
        #expect(model.draft.isEmpty)
        // 칸은 열어 둔 채로 둔다.
        #expect(model.adding == 0)
        #expect(model.options(0).filter { $0 == "혈압약" }.count == 1)
    }
}

/// 건강 정보 수정(`1s-2`)에서 직접 적어 넣는 자리.
struct HealthEditDraftTests {
    @Test func 앞서_적어_넣은_것과_같으면_줄을_더하지_않는다() {
        // 같은 줄이 두 번 서지 않는다. 고른 것으로만 표시된다.
        #expect(HealthEditModel.isNew("메밀", extras: []))
        #expect(!HealthEditModel.isNew("메밀", extras: ["메밀"]))
        #expect(HealthEditModel.isNew("메밀", extras: ["땅콩"]))
    }
}
