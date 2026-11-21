import Foundation

/// 앞 낱말의 받침에 따라 갈리는 조사.
///
/// "복부**가** 얼마나 아프세요?"와 "손목**이** 얼마나 아프세요?"는 같은 문장인데 부위
/// 이름이 바꾼다. 문장을 통째로 서버에서 받지 않는 한 앱이 골라야 한다.
///
/// 한글 음절은 `0xAC00 + (초성 × 21 + 중성) × 28 + 종성`이라 28로 나눈 나머지가 종성이다.
/// 나머지가 0이면 받침이 없다.
///
/// **마지막 한글 음절을 찾아 본다.** 온톨로지의 부위 이름이 괄호로 끝난다 —
/// "목 안(목구멍)"의 마지막 글자는 `)`이지만 읽을 때는 "멍"으로 끝나서 "목 안(목구멍)**이**"다.
/// 맨 끝 글자만 보면 늘 "가"가 붙어 "목 안(목구멍)가"가 된다.
///
/// 한글이 하나도 없으면 받침이 없는 쪽으로 둔다 — 영문·숫자의 읽는 소리를 추측하지 않는다.
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
        let syllables: ClosedRange<UInt32> = 0xAC00...0xD7A3
        guard let last = word.unicodeScalars.last(where: { syllables.contains($0.value) }) else {
            return false
        }
        return (last.value - 0xAC00) % 28 != 0
    }
}
