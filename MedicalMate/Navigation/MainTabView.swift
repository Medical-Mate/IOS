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
            TabView(selection: $tab) {
                PlaceholderView(title: "캘린더", note: "M3에서 Figma `1r-1`을 그린다")
                    .tag(Tab.calendar)
                PlaceholderView(title: "홈", note: "M2에서 Figma `1n-1`을 그린다")
                    .tag(Tab.home)
                PlaceholderView(title: "기록", note: "M3에서 Figma `1j-1`을 그린다")
                    .tag(Tab.record)
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        // 화면이 붙는 대로 여기에 등록한다. Android는 기능 패키지의 확장 함수가 맡는다.
        PlaceholderView(title: "\(route)", note: "아직 그리지 않았다")
    }
}
