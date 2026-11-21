import SwiftUI

/// `1r-2 · 캘린더 · 일자 상세` (Figma `3663:15396` 외 세 상태).
///
/// 네 장이 한 화면이다 — 읽기, 편집, 변경 있음, 일정 삭제 확인.
///
/// **할 일 체크는 읽기 모드에서도 된다.** 진료 전에 하나씩 지워 가는 목록이라 편집을
/// 거쳐야 체크할 수 있으면 쓸모가 없다. 편집은 줄을 지우는 자리다.
struct CalendarDayView: View {

    /// 할 일 줄의 지우기 단추가 읽히는 말.
    ///
    /// **그 줄의 글을 넣는다.** 같아 보이는 단추가 줄마다 있어서, 글이 없으면 화면
    /// 낭독기로는 어느 줄을 지우는지 알 수 없다. 아직 안 적은 줄은 그렇게 말한다.
    nonisolated static func todoDeleteLabel(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "빈 할 일 삭제" : "\(trimmed) 삭제"
    }
    @Environment(\.appEnvironment) private var app

    let date: Date
    let onBack: () -> Void
    var onOpenCard: (Int64) -> Void = { _ in }
    var onRecordVisit: (Int64) -> Void = { _ in }
    var onOpenRecord: (Int64) -> Void = { _ in }
    /// 뽑아 둔 재방문을 확정하러 간다. 날짜와 카드를 들고 간다.
    var onConfirmNextEvent: (Date, Int64?) -> Void = { _, _ in }
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
            let created = CalendarDayModel(
                date: date,
                repository: app.appointments,
                cards: app.cards,
                visits: app.visits
            )
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
                                MMSectionHeader(title: model.cardSectionTitle)
                                cardRows(model)
                            }

                            // 진료가 끝난 날에는 할 일을 보이지 않는다 — 지난 준비물이다.
                            if !model.isVisited, !model.todos.isEmpty || model.isEditing {
                                MMSectionHeader(title: "진료 전 할 일")
                                todoRows(model)
                            }

                            MMSectionHeader(title: "이 날 기록")
                            recordSection(model)

                            if model.nextEvent != nil {
                                MMSectionHeader(title: "다음 일정")
                                nextEventCard(model)
                            }
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
            // 진료를 마친 날은 머리 글자가 `fg/success`다(`3663:15486`).
            Text(model.dayLabel)
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(model.isVisited ? MMColor.fgSuccess : MMColor.fgSubtle)
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
                    meta: card.meta,
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
                        .accessibilityLabel(CalendarDayView.todoDeleteLabel(todo.text))
                    }
                }
            }
        }
    }

    // MARK: - 기록

    @ViewBuilder
    private func recordSection(_ model: CalendarDayModel) -> some View {
        if let record = model.record {
            MMListRow(
                title: "진료 후 기록",
                meta: model.recordMeta,
                action: { onOpenRecord(record.id) }
            )
        } else {
            emptyRecord(model)
        }
    }

    @ViewBuilder
    private func emptyRecord(_ model: CalendarDayModel) -> some View {
        // 진료 전에는 기록이 없다. **액션이 면 없는 링크다**(마스터의 Tonal을 인스턴스가
        // 바꿔 놓았다).
        // **앞날에는 기록하러 가는 단추를 두지 않는다**(`canRecord`). 빈 상태의
        // "진료가 끝나면 … 기록할 수 있어요"가 그 자리를 대신한다. Android도 같다.
        MMEmptyState(
            icon: .emptyBox,
            title: "아직 진료 전이에요",
            message: "진료가 끝나면 들은 내용을 여기에 기록할 수 있어요",
            actionTitle: model.canRecord ? "진료 후 기록하기" : nil,
            actionStyle: .link,
            onAction: model.canRecord ? { model.cards.first.map { onRecordVisit($0.id) } } : nil
        )
        .frame(maxWidth: .infinity)
    }

    /// `Next Event` — 재방문 일정(`1r-2-A` · `1r-2-A2`).
    ///
    /// **시각이 없으면 제안, 있으면 확정이다.** 기록에서 나온 날짜는 "2주 뒤"처럼
    /// 날짜까지라 시각이 비어 있고, 그때는 시간을 정하라고 청한다.
    private func nextEventCard(_ model: CalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s6) {
            Text(model.isNextEventConfirmed ? model.nextEventDayLabel : model.nextEventDateLabel)
                .mmTextStyle(MMFont.labelM)
                .foregroundStyle(MMColor.fgPrimary)
                .padding(.horizontal, NextEventMetrics.chipH)
                .padding(.vertical, NextEventMetrics.chipV)
                .background(MMColor.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: MMRadius.xs))

            Text(model.isNextEventConfirmed ? (model.nextEvent?.title ?? "") : "재방문 예정")
                .mmTextStyle(MMFont.headingS)
                .foregroundStyle(MMColor.fgOnPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(
                model.isNextEventConfirmed
                    ? model.nextEventMeta
                    : "진료 후 기록에서 자동으로 만들었어요\n시간을 정하면 하루 전에 알려드려요"
            )
            .mmTextStyle(MMFont.bodyS)
            .foregroundStyle(MMColor.fgOnPrimary.opacity(NextEventMetrics.bodyOpacity))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            if !model.isNextEventConfirmed {
                Color.clear.frame(height: MMSpace.s4)
                Button { model.nextEvent.map { onConfirmNextEvent($0.on, $0.cards.first?.id) } } label: {
                    HStack(spacing: MMSpace.s6) {
                        MMIcon.clock.view(size: MMSize.iconSm)
                        Text("시간 정하고 확정하기").mmTextStyle(MMFont.bodyMStrong)
                    }
                    .foregroundStyle(MMColor.fgOnPrimary)
                    .padding(.vertical, NextEventMetrics.actionV)
                    .frame(maxWidth: .infinity)
                    .background(MMColor.bgOnDark)
                    .clipShape(RoundedRectangle(cornerRadius: MMRadius.sm))
                    .overlay {
                        RoundedRectangle(cornerRadius: MMRadius.sm)
                            .strokeBorder(MMColor.borderOnDark, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(NextEventMetrics.inset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
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
                        if await model.delete() {
                            // 일정이 사라졌으니 걸린 알림도 다시 맞춘다.
                            await app.reminders.refresh()
                            onDeleted()
                        }
                    }
                }
            )
            .padding(.horizontal, MMSize.gutter)
        }
    }
}

private enum NextEventMetrics {
    static let inset: CGFloat = 18
    static let chipH: CGFloat = 9
    static let chipV: CGFloat = 3
    static let actionV: CGFloat = 11
    /// 본문의 흰 글자 투명도. 마스터가 82%다.
    static let bodyOpacity: Double = 0.82
}

private enum CalendarDayMetrics {
    /// 첫 구간 머리는 위 여백이 24가 아니라 8이다(`3663:15399`).
    static let firstHeaderTop: CGFloat = -16
}
