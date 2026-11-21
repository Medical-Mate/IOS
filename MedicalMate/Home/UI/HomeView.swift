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
    /// 일정 추가로 간다. 값이 있으면 **그 카드를 들고 간다**(배너 1의 `cardReady`).
    /// 배너 3은 들고 갈 카드가 없다.
    var onScheduleCard: (Int64?) -> Void = { _ in }
    /// 배너 5의 "메이트에게 말해보기". **호출어 없이 여는 길이다.**
    var onTalkToMate: () -> Void = {}

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
    private func onBannerLink(_ page: HomeBannerPage) {
        switch page {
        case .today(_, let cardId, _, _): onRecordVisit(cardId)
        case .tomorrow(_, _, let cardId): onOpenCardId(cardId)
        case .cardReady(let cardId, _): onScheduleCard(cardId)
        case .saveCard(let cardId):
            // 카드가 없으면 목록으로 간다.
            if let cardId { onOpenCardId(cardId) } else { onOpenCardList() }
        // **들고 갈 카드가 없다.** 전에는 0을 넘겨서, 있지도 않은 0번 카드가
        // 골라진 채로 저장될 뻔했다.
        case .schedule: onScheduleCard(nil)
        // **호출어 없이 메이트를 연다.** 배너는 호출어 모델을 받지 않은 사람에게도
        // 보이고, 받아쓰기만으로 듣는다 — Android도 같은 자리다(#312).
        case .mate: onTalkToMate()
        // 예약 문자 공유는 Share Extension이 서야 갈 곳이 생긴다(M4).
        case .message, .welcome: break
        }
    }

    private func banner(_ model: HomeModel) -> some View {
        HomeBannerCarousel(
            pages: model.banners,
            initial: "김",
            onNotification: onNotification,
            onAvatar: onProfile,
            onLink: onBannerLink
        )
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
