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

    var onOpenCardList: () -> Void = {}
    var onOpenCard: (HomeCard) -> Void = { _ in }
    var onStartIntake: () -> Void = {}
    var onOpenCalendar: () -> Void = {}
    var onOpenSchedule: (HomeSchedule) -> Void = { _ in }
    var onNotification: () -> Void = {}
    var onProfile: () -> Void = {}
    /// 배너가 가리키는 곳. 갈래마다 다르다(1n-1 · 1n-1-4 · 1n-1-5).
    var onRecordVisit: (Int64) -> Void = { _ in }
    var onOpenCardId: (Int64) -> Void = { _ in }
    var onScheduleCard: (Int64) -> Void = { _ in }

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

    /// 배너 링크가 하는 일.
    private func onBannerLink(_ lead: HomeLead) {
        switch lead {
        case .todayVisit(_, let cardId, _, _): onRecordVisit(cardId)
        case .tomorrowVisit(_, _, let cardId): onOpenCardId(cardId)
        case .cardReady(let cardId, _): onScheduleCard(cardId)
        case .firstVisit, .other: break
        }
    }

    private func banner(_ model: HomeModel) -> some View {
        let lead = model.lead
        return MMHomeBanner(
            title: HomeBannerCopy.title(lead),
            message: HomeBannerCopy.message(lead),
            link: HomeBannerCopy.link(lead).map { ($0.title, $0.counter, { onBannerLink(lead) }) },
            initial: "김",
            onNotification: onNotification,
            onAvatar: onProfile
        ) {
            // **첫 홈(334)의 사진만 에셋에 있다.** 마스터가 "단계별 사진 포함"이라
            // 적어 둔 대로 장마다 사진이 다르고, 400짜리 갈래의 것은 아직 못 받았다.
            // 그 자리는 `bg/inverse`로 둔다 — 가진 사진을 늘려 깔면 시안과 다른 그림이
            // 된다(docs/COMPONENT-MAP.md 3장).
            if lead == .firstVisit {
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
