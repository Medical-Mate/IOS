import SwiftUI

/// 디자인 시스템 `Social Login Button` (Figma `383:1302`).
///
/// Figma 설명 그대로:
/// > **[브랜드 예외]** 간편 로그인 버튼. 색이 각 사 가이드라인으로 정해져 있어 **이
/// > 컴포넌트만 토큰을 쓰지 않는다.** 높이 56 · 반경 16 · 라벨 Label/L — 크기와 반경은
/// > Button L과 맞춰 화면에서 이질감이 없게 했다. 로고는 직접 그리지 않았다. 각 사
/// > 상표라 반드시 **공식 개발자 키트의 에셋으로 교체**해야 한다. 왼쪽 20×20 반투명
/// > 사각이 그 자리다.
/// > **[대비 주의]** 네이버 `#03C75A` + 흰 글자는 2.2:1로 WCAG 기준을 넘지 못한다.
/// > 네이버 공식 규격이라 바꿀 수 없고 이 버튼만 예외로 둔다. **로그인 화면의 다른
/// > 안내는 반드시 기준을 넘는 색으로 둔다.**
/// > 인스턴스를 붙여 쓰기만 하고 색·크기를 임의로 바꾸지 않는다. 각 사 심사에서 반려된다.
///
/// 카카오 심볼은 디자인 시스템이 들고 있는 공식 로고(`3004:18434`)를 PDF로 내려
/// `KakaoSymbol` 에셋에 넣었다. 나머지 셋은 Figma와 똑같이 **빈 자리(반투명 사각)**로
/// 둔다 — 상표를 임의로 그리지 않는다. 쓰기 전에 각 사 키트의 에셋으로 채운다.
struct MMSocialLoginButton: View {
    enum Provider { case kakao, naver, apple, google }

    let provider: Provider
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metrics.gap) {
                logo
                Text(provider.title)
                    .mmTextStyle(MMFont.labelL)
                    .foregroundStyle(provider.label)
                    .lineLimit(1)
            }
            .padding(.horizontal, MMSpace.s20)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.height)
            .background(provider.container)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
            .overlay {
                if let border = provider.border {
                    RoundedRectangle(cornerRadius: MMRadius.md)
                        .strokeBorder(border, lineWidth: 1)
                }
            }
        }
        .accessibilityLabel(provider.title)
    }

    @ViewBuilder
    private var logo: some View {
        switch provider {
        case .kakao:
            Image("KakaoSymbol")
                .resizable()
                .frame(width: Metrics.logo, height: Metrics.logo)
        case .naver, .apple, .google:
            // 공식 에셋이 들어갈 자리. Figma 마스터의 반투명 사각 그대로다.
            RoundedRectangle(cornerRadius: 4)
                .fill(provider.logoSlot)
                .frame(width: Metrics.logo, height: Metrics.logo)
        }
    }

    private enum Metrics {
        /// Button L과 같은 높이다. 한 화면에 섞여도 이질감이 없게 맞춘 값이다.
        static let height: CGFloat = MMSize.controlLg
        static let gap: CGFloat = MMSpace.s10
        static let logo: CGFloat = MMSize.iconMd
    }
}

private extension MMSocialLoginButton.Provider {
    var title: String {
        switch self {
        case .kakao: "카카오로 시작하기"
        case .naver: "네이버로 시작하기"
        case .apple: "Apple로 시작하기"
        case .google: "Google로 시작하기"
        }
    }

    var container: Color {
        switch self {
        case .kakao: BrandColor.kakaoContainer
        case .naver: BrandColor.naverContainer
        case .apple: BrandColor.appleContainer
        case .google: BrandColor.googleContainer
        }
    }

    var label: Color {
        switch self {
        case .kakao: BrandColor.kakaoLabel
        case .naver: BrandColor.naverLabel
        case .apple: BrandColor.appleLabel
        case .google: BrandColor.googleLabel
        }
    }

    var border: Color? {
        self == .google ? BrandColor.googleBorder : nil
    }

    /// 로고가 들어갈 빈 자리의 색.
    var logoSlot: Color {
        switch self {
        case .google: Color(hex: 0x1F1F1F, opacity: 0.14)
        default: Color(hex: 0xFFFFFF, opacity: 0.14)
        }
    }
}

#Preview {
    VStack(spacing: MMSpace.s12) {
        MMSocialLoginButton(provider: .kakao) {}
        MMSocialLoginButton(provider: .naver) {}
        MMSocialLoginButton(provider: .apple) {}
        MMSocialLoginButton(provider: .google) {}
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
