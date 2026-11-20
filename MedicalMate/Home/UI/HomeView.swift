import SwiftUI

/// `1n-2 · 홈 · 처음` (Figma `3663:7007`) · `1n-1 · 홈 · 기록 있음` (`3663:7014`).
///
/// 맨 위 사진 배너 아래로 **흰 시트가 28 겹쳐 올라오고** 탭바만 고정된다. 시트는
/// 반경 28 · `Elevation/Sheet` · pt28 pb20 px20 · 묶음 사이 12다.
///
/// 시트 차례는 증상 정리 시작하기(`Card / Action`) → 최근 브리핑 카드 → 다가오는 일정.
/// 기록이 없으면 카드 아래가 `Empty State`로 바뀐다(`1n-2`).
struct HomeView: View {
    @Environment(\.appEnvironment) private var app
    @State private var model: HomeModel?

    var onStartIntake: () -> Void = {}
    var onOpenCard: (HomeCard) -> Void = { _ in }
    var onOpenCardList: () -> Void = {}
    var onOpenCalendar: () -> Void = {}
    var onOpenSchedule: (HomeSchedule) -> Void = { _ in }
    var onNotification: () -> Void = {}
    var onProfile: () -> Void = {}

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil {
                let created = HomeModel(repository: app.home)
                model = created
            }
            await model?.load()
        }
    }

    private func content(_ model: HomeModel) -> some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    banner(model)
                    sheet(model)
                        // 시트가 배너 위로 28 겹쳐 올라온다.
                        .offset(y: -HomeMetrics.overlap)
                        .padding(.bottom, -HomeMetrics.overlap)
                }
                // 탭바가 콘텐츠 위에 겹치므로 그만큼 비워 둔다.
                .padding(.bottom, MMSize.tabBarHeight)
            }
            .environment(\.mmSafeAreaTop, geo.safeAreaInsets.top)
            .ignoresSafeArea(edges: .top)
        }
        .background(MMColor.bgSurface)
    }

    private func banner(_ model: HomeModel) -> some View {
        let kind = model.banner
        return MMHomeBanner(
            title: kind.title,
            message: kind.message,
            link: kind.link.map { ($0.title, $0.counter, {}) },
            initial: "김",
            onNotification: onNotification,
            onAvatar: onProfile
        ) {
            // 첫 홈 사진만 에셋에 있다. 나머지 넷은 디자인 트랙에서 받아야 한다
            // (docs/COMPONENT-MAP.md 3장).
            if kind == .first {
                Image("home-banner-first")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.clear
            }
        }
    }

    private func sheet(_ model: HomeModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s12) {
            MMCardAction(caption: "진료 전에", title: "증상 정리 시작하기", action: onStartIntake)

            if model.summary.recentCards.isEmpty {
                MMEmptyState(kind: .noRecord, onAction: onStartIntake)
            } else {
                MMSectionHeader(title: "최근 브리핑 카드", actionTitle: "전체 보기", onAction: onOpenCardList)

                ForEach(model.summary.recentCards) { card in
                    MMListRow(
                        title: card.title,
                        meta: card.meta,
                        badge: card.badge,
                        action: { onOpenCard(card) }
                    )
                }
            }

            if let schedule = model.summary.upcoming {
                MMSectionHeader(title: "다가오는 일정", actionTitle: "캘린더", onAction: onOpenCalendar)
                MMCardSchedule(
                    month: schedule.month,
                    day: schedule.day,
                    meta: schedule.meta,
                    title: schedule.title,
                    dday: schedule.dday,
                    action: { onOpenSchedule(schedule) }
                )
            }

            if let message = model.errorMessage {
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgDanger)
            }
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMRadius.xxl)
        .padding(.bottom, MMSpace.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgSurface)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: MMRadius.xxl,
                topTrailingRadius: MMRadius.xxl
            )
        )
        .mmShadow(MMElevation.sheet)
    }
}

private enum HomeMetrics {
    /// 시트가 배너를 덮는 깊이.
    static let overlap: CGFloat = MMRadius.xxl
}

#Preview {
    HomeView()
}
