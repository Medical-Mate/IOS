import SwiftUI

/// 1o 로그인.
///
/// 카카오 버튼은 디자인 시스템의 `Social Login Button / Provider=Kakao`(`383:1290`)다.
///
/// **화면 전체는 아직 Figma 와이어프레임(`1o`)과 대조하지 않았다.** 지금 있는 것은
/// 컴포넌트를 올려 둔 골격이고, 제목·안내 문구와 배치는 시안을 열어 맞춘다.
struct LoginView: View {
    @Environment(\.appEnvironment) private var app
    @Environment(SessionModel.self) private var session
    @State private var model: LoginModel?

    var body: some View {
        VStack(spacing: MMSpace.s16) {
            Spacer()

            Text("진료메이트")
                .mmTextStyle(MMFont.displayM)
                .foregroundStyle(MMColor.fgDefault)

            Text("진료실에서 하고 싶은 말을 미리 정리해요")
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgSubtle)

            Spacer()

            if let message = model?.errorMessage {
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgDanger)
                    .multilineTextAlignment(.center)
            }

            kakaoButton

            Spacer().frame(height: MMSize.safeBottom)
        }
        .padding(.horizontal, MMSize.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MMColor.bgSurface)
        .onAppear {
            if model == nil {
                model = LoginModel(auth: app.auth, session: session)
            }
        }
    }

    private var kakaoButton: some View {
        MMSocialLoginButton(provider: .kakao) {
            Task { await model?.logIn() }
        }
        .disabled(model?.isWorking ?? false)
    }
}
