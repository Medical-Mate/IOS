import Foundation

/// 증상 정리가 **환자에게 몇 단계로 보이는가.**
///
/// **서버의 진행도를 그대로 옮기지 않는다**(Android `#176`). `progressCurrent` ·
/// `progressTotal`은 AI 문답의 **왕복을 센 것이고 상한이 20**이다. 그대로 찍으면
/// "20단계 중 7단계"가 되는데, 환자가 보는 증상 정리는 인체도 · 강도 · 문답 **셋**이다.
///
/// 세션은 부위와 강도를 고른 뒤에 생기므로 **홈과 목록에 뜨는 문답은 늘 3단계에 있다.**
/// 질문 고르기에서 "다음"을 눌렀으면(`questionsConfirmed`) 세 단계를 다 마친
/// "임시 저장"이다.
enum IntakeProgress {
    /// 환자가 보는 단계 수.
    static let total = 3

    /// 몇 단계까지 했는지.
    nonisolated static func done(questionsConfirmed: Bool) -> Int {
        questionsConfirmed ? total : total - 1
    }
}
