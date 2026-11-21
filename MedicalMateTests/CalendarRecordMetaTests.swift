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
            month: "2026년 9월", writtenOn: Date(timeIntervalSince1970: 0)
        )
        #expect(!ScheduleAddModel.isVisitedAndPicked(intake, picked: [9]))
    }
}
