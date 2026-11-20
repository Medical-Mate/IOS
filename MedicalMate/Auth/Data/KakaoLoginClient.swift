import Foundation

/// 카카오 로그인의 결과.
enum KakaoLoginResult: Sendable {
    case success(accessToken: String)
    /// 사용자가 스스로 닫았다. **오류로 다루지 않는다** — 안내를 띄우면 "취소"가 실패로 읽힌다.
    case cancelled
    case failed(message: String?)
}

/// 카카오 SDK를 부르는 자리.
///
/// **프로토콜로 둔 이유**는 두 가지다. 하나는 SDK가 화면(`UIWindowScene`)을 필요로 해서
/// 모델 계층이 UIKit을 알지 않게 하려는 것이고, 다른 하나는 테스트에서 갈아끼우기
/// 위해서다. Android도 같은 이유로 `KakaoLoginClient`를 ViewModel에 주입하지 않는다.
protocol KakaoLoginClient: Sendable {
    /// 카카오톡이 깔려 있으면 앱으로, 아니면 웹으로 로그인한다.
    func login() async -> KakaoLoginResult
    func logout() async
}

/// SDK를 아직 붙이지 않은 자리.
///
/// **M0에서는 여기까지다.** 카카오 iOS SDK를 SwiftPM으로 더하고 `Info.plist`에 URL 스킴과
/// `LSApplicationQueriesSchemes`를 넣은 뒤 이 타입을 실제 구현으로 바꾼다. 앱 키가 없어도
/// 빌드가 통과해야 한다는 규칙은 Android와 같다 — 실패는 로그인 버튼을 눌렀을 때만 난다.
struct UnavailableKakaoLoginClient: KakaoLoginClient {
    func login() async -> KakaoLoginResult {
        .failed(message: "카카오 로그인이 아직 연결되지 않았습니다")
    }

    func logout() async {}
}
