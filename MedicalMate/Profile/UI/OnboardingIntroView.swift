import SwiftUI

/// 온보딩 한 장이 들고 있는 말과 그림.
///
/// 문구는 Figma 와이어프레임 `V2-00` ~ `V2-03`(`3663:6862` · `6876` · `6890` · `6904`)에서
/// 그대로 가져왔다.
struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let body: String
    let illustration: MMIllustration
    /// 그림의 **원래 크기**. 칸에 맞춰 줄이지 않는다 — 마스터의 규칙이다.
    let artSize: CGSize

    static let all: [OnboardingPage] = [
        .init(
            id: 1,
            title: "말하기 어려웠던 증상,\n함께 준비해요.",
            body: "아픈 곳을 짚고, 증상을 말해 주세요.\n진료 전에 보여줄 카드부터\n진료 후 기록까지 함께 정리해요.",
            illustration: .onboarding1,
            artSize: CGSize(width: 326, height: 326)
        ),
        .init(
            id: 2,
            title: "짚어요.",
            body: "정확한 의학 용어를 몰라도 괜찮아요.\n아픈 부위를 먼저 고르고,\n이어지는 질문에 편하게 답해 주세요.",
            illustration: .onboarding2,
            artSize: CGSize(width: 342, height: 228)
        ),
        .init(
            id: 3,
            title: "정리해요.",
            body: "말한 증상은 AI가 한 장으로 정리해요.\n직접 확인하고 고친 뒤,\n진료실에서 의료진에게 보여 주세요.",
            illustration: .onboarding3,
            artSize: CGSize(width: 340, height: 340)
        ),
        .init(
            id: 4,
            title: "이어가요.",
            body: "진료에서 들은 말과 처방을 기록해요.\n다음 진료 일정까지 한곳에서,\n다시 준비할 때 꺼내 볼 수 있어요.",
            illustration: .onboarding4,
            artSize: CGSize(width: 307, height: 307)
        )
    ]
}

/// `V2-00` ~ `V2-03` 온보딩 (Figma `3663:6862` · `6876` · `6890` · `6904`).
///
/// 네 장이 같은 골격이다 — 상단 바(진행 표시 + 건너뛰기) · 본문(제목 + 설명 + 일러스트)
/// · 하단 버튼. 위 여백 72, 묶음 사이 24, 좌우 거터 20이다.
///
/// Figma `Onboarding Illustration`(`3610:10270`) 설명:
/// > 이미지 **원래 크기·비율 그대로**(1/4 326×326 · 2/4 342×228 · 3/4 340×340 ·
/// > 4/4 307×307). 화면에서는 **일러스트 칸 320×340 가운데**에 둔다.
///
/// 마지막 장만 버튼이 "시작하기"다. 건너뛰기는 네 장 모두에 있다.
struct OnboardingIntroView: View {
    /// 소개가 끝났을 때. 건너뛰기도 같은 곳으로 간다 — 소개만 건너뛰는 것이다.
    var onFinish: () -> Void = {}

    @State private var index = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var page: OnboardingPage { OnboardingPage.all[index] }
    private var isLast: Bool { index == OnboardingPage.all.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MMColor.bgSurface)
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            // 왼쪽은 "건너뛰기"와 같은 폭을 비워 진행 표시를 가운데에 묶어 둔다.
            Color.clear.frame(width: OnboardingMetrics.leftSpace, height: 1)

            MMOnboardingProgress(step: index + 1)
                .frame(maxWidth: .infinity)

            Button(action: onFinish) {
                Text("건너뛰기")
                    .mmTextStyle(MMFont.bodyLStrong)
                    .foregroundStyle(MMColor.fgSubtle)
            }
        }
        .padding(.horizontal, MMSize.gutter)
        .frame(height: MMSize.navBarHeight)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: MMSpace.s24) {
            VStack(alignment: .leading, spacing: MMSpace.s24) {
                Text(page.title)
                    .mmTextStyle(MMFont.displayM)
                    .foregroundStyle(MMColor.fgDefault)
                Text(page.body)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(MMColor.fgSubtle)
            }
            // 글은 줄지 않는다. 화면이 좁으면 일러스트 칸이 먼저 줄어든다 —
            // 작은 기기에서 제목이 잘리면 무슨 화면인지 알 수 없게 된다.
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            // **그림을 칸에 맞춰 줄이지 않는다.** 마스터(`3610:10270`)가 "이미지
            // 원래 크기·비율 그대로"라고 못박았고 네 장의 크기를 적어 두었다
            // (1/4 326 · 2/4 342×228 · 3/4 340 · 4/4 307). **2/4와 3/4는 콘텐츠
            // 폭 320보다 넓어 좌우 거터로 조금 나간다 — 시안도 그렇다.** 칸의 폭에
            // 맞춰 줄이면 세 장이 최대 6% 작아진다. Android도 `requiredSize`로 둔다.
            page.illustration.view()
                .frame(width: page.artSize.width, height: page.artSize.height)
                .frame(maxWidth: .infinity, maxHeight: OnboardingMetrics.illustrationBox.height)
        }
        .padding(.top, OnboardingMetrics.topInset)
        .padding(.bottom, MMSpace.s24)
        .padding(.horizontal, MMSize.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // **장은 겹쳐 바뀐다**(dissolve). 프로토타입(`3663:6862`)의 다음 버튼이
        // `DISSOLVE 350ms EASE_IN_AND_OUT`으로 다음 장을 연다 — 옆으로 밀지 않는다.
        // 되짚을 때도 같다. 240ms는 진행 표시의 값이라 여기 쓰지 않는다.
        // 진행 표시와 하단 버튼은 그대로 둔다 — 함께 바뀌면 몇 번째 장인지가 눈에서
        // 사라지고 손가락이 버튼을 따라다녀야 한다.
        .id(index)
        .transition(.opacity)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: OnboardingMetrics.pageDissolve),
            value: index
        )
    }

    private var footer: some View {
        MMButton(isLast ? "시작하기" : "다음") {
            if isLast {
                onFinish()
            } else {
                index += 1
            }
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSpace.s24)
        .background(MMColor.bgSurface)
    }
}

private enum OnboardingMetrics {
    /// "건너뛰기"와 같은 폭. 진행 표시를 화면 가운데에 두기 위한 자리다.
    static let leftSpace: CGFloat = 59
    static let topInset: CGFloat = 72
    static let illustrationBox = CGSize(width: 320, height: 340)
    /// 장이 겹쳐 바뀌는 시간. 프로토타입(`3663:6862`)의 `DISSOLVE 350ms`다.
    static let pageDissolve: Double = 0.35
}

#Preview {
    OnboardingIntroView()
}
