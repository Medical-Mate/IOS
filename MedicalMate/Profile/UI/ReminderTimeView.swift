import SwiftUI

/// `1s-3 · 알림 시간` (Figma `3663:15830`).
///
/// 위 카드가 시간이 **확정된** 일정의 알림 시점을 읽기 전용으로 적고, 아래 휠이
/// **미정**인 일정의 시각을 정한다.
struct ReminderTimeView: View {
    @Environment(\.appEnvironment) private var app
    @State private var model: ReminderTimeModel?

    var onBack: () -> Void = {}
    var onSaved: () -> Void = {}

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil { model = ReminderTimeModel(repository: app.settings) }
            await model?.load()
        }
    }

    private func content(_ model: ReminderTimeModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            MMNavBar(title: "알림 시간", leading: .back, onLeading: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: MMSpace.s14) {
                    MMSectionHeader(title: "진료 시간 확정")
                    card {
                        // 고를 수 없는 값이다. 시간이 정해진 일정의 알림 시점은 규칙이다.
                        MMSettingRow(title: "진료 전 알림", kind: .value("24시간 전"))
                        MMSettingRow(title: "진료 후 기록 알림", kind: .value("2시간 뒤"))
                    }

                    MMSectionHeader(title: "진료 시간 미정")
                    card {
                        MMTimeWheel(
                            isMorning: $model.isMorning,
                            hour: $model.hour,
                            minute: $model.minute
                        )
                    }

                    if let message = model.errorMessage {
                        Text(message)
                            .mmTextStyle(MMFont.bodyS)
                            .foregroundStyle(MMColor.fgDanger)
                    }
                }
                .padding(.horizontal, MMSize.gutter)
                .padding(.top, MMSpace.s8)
                .padding(.bottom, MMSpace.s16)
            }
            .scrollBounceBehavior(.basedOnSize)

            footer(model)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MMColor.bgSurface)
    }

    private func footer(_ model: ReminderTimeModel) -> some View {
        VStack(spacing: MMSpace.s10) {
            MMHintRow(
                text: ReminderTimeModel.hint(model.picked, day: ReminderTimeMetrics.sampleDay),
                icon: .bell
            )
            MMButton("확인", kind: .primary) {
                Task { if await model.save() { onSaved() } }
            }
            .disabled(model.isSaving)
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSpace.s24)
        .background(MMColor.bgSurface)
    }

    private func card(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.horizontal, ReminderTimeMetrics.cardPadding)
        .padding(.vertical, MMSpace.s6)
        .frame(maxWidth: .infinity)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .mmShadow(MMElevation.card)
    }
}

private enum ReminderTimeMetrics {
    static let cardPadding: CGFloat = 18
    /// 안내에 쓰는 날짜. 시안이 5일로 적었다.
    static let sampleDay = 5
}

#Preview {
    ReminderTimeView()
}
