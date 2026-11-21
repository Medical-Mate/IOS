import SwiftUI

/// `V2 · 로그인` (Figma `3663:6850`).
///
/// 흰 면에 위아래 여백을 벌려 Hero를 가운데보다 조금 위에 두고, 아래에 간편 로그인과
/// 안내를 둔다. 좌우는 거터 20, 위아래 24다.
///
/// Figma `Social Login Stack`(`383:1303`) 설명:
/// > 간편 로그인 3종 세로 스택. 간격 10. 순서는 국내 사용률 기준 카카오 → 네이버 →
/// > Apple이다. **iOS 심사 규정상 다른 소셜 로그인을 제공하면 Apple 로그인도 함께
/// > 제공해야 한다.**
///
/// **이 화면의 마스터에는 카카오 하나만 올라와 있다.** 백엔드가 `kakaoId` 하나만 알고
/// 있어서 지금 켤 수 있는 것도 그것뿐이다. Apple 로그인은 백엔드 스키마가 바뀌어야
/// 하고, 그 결정은 `docs/AOS-IOS-DIFF.md`의 D3다 — **디자인 쪽도 같은 이야기를 적어
/// 두었다는 점을 그 문서에 반영했다.**
struct LoginView: View {
    @Environment(\.appEnvironment) private var app
    @Environment(SessionModel.self) private var session
    @State private var model: LoginModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            hero
            Spacer(minLength: 0)
            actions
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.vertical, MMSpace.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MMColor.bgSurface)
        .onAppear {
            if model == nil {
                model = LoginModel(auth: app.auth, session: session)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: MMSpace.s20) {
            MMLogo.Lockup.flat.view()

            Text("진료실에서 하고 싶은 말,\n미리 정리해요")
                .mmTextStyle(MMFont.headingL)
                .foregroundStyle(MMColor.fgDefault)

            Text("증상을 기억하지 못해도, 말이 잘 안 나와도 괜찮아요.\nAI와 대화하면 진료 전에 정리해드려요.")
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgSubtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: MMSpace.s20) {
            if let message = model?.errorMessage {
                // 로그인 화면의 안내는 대비 기준을 넘는 색으로 둔다(마스터의 주의).
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Social Login Stack · 간격 10. 지금은 카카오 하나다.
            VStack(spacing: MMSpace.s10) {
                MMSocialLoginButton(provider: .kakao) {
                    Task { await model?.logIn() }
                }
                .disabled(model?.isWorking ?? false)
            }

            legal
        }
    }

    /// 의료 자문이 아님을 알리는 고지. 11/14로 본문보다 더 눌러 둔다 — `Label/S`(16)와
    /// 행간이 달라 마스터 값을 그대로 적는다.
    private var legal: some View {
        Text("진료메이트가 정리한 내용은 진료를 돕기 위한 참고 자료예요.\n진단이나 처방이 아니니 최종 판단은 의료진과 상의해 주세요.")
            .mmTextStyle(LoginMetrics.legal)
            // **`fg/subtle`이다.** `fg/muted`는 3.78:1이라 토큰 설명이 글자에 쓰지
            // 말라고 못박았고, 캡션은 `fg/subtle`을 쓰라고 적었다. 11pt로 가장 작은
            // 글자라 더욱 그렇다. Android의 `LoginScreen`도 `fgSubtle`이다.
            .foregroundStyle(MMColor.fgSubtle)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum LoginMetrics {
    static let legal = MMTextStyle(weight: .regular, size: 11, lineHeight: 14, letterSpacingPercent: 2.0)
}

#Preview {
    LoginView()
        .environment(SessionModel(tokens: TokenStore(), auth: AppEnvironment().auth))
}
