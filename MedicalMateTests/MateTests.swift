import Foundation
import Testing
@testable import MedicalMate

/// J 섹션 — 헤이 메이트가 말을 무엇으로 알아듣는지.
struct MateTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func command(_ text: String) -> MateCommand? {
        MateCommandParser.command(from: text)
    }

    @Test func 띄어쓰기가_달라도_같은_말로_듣는다() {
        // 받아쓰기가 "일정 추가"와 "일정추가"를 그때그때 다르게 적는다.
        #expect(command("일정 추가해줘") == .scheduleAdd)
        #expect(command("일정추가") == .scheduleAdd)
    }

    @Test func 카드를_만들자는_말은_증상_정리다() {
        // 카드는 증상 정리를 마쳐야 생긴다. 목록으로 가면 만들 길이 없다.
        #expect(command("브리핑 카드 만들어 줘") == .intake)
        #expect(command("새 카드") == .intake)
        #expect(command("브리핑 카드 보여 줘") == .briefCards)
    }

    @Test func 알림은_설정이라_내_정보로_간다() {
        // "진료 후 기록 알림 꺼 줘"가 기록을 시작하면 안 된다.
        #expect(command("진료 후 기록 알림 꺼 줘") == .profile)
    }

    @Test func 일정을_잡자는_말은_묻는_말이_아니다() {
        #expect(command("다음 진료 일정 잡아 줘") == .scheduleAdd)
        #expect(command("다음 진료 언제야") == .nextVisit)
    }

    @Test func 뒤로는_맨_끝이라_다른_말을_가로채지_않는다() {
        #expect(command("이전 기록 보여 줘") == .record)
        #expect(command("뒤로") == .back)
    }

    @Test func 이어서_하자는_말은_증상보다_먼저다() {
        #expect(command("증상 정리 이어서 할래") == .resume)
    }

    @Test func 모르는_말은_아무_데로도_옮기지_않는다() {
        #expect(command("오늘 날씨 어때") == nil)
        #expect(command("") == nil)
    }

    @Test func 말_앞에_남은_호출어를_뗀다() {
        // 호출어를 듣는 쪽과 받아쓰는 쪽이 마이크를 넘기는 사이에 끝이 섞여 들어온다.
        #expect(MateCommandParser.withoutWakeEcho("메이트, 캘린더 열어 줘") == "캘린더 열어 줘")
        #expect(MateCommandParser.withoutWakeEcho("헤이 메이트 다음 진료 언제야") == "다음 진료 언제야")
    }

    @Test func 말_가운데의_메이트는_떼지_않는다() {
        #expect(MateCommandParser.withoutWakeEcho("내 메이트 카드") == "내 메이트 카드")
    }

    @Test func 묻는_말은_화면을_옮기지_않는다() {
        #expect(MateModel.action(for: .nextVisit) == nil)
        #expect(MateModel.action(for: .calendar) == .tab(.calendar))
        #expect(MateModel.action(for: .back) == .back)
    }

    @Test func 옮긴_뒤_둘째_줄은_캘린더에만_있다() {
        // 시안이 적어 둔 것이 캘린더 하나뿐이라 나머지는 비운다.
        #expect(MateModel.movedHint(.calendar) == "날짜를 말하면 그 날을 열어드려요")
        #expect(MateModel.movedHint(.record) == nil)
        #expect(MateModel.movedTitle(.calendar) == "캘린더로 옮겼어요")
    }

    @Test func 다음_진료_답은_날짜와_제목을_두_줄로_적는다() {
        let appointment = Appointment(
            id: 2,
            title: "서울OO병원 내과 재진",
            clinic: "서울OO병원 내과",
            on: HomeRepository.date(from: "2026-09-25")!,
            time: AppointmentTime(hour: 10, minute: 30),
            status: .scheduled,
            origin: .manual,
            cards: [],
            todos: []
        )
        let answer = MateModel.answer(for: appointment, calendar: calendar)
        #expect(answer == "9월 25일 (금) 오전 10:30,\n서울OO병원 내과 재진이에요")
    }

    @Test func 말_전체가_닫자는_말일_때만_닫는다() {
        #expect(MateWords.isStop("그만"))
        #expect(MateWords.isStop("됐어요"))
        #expect(MateWords.isStop("이제 닫아 줘"))
        // 의사에게 물을 말이 카드를 닫으면 안 된다.
        #expect(!MateWords.isStop("그만 먹어도 되나요?"))
        #expect(!MateWords.isStop("끝났대요"))
        #expect(!MateWords.isStop("다음 진료 언제야"))
    }

    @Test func 물음표가_없어도_묻는_말을_가린다() {
        #expect(MateWords.isAsking("그만 먹어도 되나요"))
        #expect(MateWords.isAsking("언제까지 먹을까요"))
        #expect(!MateWords.isAsking("그만"))
    }

    @Test func 못_알아들은_말은_그대로_되돌려_준다() {
        #expect(MateModel.missed("오늘 날씨") == "\"오늘 날씨\", 잘 못 알아들었어요")
        #expect(MateModel.missed("") == "잘 못 알아들었어요")
    }
}
