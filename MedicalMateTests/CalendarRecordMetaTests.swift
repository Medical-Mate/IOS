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
