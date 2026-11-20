import Foundation
import Observation

/// 1o 로그인 화면의 상태.
@MainActor
@Observable
final class LoginModel {
    private(set) var isWorking = false
    /// 사용자에게 보일 오류. **취소는 오류가 아니다** — `nil`로 둔다.
    private(set) var errorMessage: String?

    private let auth: AuthRepository
    private let session: SessionModel

    init(auth: AuthRepository, session: SessionModel) {
        self.auth = auth
        self.session = session
    }

    func logIn() async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil

        switch await auth.login() {
        case .loggedIn(let onboardingRequired):
            // **화면을 바꾸기 전에 상태를 먼저 정리한다.** 화면이 바뀌면 이 뒤에 둔 코드는
            // 실행되지 않는다. Android에서 `LaunchedEffect`가 취소되는 것과 같은 자리다.
            isWorking = false
            session.logIn(onboardingRequired: onboardingRequired)
        case .cancelled:
            isWorking = false
        case .failed(let message):
            isWorking = false
            errorMessage = message ?? "로그인하지 못했습니다. 잠시 후 다시 시도해주세요."
        }
    }
}
