import Foundation

/// "헤이 메이트" 다음에 말할 수 있는 것.
///
/// **지금은 화면을 옮기는 것과 묻는 것뿐이다.** 저장 · 삭제처럼 되돌릴 수 없는 동작은
/// 넣지 않았다 — 잘못 알아들으면 사고가 난다. 넣게 되면 실행 전에 확인을 거친다.
/// 규칙은 Android `voice/ui/VoiceCommand.kt`에서 그대로 가져왔다.
enum MateCommand: Sendable, Equatable {
    case home
    case calendar
    case record
    case profile
    case back
    case intake
    /// 진료 후 기록. 말한 날, 없으면 오늘의 일자 화면에서 시작한다.
    case visitRecord
    case briefCards
    case scheduleAdd
    /// 하던 증상 정리를 이어 한다. 홈의 "이어서 하기"와 같다.
    case resume
    /// 다음 진료가 언제인지 묻는다. **옮기지 않고 답한다.**
    case nextVisit
}

/// 받아쓴 말을 명령으로 옮긴다.
enum MateCommandParser {
    /// 모르는 말이면 `nil`이다.
    ///
    /// **띄어쓰기를 지우고 낱말을 찾는다.** 받아쓰기가 "일정 추가"와 "일정추가"를 그때그때
    /// 다르게 적는다. 낱말이 서로 겹쳐서 **차례가 곧 우선순위다** — "증상 기록"은 기록 탭이
    /// 아니라 증상 정리이고, 카드는 증상보다 먼저다.
    static func command(from text: String) -> MateCommand? {
        let heard = text.filter { !$0.isWhitespace && !punctuation.contains($0) }
        guard !heard.isEmpty else { return nil }

        let keyword = keywords.first { _, words in words.contains { heard.contains($0) } }?.0

        // 알림 설정은 내 정보에 있다. "진료 후 기록 알림 꺼 줘"가 기록을 시작하면 안 된다.
        if heard.contains("알림") { return .profile }
        // **카드를 새로 만들자는 말은 증상 정리다.** 카드는 증상 정리를 마쳐야 생긴다.
        if keyword != .scheduleAdd, createsCard(heard) { return .intake }
        return keyword
    }

    /// 받아쓴 말 앞에 남은 호출어를 뗀다.
    ///
    /// 호출어를 듣는 쪽과 명령을 받아쓰는 쪽이 마이크를 넘겨받는 사이에 "헤이 메이트"의 끝이
    /// 명령에 들어가 "메이트", "웨이트"로 적힌다. **말 맨 앞일 때만 뗀다.**
    static func withoutWakeEcho(_ text: String) -> String {
        guard let regex = wakeEcho else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let stripped = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// "브리핑 카드를 만들자" · "카드 작성할래" · "새 카드".
    private static func createsCard(_ heard: String) -> Bool {
        guard let regex = createCard else { return false }
        let range = NSRange(heard.startIndex..<heard.endIndex, in: heard)
        return regex.firstMatch(in: heard, range: range) != nil
    }

    private static let punctuation: Set<Character> = [".", ",", "?", "!", "~"]

    private static let createCard = try? NSRegularExpression(
        pattern: "(?:카드|브리핑).{0,3}(?:만들|작성|쓰자|쓸래|써줘|새로)|새(?:로운)?(?:브리핑)?카드"
    )

    private static let wakeEcho = try? NSRegularExpression(
        pattern: "^\\s*(?:(?:hey|a|헤이|해이|에이|헤|해|에)[\\s,.]*)?"
            + "(?:mate|메이트|매이트|메잇|메이드|웨이트|베이트|네이트|메이트야)[\\s,.!?~]*",
        options: [.caseInsensitive]
    )

    /// **차례가 곧 우선순위다.** "뒤로"는 맨 끝이다 — "이전 기록 보여 줘"가 "이전"으로
    /// 뒤로 가면 안 된다. 일정 추가는 "다음 진료"보다 먼저다 — "다음 진료 일정 잡아 줘"는
    /// 묻는 말이 아니다.
    private static let keywords: [(MateCommand, [String])] = [
        (.scheduleAdd, [
            "일정추가", "일정등록", "일정잡", "일정만들", "일정넣", "예약추가", "예약등록", "예약잡", "예약넣",
            "스케줄추가", "스케줄잡", "진료잡", "진료예약잡",
        ]),
        (.resume, ["이어서", "이어하", "이어할", "이어서할", "하던거", "하던정리", "하다만"]),
        (.nextVisit, [
            "다음진료", "다음예약", "다음일정언제", "진료언제", "진료가언제", "병원언제", "언제가야", "진료날언제",
        ]),
        (.briefCards, ["브리핑", "카드"]),
        (.intake, [
            "증상", "아파", "아픈", "아프", "아퍼", "문진", "불편해", "결려", "결리", "저려", "저리", "쑤셔", "쑤시",
        ]),
        (.visitRecord, [
            "진료후기록", "기록할", "기록하기", "기록남", "기록쓸", "기록써", "기록적", "기록해", "진료끝", "진료다녀",
            "진료받고왔", "진료받았", "진료봤", "병원다녀왔", "들은말", "들은거",
        ]),
        (.profile, [
            "내정보", "나의정보", "제정보", "설정", "프로필", "마이페이지", "내계정", "건강정보", "먹는약", "복용약",
        ]),
        (.calendar, ["캘린더", "달력", "일정", "예약", "스케줄"]),
        (.record, ["기록", "히스토리", "진료내역", "다녀온", "지난진료", "갔던병원", "다녀왔던"]),
        (.home, ["홈", "처음", "메인", "첫화면"]),
        (.back, ["뒤로", "이전", "돌아가", "전화면", "앞화면", "되돌아"]),
    ]
}
