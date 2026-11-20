import SwiftUI

/// 증상 정리 2 · 3단계를 묶는 자리.
///
/// **1단계(인체도)는 D 섹션 밖이고 아직 없다** — D5(3D 렌더러)가 정해지지 않았다.
/// 그래서 들어오는 길이 둘이다:
/// - 새로 시작: 1단계가 짚은 부위를 넘겨준다. 그 화면이 설 때까지 이 길은 닫혀 있다.
/// - **이어서 하기: 부위를 서버가 들고 있다.** 홈과 1j-4의 "이어서 정리하기"가 이리로 온다.
struct IntakeFlowView: View {
    @Environment(\.appEnvironment) private var app

    /// 1단계가 넘겨준 부위. 이어서 하는 길에서는 비운다.
    var site: IntakeSite?
    /// 이어서 할 세션. 새로 시작하면 비운다.
    var sessionId: Int64?

    let onClose: () -> Void
    let onCreateCard: (Int64) -> Void
    let onFindHospital: () -> Void

    @State private var model: IntakeModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            guard model == nil else { return }
            let created = IntakeModel(site: site ?? IntakeSite(text: ""), repository: app.intake)
            model = created
            if let sessionId {
                await created.resume(sessionId: sessionId)
            }
        }
    }

    @ViewBuilder
    private func content(_ model: IntakeModel) -> some View {
        switch model.phase {
        case .severity:
            SeverityStepView(model: model, onBack: onClose)
        case .chat:
            IntakeChatView(model: model, onBack: model.backToSeverity)
        case .done:
            IntakeDoneView(
                onCreateCard: {
                    if let id = model.sessionId { onCreateCard(id) }
                },
                onFindHospital: onFindHospital,
                onBack: model.backToChat
            )
        }
    }
}
