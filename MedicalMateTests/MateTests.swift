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

    @Test("띄어쓰기가 달라도 같은 말로 듣는다")
    func spacingDoesNotChangeCommand() {
        // 받아쓰기가 "일정 추가"와 "일정추가"를 그때그때 다르게 적는다.
        #expect(command("일정 추가해줘") == .scheduleAdd)
        #expect(command("일정추가") == .scheduleAdd)
    }

    @Test("카드를 만들자는 말은 증상 정리다")
    func makeCardMeansIntake() {
        // 카드는 증상 정리를 마쳐야 생긴다. 목록으로 가면 만들 길이 없다.
        #expect(command("브리핑 카드 만들어 줘") == .intake)
        #expect(command("새 카드") == .intake)
        #expect(command("브리핑 카드 보여 줘") == .briefCards)
    }

    @Test("알림은 설정이라 내 정보로 간다")
    func reminderWordsGoToProfile() {
        // "진료 후 기록 알림 꺼 줘"가 기록을 시작하면 안 된다.
        #expect(command("진료 후 기록 알림 꺼 줘") == .profile)
    }

    @Test("일정을 잡자는 말은 묻는 말이 아니다")
    func schedulingIsNotAQuestion() {
        #expect(command("다음 진료 일정 잡아 줘") == .scheduleAdd)
        #expect(command("다음 진료 언제야") == .nextVisit)
    }

    @Test("뒤로는 맨 끝이라 다른 말을 가로채지 않는다")
    func backIsMatchedLast() {
        #expect(command("이전 기록 보여 줘") == .record)
        #expect(command("뒤로") == .back)
    }

    @Test("이어서 하자는 말은 증상보다 먼저다")
    func resumeBeatsIntake() {
        #expect(command("증상 정리 이어서 할래") == .resume)
    }

    @Test("모르는 말은 아무 데로도 옮기지 않는다")
    func unknownWordsNavigateNowhere() {
        #expect(command("오늘 날씨 어때") == nil)
        #expect(command("") == nil)
    }

    @Test("말 앞에 남은 호출어를 뗀다")
    func stripsLeadingWakeEcho() {
        // 호출어를 듣는 쪽과 받아쓰는 쪽이 마이크를 넘기는 사이에 끝이 섞여 들어온다.
        #expect(MateCommandParser.withoutWakeEcho("메이트, 캘린더 열어 줘") == "캘린더 열어 줘")
        #expect(MateCommandParser.withoutWakeEcho("헤이 메이트 다음 진료 언제야") == "다음 진료 언제야")
    }

    @Test("말 가운데의 메이트는 떼지 않는다")
    func keepsMateInsideSentence() {
        #expect(MateCommandParser.withoutWakeEcho("내 메이트 카드") == "내 메이트 카드")
    }

    @Test("묻는 말은 화면을 옮기지 않는다")
    func questionsDoNotNavigate() {
        #expect(MateModel.action(for: .nextVisit) == nil)
        #expect(MateModel.action(for: .calendar) == .tab(.calendar))
        #expect(MateModel.action(for: .back) == .back)
    }

    @Test("옮긴 뒤 둘째 줄은 캘린더에만 있다")
    func onlyCalendarHasHint() {
        // 시안이 적어 둔 것이 캘린더 하나뿐이라 나머지는 비운다.
        #expect(MateModel.movedHint(.calendar) == "날짜를 말하면 그 날을 열어드려요")
        #expect(MateModel.movedHint(.record) == nil)
        #expect(MateModel.movedTitle(.calendar) == "캘린더로 옮겼어요")
    }

    @Test("다음 진료 답은 날짜와 제목을 두 줄로 적는다")
    func nextVisitAnswerHasTwoLines() throws {
        let appointment = Appointment(
            id: 2,
            title: "서울OO병원 내과 재진",
            clinic: "서울OO병원 내과",
            on: try #require(HomeRepository.date(from: "2026-09-25")),
            time: AppointmentTime(hour: 10, minute: 30),
            status: .scheduled,
            origin: .manual,
            cards: [],
            todos: []
        )
        let answer = MateModel.answer(for: appointment, calendar: calendar)
        #expect(answer == "9월 25일 (금) 오전 10:30,\n서울OO병원 내과 재진이에요")
    }

    @Test("말 전체가 닫자는 말일 때만 닫는다")
    func closesOnlyOnWholeStopPhrase() {
        #expect(MateWords.isStop("그만"))
        #expect(MateWords.isStop("됐어요"))
        #expect(MateWords.isStop("이제 닫아 줘"))
        // 의사에게 물을 말이 카드를 닫으면 안 된다.
        #expect(!MateWords.isStop("그만 먹어도 되나요?"))
        #expect(!MateWords.isStop("끝났대요"))
        #expect(!MateWords.isStop("다음 진료 언제야"))
    }

    @Test("물음표가 없어도 묻는 말을 가린다")
    func detectsQuestionsWithoutMark() {
        #expect(MateWords.isAsking("그만 먹어도 되나요"))
        #expect(MateWords.isAsking("언제까지 먹을까요"))
        #expect(!MateWords.isAsking("그만"))
    }

    @Test("못 알아들은 말은 그대로 되돌려 준다")
    func echoesWhatItMisheard() {
        #expect(MateModel.missed("오늘 날씨") == "\"오늘 날씨\", 잘 못 알아들었어요")
        #expect(MateModel.missed("") == "잘 못 알아들었어요")
    }
}
