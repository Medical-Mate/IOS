import SwiftUI

/// `1b-1` ~ `1b-3` 신상정보 (Figma `3663:6919` · `6938` · `6957`).
///
/// 세 단계가 같은 골격이다 — 상단 내비("내 정보 등록") · 진행 표시 `n / 3` · 질문 ·
/// 칩 목록(Wrap) · 직접 입력 · 하단 버튼. 마지막 단계만 버튼이 "완료"다.
///
/// 알러지 단계(`1b-3`)에는 질문 옆에 툴팁이 붙는다. 열면 "브리핑 카드 맨 위에 항상
/// 표시돼요"가 뜬다(`1b-3-T` · `3663:6977`).
struct ProfileSetupView: View {
    @Environment(\.appEnvironment) private var app
    @Environment(SessionModel.self) private var session
    @State private var model: ProfileSetupModel?
    @State private var tooltipOpen = false
    /// 마지막 단계를 저장하면 완료 화면으로 넘어간다.
    @State private var isDone = false

    var body: some View {
        Group {
            if isDone {
                ProfileCompleteView {
                    session.completeOnboarding()
                }
            } else if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil {
                let created = ProfileSetupModel(repository: app.healthProfile)
                model = created
                await created.load()
            }
        }
    }

    private func content(_ model: ProfileSetupModel) -> some View {
        VStack(spacing: 0) {
            MMNavBar(title: "내 정보 등록", leading: .back) {
                model.back()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: MMSpace.s20) {
                    MMProgressIndicator(label: "내 정보 등록", step: model.index + 1, total: model.total)

                    question(model)

                    MMWrap {
                        ForEach(model.step.options, id: \.self) { option in
                            MMChip(text: option, isSelected: model.isPicked(option)) {
                                model.toggle(option)
                            }
                        }
                    }

                    MMTextField(
                        label: "직접 입력",
                        text: Binding(
                            get: { model.typed[model.index] },
                            set: { model.typed[model.index] = $0 }
                        ),
                        placeholder: "목록에 없으면 여기에 적어주세요"
                    )

                    if let message = model.errorMessage {
                        Text(message)
                            .mmTextStyle(MMFont.bodyS)
                            .foregroundStyle(MMColor.fgDanger)
                    }
                }
                .padding(.horizontal, MMSize.gutter)
                .padding(.top, MMSpace.s12)
                .padding(.bottom, MMSpace.s16)
            }
            .scrollBounceBehavior(.basedOnSize)

            footer(model)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MMColor.bgSurface)
        .overlay(alignment: .topTrailing) {
            if tooltipOpen, let text = model.step.tooltip {
                MMTooltipBubble(text: text)
                    .padding(.trailing, MMSize.gutter)
                    .padding(.top, ProfileSetupMetrics.tooltipTop)
            }
        }
    }

    private func question(_ model: ProfileSetupModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s8) {
            HStack(spacing: MMSpace.s8) {
                Text(model.step.question)
                    .mmTextStyle(MMFont.headingL)
                    .foregroundStyle(MMColor.fgDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if model.step.tooltip != nil {
                    MMTooltip(isPresented: $tooltipOpen, label: "알러지를 적는 이유")
                }
            }

            Text(model.step.description)
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgSubtle)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, MMSpace.s8)
    }

    private func footer(_ model: ProfileSetupModel) -> some View {
        MMButton(model.isLast ? "완료" : "다음") {
            tooltipOpen = false
            Task {
                if await model.next() { isDone = true }
            }
        }
        .disabled(model.isSaving)
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSpace.s24)
        .background(MMColor.bgSurface)
    }
}

private enum ProfileSetupMetrics {
    /// 툴팁 말풍선이 뜨는 높이. 마스터(`3663:6997`)가 화면 위에서 179다.
    static let tooltipTop: CGFloat = 179
}

#Preview {
    ProfileSetupView()
        .environment(SessionModel(tokens: TokenStore(), auth: AppEnvironment().auth))
}
