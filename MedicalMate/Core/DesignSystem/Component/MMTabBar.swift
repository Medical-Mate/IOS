import SwiftUI

/// 디자인 시스템 `Tab Bar` (Figma `319:1026`).
///
/// Figma 설명 그대로:
/// > 하단 내비. 390 × 82(탭 46 + 상단 여백 8 + safe area 24). 최대 5탭, 라벨 6자 이내.
/// > **활성 표시는 아이콘 채움 전환 + 색 + 라벨 무게 세 가지를 겹친다.** 알약
/// > 인디케이터를 쓰지 않는 이유: 그건 Material 3(안드로이드) 고유 패턴이고, iOS와
/// > 국내 앱의 공통 관례는 아이콘이 채워지는 것이다. 한쪽 플랫폼 관례를 양쪽에 쓰면
/// > iOS에서 이물감이 난다. **채움 전환은 색맹 사용자에게도 상태가 전달된다** — 색만
/// > 바뀌면 구분되지 않는다. 상단 1px 헤어라인이 콘텐츠와 바를 가른다. 콘텐츠 위에
/// > 겹치므로 `Surface/Glass`(흰 면 86% + 블러)를 쓴다. **각 탭의 1Depth 화면에서만
/// > 노출한다** — 하위 화면으로 들어가면 감춘다.
///
/// **라벨 무게는 마스터에서 바뀌지 않는다.** 설명은 Medium → SemiBold라고 적었는데
/// 마스터의 활성·비활성 라벨이 모두 `Label/S`다. Figma 마스터를 따랐고 디자인 트랙에
/// 물어야 한다. 채움 전환과 색 둘은 그대로 있어서 색만으로 구분하지는 않는다.
///
/// 탭은 셋이고 홈이 가운데다. 마스터에 네 번째 variant(`Active=Active4`)가 있지만
/// 앱은 쓰지 않는다 — 내 정보는 탭이 아니라 홈 헤더의 아바타로 들어간다.
struct MMTabBar: View {
    @Binding var selection: Tab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(MMColor.borderSubtle)
                .frame(height: TabBarMetrics.hairline)

            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    item(tab)
                }
            }
            .padding(.top, MMSpace.s8)
            .padding(.bottom, MMSize.safeBottom)
        }
        .frame(height: MMSize.tabBarHeight)
        .background {
            MMColor.bgSurface.opacity(MMGlass.tabBarOpacity)
                .background(.ultraThinMaterial)
        }
    }

    private func item(_ tab: Tab) -> some View {
        let isActive = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: MMSpace.s4) {
                (isActive ? tab.filledIcon : tab.icon).view()
                // 활성 라벨만 SemiBold다. 채움 전환 · 색과 함께 세 가지가 겹친다 —
                // 색만으로 구분하지 않는다(COMPONENT-MAP 3장 #6).
                Text(tab.title)
                    .mmTextStyle(MMFont.labelS)
                    .fontWeight(isActive ? .semibold : nil)
            }
            .foregroundStyle(isActive ? MMColor.fgPrimary : MMColor.fgSubtle)
            .frame(maxWidth: .infinity)
            .frame(height: TabBarMetrics.itemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

private enum TabBarMetrics {
    static let hairline: CGFloat = 1
    static let itemHeight: CGFloat = 46
}

extension Tab {
    var title: String {
        switch self {
        case .calendar: "캘린더"
        case .home: "홈"
        case .record: "기록"
        }
    }

    var icon: MMIcon {
        switch self {
        case .calendar: .calendar
        case .home: .home
        case .record: .note
        }
    }

    /// 활성 전용 채움형. 획형과 같은 기하로 그려 실루엣이 정확히 겹친다.
    var filledIcon: MMIcon {
        switch self {
        case .calendar: .calendarFilled
        case .home: .homeFilled
        case .record: .noteFilled
        }
    }
}

#Preview {
    @Previewable @State var tab: Tab = .home
    return VStack {
        Spacer()
        MMTabBar(selection: $tab)
    }
    .background(MMColor.bgCanvas)
}
