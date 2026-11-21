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
