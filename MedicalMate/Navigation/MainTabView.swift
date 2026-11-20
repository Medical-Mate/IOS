import SwiftUI

/// 하단 탭 셋과 유일한 네비게이션 스택.
///
/// 탭은 **캘린더 · 홈 · 기록**이고 홈이 가운데다. 내 정보는 탭이 아니라 홈 헤더의
/// 아바타로 들어간다.
///
/// 탭마다 스택을 따로 두지 않고 하나를 공유한다. Android가 단일 `NavHost`를 쓰는 것과
/// 같은 이유다 — 탭마다 스택을 두면 같은 화면이 탭 수만큼 쌓인다.
struct MainTabView: View {
    @State private var tab: Tab = .home
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            // 시스템 탭바를 쓰지 않는다. 디자인 시스템의 `Tab Bar`(319:1026)가 Glass
            // 86% · 채움 아이콘 전환으로 그려져 있고, 시스템 바로는 그 모양이 안 된다.
            ZStack(alignment: .bottom) {
                screen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                MMTabBar(selection: $tab)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch tab {
        case .calendar:
            PlaceholderView(title: "캘린더", note: "G 섹션 `1r-1`(3663:15299)을 그린다")
        case .home:
            HomeView(
                onOpenCardList: { path.append(Route.briefCardList) },
                onOpenCard: { path.append(Route.briefCard(cardId: $0.id)) },
                onStartIntake: { path.append(Route.intake(sessionId: nil)) }
            )
        case .record:
            PlaceholderView(title: "기록", note: "H 섹션 `1j-1`(3663:15519)을 그린다")
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        // 화면이 붙는 대로 여기에 등록한다.
        switch route {
        case .briefCardList:
            BriefCardListView(
                onOpenCard: { path.append(Route.briefCard(cardId: "\($0)")) },
                onResumeIntake: { path.append(Route.intake(sessionId: $0)) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .intake(let sessionId):
            // 새로 시작하는 길은 1단계(인체도)가 짚은 부위를 넘겨줘야 열린다. 아직
            // 그 화면이 없어서 이어서 하는 길만 간다.
            if let sessionId {
                IntakeFlowView(
                    sessionId: sessionId,
                    onClose: { path.removeLast() },
                    onCreateCard: { _ in path.append(Route.briefCardList) },
                    onFindHospital: { path.append(Route.hospitalPick) }
                )
                .toolbar(.hidden, for: .navigationBar)
            } else {
                PlaceholderView(title: "인체도", note: "1단계 `1c-1`이 서면 여기서 부위를 짚는다 (D5 미정)")
            }
        default:
            PlaceholderView(title: "\(route)", note: "아직 그리지 않았다")
        }
    }
}
