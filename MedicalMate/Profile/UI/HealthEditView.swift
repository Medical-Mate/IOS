import SwiftUI

/// `1s-2 · 건강 정보 수정` (Figma `3663:15798`).
///
/// 세 갈래를 한 화면에서 고치고 아래의 두 버튼으로 닫는다. 내비는 **닫기**다 —
/// 저장하지 않고 나가는 길이 아래에도 있어서 뒤로가기가 아니다.
///
/// `+ 직접 추가` 칩 뒤에 무엇이 나오는지는 Figma에 없다. 1b의 "직접 입력" 칸과 같은
/// 방식으로 뒀다(COMPONENT-MAP 3장 #24).
struct HealthEditView: View {
    @Environment(\.appEnvironment) private var app
    @State private var model: HealthEditModel?

    var onClose: () -> Void = {}
    var onSaved: () -> Void = {}

    /// 갈래의 제목. 1b의 질문("지금 드시는 약이 있나요?")이 아니라 명사다.
    private static let titles = ["복용 중인 약", "기저질환", "알러지"]

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil { model = HealthEditModel(repository: app.healthProfile) }
            await model?.load()
        }
    }

    private func content(_ model: HealthEditModel) -> some View {
        VStack(spacing: 0) {
            MMNavBar(title: "건강 정보 수정", leading: .close, onLeading: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: HealthEditMetrics.sectionGap) {
                    MMNotice(
                        title: "바꾸면 다음 브리핑 카드부터 반영돼요",
                        message: "이미 만든 카드는 그대로 남고,\n새로 만드는 카드에 적용됩니다.",
                        tone: .info
                    )

                    ForEach(Array(Self.titles.enumerated()), id: \.offset) { index, title in
                        group(model, step: index, title: title)
                    }

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
    }

    private func group(_ model: HealthEditModel, step: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s10) {
            Text(title)
                .mmTextStyle(MMFont.headingS)
                .foregroundStyle(MMColor.fgDefault)

            MMWrap {
                ForEach(model.options(step), id: \.self) { option in
                    MMChip(text: option, isSelected: model.isPicked(step, option)) {
                        model.toggle(step, option)
                    }
                }
                MMChip(text: "+ 직접 추가") { model.startAdding(step) }
            }

            if model.adding == step {
                adder(model)
            }
        }
    }

    private func adder(_ model: HealthEditModel) -> some View {
        @Bindable var model = model
        return HStack(spacing: MMSpace.s8) {
            MMTextField(
                label: "직접 입력",
                text: $model.draft,
                placeholder: "목록에 없으면 여기에 적어주세요"
            )
            MMButton("추가", kind: .outline, size: .m) { model.commitDraft() }
                .disabled(!model.canAddDraft)
                .frame(width: HealthEditMetrics.addButton)
        }
    }

    private func footer(_ model: HealthEditModel) -> some View {
        VStack(spacing: MMSpace.s12) {
            MMButton("저장하기", kind: .primary) {
                Task { if await model.save() { onSaved() } }
            }
            .disabled(model.isSaving)

            MMButton("취소", kind: .outline, action: onClose)
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.vertical, MMSpace.s12)
        .background(MMColor.bgSurface)
    }
}

private enum HealthEditMetrics {
    static let sectionGap: CGFloat = 18
    static let addButton: CGFloat = 84
}

#Preview {
    HealthEditView()
}
