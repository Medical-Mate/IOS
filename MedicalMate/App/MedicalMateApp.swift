import SwiftUI

@main
struct MedicalMateApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment.session)
                .environment(\.appEnvironment, environment)
                // **다크 모드는 지원 대상이 아니다.** 디자인 시스템에 다크 값이 없어서
                // 시스템이 어두워도 색이 뒤집히지 않게 여기서 고정한다.
                .preferredColorScheme(.light)
        }
    }
}

private struct AppEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = AppEnvironment()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
