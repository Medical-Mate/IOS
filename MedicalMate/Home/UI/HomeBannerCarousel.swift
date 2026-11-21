import SwiftUI

/// 홈 맨 위 사진 배너 다섯 장. Figma `1n-1` · `1n-2`.
///
/// **4초마다 한 장씩 0.5초에 걸쳐 넘어가고 끝에서 첫 장으로 이음매 없이 돈다**
/// (`docs/FEATURE-SPEC.md` 2.9). 손으로 넘기는 동안은 세지 않고, **기기에서
/// 애니메이션을 껐으면 저절로 넘기지 않는다**(Reduce Motion).
///
/// **이음매가 없으려면 자리를 모듈로로 접으면 안 된다.** 마지막 장에서 0으로
/// 되돌리면 넘어가는 것이 아니라 **앞의 네 장을 거꾸로 되감는다.** Android
/// `HomeBannerPager`가 장 수를 아주 크게 잡고 가운데에서 시작하는 까닭이고
/// 여기서도 같게 했다 — 자리는 늘 앞으로만 가고 그릴 때만 접는다.
///
/// 헤더는 한 번만 그리고 사진과 글만 넘어간다 — 다섯 장이 같은 헤더를 들고 함께
/// 미끄러지면 로고와 아바타가 흔들린다.
struct HomeBannerCarousel: View {
    let pages: [HomeBannerPage]
    let initial: String
    var onNotification: () -> Void = {}
    var onAvatar: () -> Void = {}
    var onLink: (HomeBannerPage) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 접지 않은 자리. 늘 앞으로만 간다.
    @State private var index = 0

    private var isLooping: Bool { pages.count > 1 }

    var body: some View {
        ZStack(alignment: .top) {
            if pages.isEmpty {
                Color.clear
            } else if isLooping {
                carousel
            } else {
                page(pages[0], at: 0, showsHeader: true)
            }

            if isLooping {
                header
            }
        }
    }

    private var carousel: some View {
        TabView(selection: $index) {
            ForEach(0..<BannerCarouselMetrics.loopPages, id: \.self) { slot in
                page(pages[slot % pages.count], at: slot % pages.count, showsHeader: false)
                    .tag(slot)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: BannerCarouselMetrics.height + safeAreaTop)
        // **장이 바뀔 때마다 처음부터 센다.** 손으로 넘긴 것도 마찬가지다 — 3.9초에
        // 손으로 넘기고 0.1초 뒤에 또 넘어가면 방금 넘긴 장을 보지 못한다.
        // Android도 `settledPage`가 바뀔 때마다 다시 센다.
        .task(id: BannerTick(index: index, reduceMotion: reduceMotion)) { await autoAdvance() }
        .task { index = BannerCarouselMetrics.start(for: pages.count) }
    }

    /// 저절로 넘기기. **애니메이션을 끈 기기에서는 돌지 않는다.**
    ///
    /// 한 번만 넘기고 끝낸다 — 자리가 바뀌면 `task`가 다시 불린다. Android가
    /// `#322`에서 손이 닿아 있는지까지 봐야 했던 것은 그쪽 페이저가 **닿는 순간
    /// 넘기던 동작을 취소**하기 때문인데, 여기서는 자리를 바꾸는 것뿐이라 그럴 일이
    /// 없다. 실제로 `DragGesture`로 닿음을 받아 기다려 봤더니 **페이저가 `onEnded`를
    /// 주지 않아 배너가 영영 멈췄다.** 세는 것을 자리마다 다시 시작하는 것으로 족하다.
    private func autoAdvance() async {
        guard !reduceMotion, isLooping else { return }
        try? await Task.sleep(for: .seconds(BannerCarouselMetrics.dwell))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: BannerCarouselMetrics.transition)) {
            index += 1
        }
    }

    /// `task(id:)`에 넘길 키. 자리나 Reduce Motion이 바뀌면 세는 것을 다시 시작한다.
    private struct BannerTick: Equatable {
        let index: Int
        let reduceMotion: Bool
    }

    private func page(_ item: HomeBannerPage, at offset: Int, showsHeader: Bool) -> some View {
        MMHomeBanner(
            title: HomeBannerCopy.title(item),
            message: HomeBannerCopy.message(item),
            link: HomeBannerCopy.link(item, index: offset, total: pages.count)
                .map { MMBannerLink(title: $0.title, counter: $0.counter) { onLink(item) } },
            initial: initial,
            onNotification: onNotification,
            onAvatar: onAvatar,
            showsHeader: showsHeader
        ) {
            Image(item.photo)
                .resizable().scaledToFill()
        }
    }

    /// 넘기는 동안 제자리에 있는 헤더.
    private var header: some View {
        MMHomeHeader(initial: initial, onNotification: onNotification, onAvatar: onAvatar)
    }

    @Environment(\.mmSafeAreaTop) private var safeAreaTop
}

enum BannerCarouselMetrics {
    /// `CTA=Link` 배너의 높이.
    static let height: CGFloat = 400
    /// 한 장이 머무는 시간.
    static let dwell: Double = 4
    /// 넘어가는 데 걸리는 시간.
    static let transition: Double = 0.5
    /// 접지 않은 자리의 칸 수. 이음매 없이 돌려면 앞으로만 가야 해서 넉넉히 둔다.
    /// Android `LOOP_PAGES`와 같은 뜻이다.
    static let loopPages = 10_000
    /// 시작 자리. 가운데에서 **장 수의 배수**로 맞춰 첫 장이 서게 한다.
    nonisolated static func start(for count: Int) -> Int {
        guard count > 0 else { return 0 }
        let middle = loopPages / 2
        return middle - middle % count
    }
}
