import SwiftUI

/// 홈 맨 위 사진 배너 다섯 장. Figma `1n-1` · `1n-2`.
///
/// **4초마다 한 장씩 넘어가고 끝에서 첫 장으로 돈다**(`docs/FEATURE-SPEC.md` 2.9).
/// 손으로 넘기는 동안은 세지 않고, **기기에서 애니메이션을 껐으면 저절로 넘기지
/// 않는다**(Reduce Motion).
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
            ForEach(Array(pages.enumerated()), id: \.offset) { offset, item in
                page(item, at: offset, showsHeader: false)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: BannerCarouselMetrics.height + safeAreaTop)
        .task(id: reduceMotion) { await autoAdvance() }
    }

    /// 저절로 넘기기. **애니메이션을 끈 기기에서는 돌지 않는다.**
    private func autoAdvance() async {
        guard !reduceMotion, isLooping else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(BannerCarouselMetrics.dwell))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: BannerCarouselMetrics.transition)) {
                index = (index + 1) % pages.count
            }
        }
    }

    private func page(_ item: HomeBannerPage, at offset: Int, showsHeader: Bool) -> some View {
        MMHomeBanner(
            title: HomeBannerCopy.title(item),
            message: HomeBannerCopy.message(item),
            link: HomeBannerCopy.link(item, index: offset, total: pages.count)
                .map { ($0.title, $0.counter, { onLink(item) }) },
            initial: initial,
            onNotification: onNotification,
            onAvatar: onAvatar,
            showsHeader: showsHeader
        ) {
            Image(item.photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }

    /// 넘기는 동안 제자리에 있는 헤더.
    private var header: some View {
        MMHomeHeader(initial: initial, onNotification: onNotification, onAvatar: onAvatar)
    }

    @Environment(\.mmSafeAreaTop) private var safeAreaTop
}

private enum BannerCarouselMetrics {
    /// `CTA=Link` 배너의 높이.
    static let height: CGFloat = 400
    /// 한 장이 머무는 시간.
    static let dwell: Double = 4
    /// 넘어가는 데 걸리는 시간.
    static let transition: Double = 0.5
}
