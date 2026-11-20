import Foundation

/// 브리핑 카드에 담을 질문의 상한.
///
/// **한 자리에 둔다.** 증상 정리 3단계(1c-D~D4)와 카드 편집(1e-1-E)이 같은 상한을
/// 쓴다. 둘이 다른 숫자를 들고 있으면 한쪽에서 담은 질문이 다른 쪽에서 거절된다.
///
/// 서버도 같은 상한을 들고 있고 넘기면 `PUT /questions`를 거절한다. **그 결과를 버리지
/// 말고 화면에 알려야 한다** — Android의 알려진 결함이다(FEATURE-SPEC 2.3).
enum BriefCardQuestions {
    static let max = 5
}
