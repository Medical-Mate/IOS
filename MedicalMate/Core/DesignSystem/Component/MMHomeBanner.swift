import SwiftUI

/// 디자인 시스템 `Link / On Image` (Figma `3313:4925`).
///
/// Figma 설명 그대로: **사진 배너 하단 텍스트 링크 + 장 수.** 글자·화살표 `neutral/0`,
/// 위 구분선 `border/on-dark`.
struct MMLinkOnImage: View {
    let title: String
    /// "1 / 5"처럼 몇 번째 장인지.
    let counter: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                HStack(spacing: MMSpace.s2) {
                    Text(title).mmTextStyle(MMFont.bodyMStrong)
                    MMIcon.chevronRight.view(size: MMSize.iconSm)
                }
                Spacer(minLength: 0)
                Text(counter).mmTextStyle(MMFont.labelM)
            }
            .foregroundStyle(MMColor.fgOnInverse)
            .padding(.top, MMSpace.s4)
            .frame(height: MMSize.controlMd)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(MMColor.borderOnDark)
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

/// 디자인 시스템 `Home Banner` (Figma `3317:5085`).
///
/// Figma 설명 그대로:
/// > 홈 맨 위 사진 배너 360×400. Banner = 1 오늘의 한 줄 · 2 예약 문자 · 3 일정 알림 ·
/// > 4 이미지 저장 · 5 헤이 메이트. **CTA = Link(하단 링크 + 장 수) · None(첫 홈, 334,
/// > 링크·장 수 없음).** 헤더는 홈 1n-1과 같은 좌우 20, 흰 로고·아이콘.
/// > **글자·아이콘 그림자는 `Shadow/On Image`.**
///
/// Android는 글자 그림자를 두 겹 내려고 **글자를 두 번 겹쳐 그렸다**. iOS는 `.shadow`를
/// 중첩할 수 있어 ``MMElevation/onImageText``를 한 번 입히면 된다.
///
/// 배너 사진은 Figma가 이미지 레이어에 건 필터(밝기 · 색온도)까지 적용된 내보내기다.
/// **원본 사진은 훨씬 밝아 그대로 쓰면 흰 글자가 읽히지 않는다.** 지금 에셋에 들어온
/// 것은 첫 홈(`1 오늘의 한 줄 · CTA=None`)의 사진 하나이고, 나머지 다섯 장은 디자인
/// 트랙에서 받아야 한다(`docs/COMPONENT-MAP.md`).
struct MMHomeBanner<Photo: View>: View {
    let title: String
    let message: String
    /// 아래 링크. 첫 홈(`CTA=None`)은 `nil`이다.
    var link: (title: String, counter: String, action: () -> Void)?
    /// 헤더 아바타에 넣을 한 글자.
    var initial: String
    var onNotification: () -> Void
    var onAvatar: () -> Void
    @ViewBuilder var photo: Photo

    var body: some View {
        ZStack(alignment: .top) {
            MMColor.bgInverse
            photo
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: 0)
                content
            }
        }
        .frame(width: MMSize.canvasWidth, height: link == nil ? BannerMetrics.firstHeight : BannerMetrics.height)
        .clipped()
    }

    private var header: some View {
        HStack(spacing: 0) {
            MMLogo.Lockup.monoLight.view(height: BannerMetrics.lockupHeight)
                .foregroundStyle(MMColor.fgOnInverse)
                .mmShadow(MMElevation.onImageIcon)

            Spacer(minLength: 0)

            Button(action: onNotification) {
                MMIcon.bell.view()
                    .foregroundStyle(MMColor.fgOnInverse)
                    .frame(width: MMSize.controlMd, height: MMSize.controlMd)
                    .contentShape(Rectangle())
                    .mmShadow(MMElevation.onImageIcon)
            }
            .accessibilityLabel("알림")

            Button(action: onAvatar) {
                Text(initial)
                    .mmTextStyle(MMFont.bodyMStrong)
                    .foregroundStyle(MMColor.fgOnInverse)
                    .frame(width: BannerMetrics.avatar, height: BannerMetrics.avatar)
                    .background(MMColor.bgOnDark)
                    .clipShape(Circle())
                    .overlay { Circle().strokeBorder(MMColor.borderOnDark, lineWidth: 1) }
                    .frame(width: MMSize.controlMd, height: MMSize.controlMd)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("내 정보")
        }
        .padding(.horizontal, MMSize.gutter)
        .frame(height: MMSize.navBarHeight)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: MMSpace.s10) {
            Text(title)
                .mmTextStyle(MMFont.displayM)
                .foregroundStyle(MMColor.fgOnInverse)
                .mmShadow(MMElevation.onImageText)

            Text(message)
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgOnInverse)
                .mmShadow(MMElevation.onImageText)

            if let link {
                MMLinkOnImage(title: link.title, counter: link.counter, action: link.action)
                    .padding(.top, MMSpace.s8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MMSize.gutter)
        .padding(.bottom, BannerMetrics.bottomInset)
    }
}

private enum BannerMetrics {
    static let height: CGFloat = 400
    /// 첫 홈은 링크가 없어 더 낮다.
    static let firstHeight: CGFloat = 334
    static let avatar: CGFloat = 36
    static let lockupHeight: CGFloat = 29.525
    /// 아래 흰 시트가 28 겹쳐 올라오는 자리를 비워 둔다.
    static let bottomInset: CGFloat = MMSize.navBarHeight
}

#Preview {
    ScrollView {
        VStack(spacing: MMSpace.s16) {
            MMHomeBanner(
                title: "처음 오셨네요,\n반가워요",
                message: "아픈 곳을 짚고 몇 가지만 답하면\n진료실에서 보여줄 카드가 돼요.",
                initial: "김",
                onNotification: {},
                onAvatar: {}
            ) {
                Image("home-banner-first")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }

            MMHomeBanner(
                title: "진료 잘\n다녀오셨나요?",
                message: "서울OO병원 내과에서 들은 말을\n잊기 전에 남겨두세요.",
                link: ("진료 후 기록하기", "1 / 5", {}),
                initial: "김",
                onNotification: {},
                onAvatar: {}
            ) {
                Color.clear
            }
        }
    }
    .background(MMColor.bgCanvas)
}
