import Foundation

/// 앞 낱말의 받침에 따라 갈리는 조사.
///
/// "복부**가** 얼마나 아프세요?"와 "손목**이** 얼마나 아프세요?"는 같은 문장인데 부위
/// 이름이 바꾼다. 문장을 통째로 서버에서 받지 않는 한 앱이 골라야 한다.
///
/// 한글 음절은 `0xAC00 + (초성 × 21 + 중성) × 28 + 종성`이라 28로 나눈 나머지가 종성이다.
/// 나머지가 0이면 받침이 없다. 한글이 아닌 글자로 끝나면 받침이 없는 쪽으로 둔다 —
/// 영문·숫자의 읽는 소리를 추측하지 않는다.
enum KoreanParticle {
    /// 이 / 가.
    static func subject(after word: String) -> String {
        hasFinalConsonant(word) ? "이" : "가"
    }

    /// 을 / 를.
    static func object(after word: String) -> String {
        hasFinalConsonant(word) ? "을" : "를"
    }

    static func hasFinalConsonant(_ word: String) -> Bool {
        guard let last = word.unicodeScalars.last else { return false }
        let syllables: ClosedRange<UInt32> = 0xAC00...0xD7A3
        guard syllables.contains(last.value) else { return false }
        return (last.value - 0xAC00) % 28 != 0
    }
}
