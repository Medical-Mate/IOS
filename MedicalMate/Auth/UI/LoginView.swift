import SwiftUI

/// 1o 로그인.
///
/// **아직 Figma 마스터를 대조하지 않은 골격이다.** 카카오 버튼은 디자인 시스템의
/// `Social Login Button / Provider=Kakao`(`383:1290`)로 교체한다. 그 마스터 안에 말풍선
/// 심볼이 들어 있어 콘솔에서 따로 받지 않는다.
///
/// 브랜드 색은 ``BrandColor``에서 읽는다. 카카오 디자인 가이드가 변경을 금지하므로
/// 테마를 타지 않는다.
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
        Button {
            Task { await model?.logIn() }
        } label: {
            Text("카카오로 시작하기")
                .mmTextStyle(MMFont.labelL)
                .foregroundStyle(BrandColor.kakaoLabel)
                .frame(maxWidth: .infinity)
                .frame(height: MMSize.controlLg)
                .background(BrandColor.kakaoContainer)
                .clipShape(RoundedRectangle(cornerRadius: MMRadius.sm))
        }
        .disabled(model?.isWorking ?? false)
        .accessibilityLabel("카카오로 시작하기")
    }
}
