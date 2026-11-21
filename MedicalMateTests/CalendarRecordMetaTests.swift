import Foundation
import Testing
@testable import MedicalMate

/// 기록 줄의 둘째 줄(2026-11-22). 시안 `1r-2`가 `위염 초기 · 2주 약 · 09.26 재방문`이라
/// **소견 · 약 · 재방문** 셋을 그 차례로 잇는다. 전에는 목록 응답만 보고 카드 제목과
/// 재방문 날짜를 적어서 **같은 줄이 두 기기에서 다른 말을 했다**(Android `#262`).
@Suite("기록 줄의 둘째 줄")
struct CalendarRecordMetaTests {
    private func item(_ axis: String, _ value: String) -> VisitItem {
        VisitItem(axis: axis, label: VisitMapping.label(for: axis), value: value)
    }

    @Test func 소견_약_재방문을_그_차례로_잇는다() {
        let items = [
            item(VisitAxis.followUp, "09.26 재방문"),
            item(VisitAxis.medication, "2주 약"),
            item(VisitAxis.findings, "위염 초기")
        ]
        #expect(CalendarDayModel.recordMeta(items) == "위염 초기 · 2주 약 · 09.26 재방문")
    }

    /// 검사와 AI가 늘린 축은 붙이지 않는다. 한 줄 메타가 넘친다.
    @Test func 검사와_늘어난_축은_빼고_잇는다() {
        let items = [
            item(VisitAxis.findings, "위염 초기"),
            item(VisitAxis.tests, "위내시경"),
            item("extra", "AI가 늘린 축")
        ]
        #expect(CalendarDayModel.recordMeta(items) == "위염 초기")
    }

    /// 두 줄로 적힌 값은 첫 줄만 쓴다.
    @Test func 값의_첫_줄만_쓴다() {
        let items = [item(VisitAxis.findings, "위염 초기\n다음에 다시 봅시다")]
        #expect(CalendarDayModel.recordMeta(items) == "위염 초기")
    }

    @Test func 셋이_다_없으면_비어_있다() {
        #expect(CalendarDayModel.recordMeta([item(VisitAxis.tests, "위내시경")]).isEmpty)
    }
}

/// 누른 일정이 열리는지(2026-11-22). 하루에 일정이 둘 이상일 수 있는데 날짜만으로 열면
/// 첫 건이 나와서, 누른 것과 열린 것이 달랐다(Android `#179`).
@Suite("일자 화면이 여는 일정")
struct CalendarDayPickTests {
    private func appointment(_ id: Int64, _ hour: Int) -> Appointment {
        Appointment(
            id: id,
            title: "진료 \(id)",
            clinic: nil,
            on: Date(timeIntervalSince1970: 0),
            time: AppointmentTime(hour: hour, minute: 0),
            status: .scheduled,
            origin: .manual,
            cards: [],
            todos: []
        )
    }

    @Test func 누른_일정을_연다() {
        let list = [appointment(1, 9), appointment(2, 14)]
        #expect(CalendarDayModel.pick(list, id: 2)?.id == 2)
    }

    /// 지운 일정으로 돌아오는 경우가 그렇다.
    @Test func 그_날에_없는_번호면_가장_이른_것을_연다() {
        let list = [appointment(1, 9), appointment(2, 14)]
        #expect(CalendarDayModel.pick(list, id: 99)?.id == 1)
    }

    @Test func 번호가_없으면_가장_이른_것을_연다() {
        let list = [appointment(2, 14), appointment(1, 9)]
        #expect(CalendarDayModel.pick(list, id: nil)?.id == 1)
    }

    @Test func 일정이_없으면_아무것도_없다() {
        #expect(CalendarDayModel.pick([], id: 1) == nil)
    }
}

/// 재진인 일정인지(2026-11-22). 재방문 확정으로 들어왔거나 **이미 진료를 마친 카드를
/// 골랐으면** 재진이다(Android `#245` · `#272`). 뒤의 것이 없으면 같은 카드로 다시 잡은
/// 일정이 일자 화면과 홈에서 "초진"으로 뜨는데, 기록 상세는 같은 진료를 재방문으로
/// 적어 두 화면이 어긋난다.
@Suite("재진인 일정 가르기")
struct ScheduleRevisitTests {
    private func card(_ id: Int64, visited: Bool) -> CardListItem {
        CardListItem(
            kind: .card(id: id, visited: visited),
            title: "카드 \(id)", meta: "", summary: nil,
            clinic: nil,
            month: "2026년 9월", writtenOn: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func 진료를_마친_카드를_고르면_재진이다() {
        #expect(ScheduleAddModel.isVisitedAndPicked(card(1, visited: true), picked: [1]))
    }

    @Test func 고르지_않았으면_재진이_아니다() {
        #expect(!ScheduleAddModel.isVisitedAndPicked(card(1, visited: true), picked: [2]))
    }

    @Test func 아직_안_간_카드는_재진이_아니다() {
        #expect(!ScheduleAddModel.isVisitedAndPicked(card(1, visited: false), picked: [1]))
    }

    /// 문답 줄과 기록 줄은 카드가 아니다.
    @Test func 카드가_아닌_줄은_재진이_아니다() {
        let intake = CardListItem(
            kind: .openIntake(sessionId: 9, tempSaved: false, step: 2, total: 3),
            title: "문답", meta: "", summary: nil,
            clinic: nil,
            month: "2026년 9월", writtenOn: Date(timeIntervalSince1970: 0)
        )
        #expect(!ScheduleAddModel.isVisitedAndPicked(intake, picked: [9]))
    }
}

/// 시간 미정으로 저장한 일정을 나중에 고치는 길(Android `#230`).
struct ScheduleEditTests {
    private func appointment(time: AppointmentTime?) -> Appointment {
        Appointment(
            id: 7,
            title: "서울OO병원 내과",
            clinic: "서울OO병원 내과",
            on: fixtureDay("2026-09-26"),
            time: time,
            status: .scheduled,
            origin: .manual,
            cards: [],
            todos: []
        )
    }

    @Test func 시각이_없는_일정만_눌러서_고친다() {
        // 시간 미정으로 저장하고 나면 그 값을 채울 자리가 여기뿐이다.
        #expect(CalendarDayView.editableId(appointment(time: nil)) == 7)
    }

    @Test func 시각이_정해진_일정은_눌리지_않는다() {
        // 열어도 고칠 것이 없는 화면이 뜬다.
        #expect(CalendarDayView.editableId(appointment(time: AppointmentTime(hour: 10, minute: 30))) == nil)
    }

    @Test func 일정이_없으면_눌리지_않는다() {
        #expect(CalendarDayView.editableId(nil) == nil)
    }

    @Test func 고칠_때는_출처를_보내지_않는다() {
        // 이미 저장된 일정이 어디서 왔는지는 고친다고 바뀌지 않는다. 날짜·시각·카드·할
        // 일만 간다.
        let create = CreateAppointmentRequest(
            clinicName: "서울OO병원 내과",
            department: nil,
            purpose: nil,
            scheduledOn: "2026-09-26",
            scheduledTime: "10:30",
            cardIds: [3],
            origin: AppointmentOrigin.visitFollowUp.wire,
            todos: []
        )
        let update = ScheduleAddModel.updateRequest(from: create)
        #expect(update.scheduledOn == "2026-09-26")
        #expect(update.scheduledTime == "10:30")
        #expect(update.cardIds == [3])
        #expect(update.clinicName == "서울OO병원 내과")
        #expect(update.status == nil)
    }
}

/// 일정 추가의 저장 조건(`1r-4` · `1r-4-B`).
@MainActor
struct ScheduleSaveRuleTests {
    private func model(date: Date?) -> ScheduleAddModel {
        let env = AppEnvironment()
        return ScheduleAddModel(
            initialDate: date,
            repository: AppointmentRepository(client: env.client),
            cards: CardRepository(client: env.client)
        )
    }

    @Test func 병원이_비면_저장할_수_없다() {
        // 시안이 저장하기를 병원이 차는 순간 켠다. 병원 없이 저장하면 일자 화면의
        // 일정 제목이 빈 줄로 선다 — 제목을 병원·진료과·목적으로 짓기 때문이다.
        #expect(!model(date: fixtureDay("2026-09-26")).canSave)
    }

    @Test func 날짜가_비면_저장할_수_없다() {
        let model = model(date: nil)
        model.pick(clinic: Hospital(name: "서울OO병원 내과", address: nil))
        #expect(!model.canSave)
    }

    @Test func 카드를_고르지_않으면_저장할_수_없다() {
        // 홈의 오늘 진료 배너와 진료 후 기록이 카드에 붙어 있어서, 카드 없는 일정은
        // 그 길에 들어서지 못한다(Android `#312`). 시각만 선택이다.
        let model = model(date: fixtureDay("2026-09-26"))
        model.pick(clinic: Hospital(name: "서울OO병원 내과", address: nil))
        #expect(!model.canSave)
    }

    @Test func 고치러_연_일정에는_카드를_묻지_않는다() {
        // 그때는 카드를 보내지 않는다.
        #expect(!ScheduleAddModel.isCardMissing(appointmentId: 1, pickedCount: 0))
        #expect(ScheduleAddModel.isCardMissing(appointmentId: nil, pickedCount: 0))
        #expect(!ScheduleAddModel.isCardMissing(appointmentId: nil, pickedCount: 1))
    }
}

/// 고른 카드의 병원으로 빈 칸을 채운다(`1r-4-B`).
struct ScheduleClinicFillTests {
    private func card(id: Int64, clinic: String?) -> CardListItem {
        CardListItem(
            kind: .card(id: id, visited: false),
            title: "복부 통증 · 3주",
            meta: "09.04 작성",
            summary: nil,
            clinic: clinic,
            month: "2026년 9월",
            writtenOn: fixtureDay("2026-09-04")
        )
    }

    @Test func 고른_카드의_병원을_쓴다() {
        let cards = [card(id: 7, clinic: "서울OO병원 내과")]
        #expect(ScheduleAddModel.pickedClinic(cards: cards, picked: [7]) == "서울OO병원 내과")
    }

    @Test func 고르지_않은_카드의_병원은_쓰지_않는다() {
        let cards = [card(id: 7, clinic: "서울OO병원 내과")]
        #expect(ScheduleAddModel.pickedClinic(cards: cards, picked: [8]) == nil)
    }

    @Test func 병원이_빈_카드는_건너뛴다() {
        // "병원 미정"은 메타 줄의 말이지 적힌 병원이 아니다.
        let cards = [card(id: 7, clinic: nil), card(id: 8, clinic: "OO이비인후과의원")]
        #expect(ScheduleAddModel.pickedClinic(cards: cards, picked: [7, 8]) == "OO이비인후과의원")
    }
}
