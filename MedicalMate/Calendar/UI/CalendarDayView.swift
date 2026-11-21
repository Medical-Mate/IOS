import SwiftUI

/// `1r-2 · 캘린더 · 일자 상세` (Figma `3663:15396` 외 세 상태).
///
/// 네 장이 한 화면이다 — 읽기, 편집, 변경 있음, 일정 삭제 확인.
///
/// **할 일 체크는 읽기 모드에서도 된다.** 진료 전에 하나씩 지워 가는 목록이라 편집을
/// 거쳐야 체크할 수 있으면 쓸모가 없다. 편집은 줄을 지우는 자리다.
struct CalendarDayView: View {
    @Environment(\.appEnvironment) private var app

    let date: Date
    let onBack: () -> Void
    var onOpenCard: (Int64) -> Void = { _ in }
    var onRecordVisit: (Int64) -> Void = { _ in }
    var onDeleted: () -> Void = {}

    @State private var model: CalendarDayModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            guard model == nil else { return }
            let created = CalendarDayModel(date: date, repository: app.appointments)
            model = created
            await created.load()
        }
    }

    private func content(_ model: CalendarDayModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                MMNavBar(
                    title: model.title,
                    leading: .back,
                    onLeading: { model.isEditing ? model.cancelEditing() : onBack() },
                    actionTitle: model.appointment == nil ? nil : model.actionTitle,
                    actionTone: model.actionTone,
                    onAction: { Task { await model.commitAction() } }
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: MMSpace.s14) {
                        if model.appointment != nil {
                            MMSectionHeader(title: "이 날 일정")
                                .padding(.top, CalendarDayMetrics.firstHeaderTop)
                            scheduleCard(model)

                            if !model.cards.isEmpty {
                                MMSectionHeader(title: "가져갈 브리핑 카드")
                                cardRows(model)
                            }

                            MMSectionHeader(title: "진료 전 할 일")
                            todoRows(model)

                            MMSectionHeader(title: "이 날 기록")
                            recordSection(model)
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

                if model.isEditing {
                    footer(model)
                }
            }

            overlays(model)
        }
        .background(MMColor.bgSurface)
    }

    // MARK: - 일정

    /// `Card / Brand` — `bg/primary-faint` 면에 D-day · 제목 · 시각.
    private func scheduleCard(_ model: CalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s6) {
            Text(model.dayLabel)
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(model.appointment?.title ?? "")
                .mmTextStyle(MMFont.headingS)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(model.scheduleDetail)
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgSubtle)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MMSize.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgPrimaryFaint)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
    }

    private func cardRows(_ model: CalendarDayModel) -> some View {
        VStack(spacing: MMSpace.s10) {
            ForEach(model.cards) { card in
                MMListRow(
                    title: card.title,
                    meta: "",
                    action: { onOpenCard(card.id) }
                )
            }
        }
    }

    // MARK: - 할 일

    private func todoRows(_ model: CalendarDayModel) -> some View {
        VStack(spacing: 0) {
            ForEach(model.todos) { todo in
                HStack(spacing: MMSpace.s8) {
                    HStack(spacing: MMSpace.s12) {
                        MMSelectBox(isOn: .constant(todo.isDone))
                            .allowsHitTesting(false)
                        Text(todo.text)
                            .mmTextStyle(MMFont.bodyL)
                            .foregroundStyle(MMColor.fgDefault)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, MMSpace.s14)
                    .contentShape(Rectangle())
                    .onTapGesture { Task { await model.toggle(todo) } }

                    if model.isEditing {
                        Button { model.deleteTodo(todo) } label: {
                            MMIcon.close.view(size: MMSize.iconMd)
                                .foregroundStyle(MMColor.fgSubtle)
                                .frame(width: MMSize.touchMin, height: MMSize.touchMin)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("할 일 지우기")
                    }
                }
            }
        }
    }

    // MARK: - 기록

    @ViewBuilder
    private func recordSection(_ model: CalendarDayModel) -> some View {
        // 진료 전에는 기록이 없다. **액션이 면 없는 링크다**(마스터의 Tonal을 인스턴스가
        // 바꿔 놓았다).
        MMEmptyState(
            icon: .emptyBox,
            title: "아직 진료 전이에요",
            message: "진료가 끝나면 들은 내용을 여기에 기록할 수 있어요",
            actionTitle: "진료 후 기록하기",
            actionStyle: .link,
            onAction: { model.cards.first.map { onRecordVisit($0.id) } }
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - 아래 칸

    private func footer(_ model: CalendarDayModel) -> some View {
        VStack(spacing: 0) {
            MMButton("일정 삭제", kind: .danger) {
                model.isDeleteRequested = true
            }
            .disabled(model.isSaving)
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .background(MMColor.bgSurface)
    }

    @ViewBuilder
    private func overlays(_ model: CalendarDayModel) -> some View {
        if model.isDeleteRequested {
            MMOverlayScrim(onTap: { model.isDeleteRequested = false })
            MMDialog(
                title: "이 일정을 삭제할까요?",
                message: "캘린더와 하루 전 알림이 함께 사라져요.",
                confirmTitle: "삭제",
                onCancel: { model.isDeleteRequested = false },
                onConfirm: {
                    Task {
                        if await model.delete() { onDeleted() }
                    }
                }
            )
            .padding(.horizontal, MMSize.gutter)
        }
    }
}

private enum CalendarDayMetrics {
    /// 첫 구간 머리는 위 여백이 24가 아니라 8이다(`3663:15399`).
    static let firstHeaderTop: CGFloat = -16
}
