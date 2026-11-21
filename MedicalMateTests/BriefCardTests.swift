import Foundation
import Testing
@testable import MedicalMate

/// E 섹션 — 브리핑 카드(1e-1)가 응답을 어떻게 읽는지.
struct BriefCardTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func axis(_ status: String, _ value: String? = nil) -> AxisResponse {
        AxisResponse(status: status, value: value)
    }

    // MARK: - 축

    @Test func 아직_묻지_않았거나_건너뛴_축은_줄이_되지_않는다() {
        // 8축이 늘 자리를 차지하고 1턴째는 대부분 NOT_ASKED다. 그대로 그리면 빈 줄
        // 여덟 개가 먼저 보인다.
        let items = BriefCardMapping.items(from: [
            "site": axis("FILLED", "복부"),
            "onset": axis("NOT_ASKED"),
            "character": axis("SKIPPED")
        ])
        #expect(items.map(\.key) == ["부위"])
    }

    @Test func 잘_모르겠다는_답은_남긴다() {
        // 확인하지 못했다는 것이 의사에게는 정보다.
        let items = BriefCardMapping.items(from: ["onset": axis("UNKNOWN")])
        #expect(items.map(\.value) == ["잘 모르겠어요"])
    }

    @Test func 확실하지_않은_값은_그_사실을_함께_적는다() {
        let items = BriefCardMapping.items(from: ["onset": axis("AMBIGUOUS", "3주 전")])
        #expect(items.map(\.value) == ["3주 전 (확실하지 않아요)"])
    }

    @Test func 축은_서버_순서가_아니라_읽는_차례로_선다() {
        let items = BriefCardMapping.items(from: [
            "character": axis("FILLED", "쓰림"),
            "site": axis("FILLED", "복부"),
            "onset": axis("FILLED", "3주 전")
        ])
        #expect(items.map(\.key) == ["부위", "기간", "양상"])
    }

    @Test func 모르는_축은_id를_그대로_보인다() {
        // 서버가 축을 늘려도 줄이 사라지지 않게.
        #expect(BriefCardMapping.label(for: "new_axis") == "new_axis")
    }

    // MARK: - 강도

    @Test func 강도는_앞의_숫자만_읽는다() {
        // 낱말은 화면이 단계에서 가져온다. 문자열을 맞춰 보면 서버가 표현을 바꿀 때마다 갈린다.
        #expect(BriefCardMapping.severity(from: axis("FILLED", "3 (꽤 아파요)")) == 3)
    }

    @Test func 범위_밖이거나_숫자가_없으면_눈금을_그리지_않는다() {
        #expect(BriefCardMapping.severity(from: axis("FILLED", "7 (심함)")) == nil)
        #expect(BriefCardMapping.severity(from: axis("FILLED", "꽤 아파요")) == nil)
        #expect(BriefCardMapping.severity(from: axis("UNKNOWN", "3")) == nil)
    }

    // MARK: - 건강 정보

    @Test func 상태가_빠져_와도_값이_있으면_줄을_만든다() {
        // 기기 로그에서 status 없이 오는 것을 봤다. 상태만 보고 자르면 값이 있는데도
        // 줄이 사라진다.
        let patient = PatientResponse(
            name: nil, age: nil, sex: nil, allergies: nil,
            medications: CardListFieldResponse(status: nil, items: ["혈압약"]),
            conditions: nil
        )
        #expect(BriefCardMapping.healthRows(patient).map(\.key) == ["복용약"])
    }

    @Test func 없다고_답했거나_비면_카드에_적지_않는다() {
        let patient = PatientResponse(
            name: nil, age: nil, sex: nil, allergies: nil,
            medications: CardListFieldResponse(status: "NONE", items: []),
            conditions: CardListFieldResponse(status: "UNKNOWN", items: [])
        )
        #expect(BriefCardMapping.healthRows(patient).isEmpty)
    }

    @Test func 건강_정보_줄은_축이_없다() {
        // 고쳐도 보낼 곳이 없는 줄이다.
        let patient = PatientResponse(
            name: nil, age: nil, sex: nil, allergies: nil,
            medications: CardListFieldResponse(status: "KNOWN", items: ["혈압약", "진통제"]),
            conditions: nil
        )
        let row = BriefCardMapping.healthRows(patient).first
        #expect(row?.axis == nil)
        #expect(row?.value == "혈압약 · 진통제")
    }

    @Test func 알러지는_쉼표로_나눈다() {
        let field = CardTextFieldResponse(status: "KNOWN", text: "페니실린, 아스피린 ")
        #expect(BriefCardMapping.allergies(field) == ["페니실린", "아스피린"])
        #expect(BriefCardMapping.allergies(CardTextFieldResponse(status: "NONE", text: "")).isEmpty)
    }

    // MARK: - 머리 줄

    private func response(name: String? = "김OO", age: Int? = 32) -> CardResponse {
        CardResponse(
            cardId: 1, status: nil,
            patient: PatientResponse(
                name: name, age: age, sex: "FEMALE",
                allergies: nil, medications: nil, conditions: nil
            ),
            title: nil, chiefComplaint: "복부 통증 · 3주", axes: nil, questions: nil,
            visited: nil, createdAt: "2026-09-18", clinic: nil, appointment: nil
        )
    }

    @Test func 환자_줄은_이름_나이_성별_작성일이다() {
        #expect(BriefCardMapping.patientLine(response(), calendar: calendar) == "김OO · 32세 여 · 2026.09.18 작성")
    }

    @Test func 가린_줄은_성만_남기고_나이를_뺀다() {
        // 숫자를 바꿔 적으면 틀린 정보가 찍힌다.
        #expect(BriefCardMapping.maskedPatientLine(response(), calendar: calendar) == "김OO · 여 · 2026.09.18 작성")
    }

    // MARK: - 병원 · 일정

    @Test func 이름_없는_병원은_없는_것으로_본다() {
        #expect(BriefCardMapping.hospital(from: ClinicResponse(name: "", address: "서울")) == nil)
        #expect(BriefCardMapping.hospital(from: nil) == nil)
    }

    @Test func 하단_버튼은_일정으로_갈리고_당일은_기록하기다() {
        let today = fixtureDay("2026-09-18")
        func card(on day: String?) -> BriefCard {
            BriefCard(
                id: 1, title: "", patientLine: "", maskedPatientLine: "", items: [],
                severity: nil, allergies: [], questions: [], hospital: nil,
                appointment: day.map {
                    BriefCardAppointment(id: 1, date: fixtureDay($0), clinicName: nil)
                },
                status: nil, visited: false
            )
        }
        func action(_ day: String?) -> BriefCardFooterAction {
            BriefCardMapping.footerAction(for: card(on: day), today: today, calendar: calendar)
        }
        #expect(action(nil) == .schedule)
        #expect(action("2026-09-20") == .viewSchedule)
        // 당일은 진료를 다녀왔을 수 있다.
        #expect(action("2026-09-18") == .recordVisit)
        #expect(action("2026-09-10") == .recordVisit)
    }
}

/// 편집이 서버로 무엇을 보내는지.
struct BriefCardEditTests {
    private func item(_ key: String, _ value: String, axis: String?) -> BriefCardItem {
        BriefCardItem(key: key, value: value, axis: axis)
    }

    @Test func 고친_축만_간다() {
        let original = [item("부위", "복부", axis: "site"), item("시작", "3주 전", axis: "onset")]
        var edited = original
        edited[1].value = "한 달 전"

        let axes = BriefCardMapping.changedAxes(from: original, to: edited)
        #expect(axes?.count == 1)
        #expect(axes?.first?.axis == "onset")
        #expect(axes?.first?.value == "한 달 전")
    }

    @Test func 지운_줄은_빈_값으로_보낸다() {
        // 서버에 "줄을 지운다"는 요청이 없다. 값을 비우면 축이 UNKNOWN으로 내려온다.
        let original = [item("부위", "복부", axis: "site")]
        let axes = BriefCardMapping.changedAxes(from: original, to: [])
        #expect(axes?.first?.axis == "site")
        #expect(axes?.first?.value == "")
    }

    @Test func 축이_없는_줄은_보내지_않는다() {
        let original = [item("복용약", "혈압약", axis: nil)]
        #expect(BriefCardMapping.changedAxes(from: original, to: []) == nil)
    }

    @Test func 고친_것이_없으면_축을_보내지_않는다() {
        let original = [item("부위", "복부", axis: "site")]
        #expect(BriefCardMapping.changedAxes(from: original, to: original) == nil)
    }

    @Test func 적지_않은_빈_질문은_보내지_않는다() {
        #expect(BriefCardMapping.cleaned(["검사를 받아야 하나요?", "  ", ""]) == ["검사를 받아야 하나요?"])
    }
}

/// 화면이 들고 있는 상태.
@MainActor
struct BriefCardModelTests {
    private func model() -> BriefCardModel {
        BriefCardModel(cardId: 1, repository: CardRepository(client: BriefCardStub.client))
    }

    @Test func 편집_전에는_액션이_편집이다() {
        let model = model()
        #expect(model.actionTitle == "편집")
        #expect(!model.isEditing)
    }

    @Test func 이름나이_가리기는_처음부터_켜져_있다() {
        // 카드를 남에게 보이는 자리라 덜 내보내는 쪽이 기본이다. 시안(`1e-1-X`)의
        // 토글이 켜져 있고 Android도 `maskPatient = true`다.
        #expect(model().masksPatient)
    }
}

/// 내보내기 토글이 어느 줄을 바꾸는가(`1e-1-X` `3663:7479`).
struct BriefCardMaskTests {
    private static let card = BriefCard(
        id: 1,
        title: "복부 통증 · 3주",
        patientLine: "김OO · 32세 여 · 2026.09.18 작성",
        maskedPatientLine: "김OO · OO세 여 · 2026.09.18 작성",
        items: [],
        severity: nil,
        allergies: [],
        questions: [],
        hospital: nil,
        appointment: nil,
        status: nil,
        visited: false
    )

    @Test func 찍는_중이_아니면_화면의_줄은_가리지_않는다() {
        // 토글은 내보낼 이미지를 정하는 값이다. 켜 둔 채 시트를 닫았다고 해서 내
        // 화면의 내 이름까지 가려진 채 남으면 안 된다.
        #expect(BriefCardModel.patientLine(Self.card, masked: false) == Self.card.patientLine)
    }

    @Test func 찍는_동안에는_가린_줄로_그린다() {
        #expect(BriefCardModel.patientLine(Self.card, masked: true) == Self.card.maskedPatientLine)
    }
}

private enum BriefCardStub {
    @MainActor static let client = AppEnvironment().client
}

/// `onset`의 줄 이름.
struct BriefCardAxisLabelTests {
    @Test func onset은_기간이라고_적는다() {
        // Android는 "시작"인데 1e-1의 마스터가 "기간"이고 값도 "3주 전 시작 · 최근 악화"라
        // 기간으로 읽힌다. 화면 문구는 Figma를 따른다 — COMPONENT-MAP 3장 14번.
        #expect(BriefCardMapping.label(for: "onset") == "기간")
    }

    @Test func 하단_버튼은_세_상태가_모양이_다르다() {
        // 시안이 일정 잡기는 채운 면(3663:7335), 일정 보기는 테두리(3663:7393),
        // 진료 후 기록은 옅은 면(3663:7428)으로 그린다.
        #expect(BriefCardFooterAction.schedule.kind == .primary)
        #expect(BriefCardFooterAction.viewSchedule.kind == .outline)
        #expect(BriefCardFooterAction.recordVisit.kind == .tonal)
    }
}
