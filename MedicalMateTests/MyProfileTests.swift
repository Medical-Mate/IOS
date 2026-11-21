import Foundation
import Testing
@testable import MedicalMate

/// I 섹션 — 내 정보 · 건강 정보 수정 · 알림 시간의 규칙.
struct MyProfileTests {
    // MARK: - 1s-1 내 정보

    @Test("아바타는 이름의 첫 글자다")
    func avatarUsesFirstLetter() {
        #expect(MyProfileModel.initial("김OO") == "김")
    }

    @Test("이름이 없으면 아바타 글자도 없다")
    func avatarIsEmptyWithoutName() {
        // 카카오 동의를 거부한 계정은 이름이 빈 채로 온다. 아무 글자나 채우면 그것이
        // 이름의 첫 자로 읽힌다 — 빈 동그라미로 둔다.
        #expect(MyProfileModel.initial(nil).isEmpty)
        #expect(MyProfileModel.initial("  ").isEmpty)
    }

    @Test("생년과 성별을 한 줄로 묶는다")
    func birthLineJoinsYearAndSex() {
        #expect(MyProfileModel.birthLine(year: 1994, sex: "FEMALE") == "1994년생 · 여")
        #expect(MyProfileModel.birthLine(year: 1994, sex: "MALE") == "1994년생 · 남")
    }

    @Test("밝히지 않은 성별은 적지 않는다")
    func unspecifiedSexIsOmitted() {
        // "밝히지 않음"을 적을 자리가 시안에 없다.
        #expect(MyProfileModel.birthLine(year: 1994, sex: "UNSPECIFIED") == "1994년생")
        #expect(MyProfileModel.birthLine(year: nil, sex: nil).isEmpty)
    }

    @Test("건강 정보가 비어도 까닭을 적는다")
    func healthSummaryKeepsReason() {
        // "없어요"와 "잘 모르겠어요"는 처방이 달라지는 값이라 뭉개지 않는다.
        #expect(MyProfileModel.summary(HealthField(items: ["혈압약", "진통제"])) == "혈압약 · 진통제")
        #expect(MyProfileModel.summary(HealthField(items: [], status: .absent)) == "없어요")
        #expect(MyProfileModel.summary(HealthField(items: [], status: .unknown)) == "잘 모르겠어요")
    }

    @Test("토글 설명이 정한 시각을 그대로 적는다")
    func toggleDescriptionUsesChosenTime() {
        let time = ReminderTime(hour: 7, minute: 30)
        #expect(MyProfileModel.beforeVisitDescription(time) == "확정시 24시간 전, 미정이면 전날 오전 7시 30분")
        #expect(MyProfileModel.afterVisitDescription(time) == "진료 2시간 뒤, 미정이면 당일 오전 7시 30분")
    }

    // MARK: - 알림 시각

    @Test("서버의 HH mm을 읽는다")
    func parsesServerTime() {
        #expect(ReminderTime.parse("19:00") == ReminderTime(hour: 19, minute: 0))
        #expect(ReminderTime.parse("07:30:00") == ReminderTime(hour: 7, minute: 30))
    }

    @Test("못 읽으면 서버 기본값인 오후 7시로 본다")
    func fallsBackToDefaultTime() {
        // 알림 하나 때문에 설정 전체를 잃지 않는다.
        #expect(ReminderTime.parse(nil) == .default)
        #expect(ReminderTime.parse("25:00") == .default)
        #expect(ReminderTime.parse("저녁") == .default)
    }

    @Test("정오와 자정은 12시로 적는다")
    func noonAndMidnightAreTwelve() {
        #expect(ReminderTime(hour: 0, minute: 0).value == "오전 12:00")
        #expect(ReminderTime(hour: 12, minute: 0).value == "오후 12:00")
    }

    @Test("값과 말은 표기가 다르다")
    func valueAndWordsDiffer() {
        let time = ReminderTime(hour: 19, minute: 0)
        #expect(time.value == "오후 7:00")
        #expect(time.words == "오후 7시")
        #expect(ReminderTime(hour: 19, minute: 30).words == "오후 7시 30분")
        #expect(time.wire == "19:00")
    }

    @Test("안내는 전날과 당일 둘 다를 적는다")
    func hintNamesBothDays() {
        let hint = ReminderTimeModel.hint(ReminderTime(hour: 19, minute: 0), day: 5)
        #expect(hint == "5일 진료라면 4일 · 5일 오후 7:00에 알려요")
    }

    // MARK: - 1s-2 건강 정보 수정

    @Test("목록에 없이 저장돼 있던 것도 칩으로 세운다")
    func savedExtrasBecomeChips() {
        // 1b에서 직접 적은 "한방차"가 여기서 사라지면 저장할 때 지워진다.
        #expect(HealthEditModel.extras(["혈압약", "한방차"], step: 0) == ["한방차"])
    }

    @Test("보내는 차례는 보이는 차례다")
    func sendOrderMatchesDisplayOrder() {
        // Set은 순서가 없어 저장할 때마다 카드의 항목 차례가 흔들린다.
        let field = HealthEditModel.field(["진통제", "혈압약"], step: 0, extras: [])
        #expect(field.items == ["혈압약", "진통제"])
        #expect(field.status == .known)
    }

    @Test("아무것도 고르지 않은 것을 없다로 보지 않는다")
    func emptyIsNotAbsent() {
        let field = HealthEditModel.field([], step: 2, extras: [])
        #expect(field.items.isEmpty)
        #expect(field.status == .unknown)
    }

    @MainActor
    @Test("직접 추가를 다시 누르면 닫는다")
    func tappingAddTwiceCloses() {
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
    @Test("이미 있는 항목은 칩을 두 번 세우지 않는다")
    func duplicateChipIsNotAdded() {
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
