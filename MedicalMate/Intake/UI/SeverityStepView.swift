import SwiftUI

/// `1d · 통증 강도 (2/3)` (Figma `3663:7170`).
///
/// 짚은 부위를 그대로 물음에 넣는다 — "복부가 얼마나 아프세요?". 아래 `Notice`가
/// **숫자는 의사가 읽고 환자는 낱말로 고른다**는 것을 말한다. 슬라이더는 드래그와
/// 정지점 탭 둘 다 받는다.
struct SeverityStepView: View {
    @Bindable var model: IntakeModel
    let onBack: () -> Void

    private var question: String {
        let site = model.site.text
        return "\(site)\(KoreanParticle.subject(after: site)) 얼마나 아프세요?"
    }

    var body: some View {
        VStack(spacing: 0) {
            MMNavBar(title: "증상 정리", leading: .back, onLeading: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: MMSpace.s20) {
                    MMProgressIndicator(
                        label: IntakeStep.label,
                        step: IntakeStep.severity.rawValue,
                        total: IntakeStep.total
                    )

                    VStack(alignment: .leading, spacing: MMSpace.s8) {
                        Text(question)
                            .mmTextStyle(MMFont.headingL)
                            .foregroundStyle(MMColor.fgDefault)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("지금 느끼는 정도를 골라주세요.\n정확한 숫자가 아니어도 괜찮아요.")
                            .mmTextStyle(MMFont.bodyM)
                            .foregroundStyle(MMColor.fgSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, MMSpace.s8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    MMSeveritySlider(level: $model.severity)

                    MMNotice(
                        title: "숫자는 진료실에서 의사가 읽어요",
                        message: "환자분은 낱말로 고르시면 돼요.\n카드에는 NRS 등가로 함께 표시됩니다.",
                        tone: .info
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

            VStack(spacing: 0) {
                MMButton("다음") {
                    Task { await model.confirmSeverity() }
                }
                .disabled(model.isBusy)
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.top, MMSpace.s12)
            .padding(.bottom, MMSize.safeBottom)
            .background(MMColor.bgSurface)
        }
        .background(MMColor.bgSurface)
    }
}
