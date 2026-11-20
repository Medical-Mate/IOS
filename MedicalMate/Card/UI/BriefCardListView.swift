import SwiftUI

/// `1j-4 · 브리핑 카드 전체` (Figma `3663:7125`),
/// 편집 `1j-4-D`(`3663:7134`) · `1j-4-D2`(`3663:7145`) · 삭제 확인 `1j-4-DC`(`3663:7156`).
///
/// 달로 묶은 목록이다. 구간 머리의 오른쪽은 **누르는 링크가 아니라 장 수**이고,
/// 편집 중에는 "n장 선택됨"으로 바뀐다.
///
/// 편집을 켜면 줄마다 고르는 상자가 서고 셋째 줄(요약)이 빠지며 아래에 Danger 버튼이
/// 선다. **지우기는 되돌릴 수 없어서 Dialog가 먼저 묻는다.**
struct BriefCardListView: View {
    @Environment(\.appEnvironment) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var model: BriefCardListModel?
    @State private var askingDelete = false

    var onOpenCard: (Int64) -> Void = { _ in }
    var onResumeIntake: (Int64) -> Void = { _ in }

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil {
                model = BriefCardListModel(repository: app.cards, home: app.home)
            }
            await model?.load()
        }
    }

    private func content(_ model: BriefCardListModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                navBar(model)
                list(model)
                if model.isEditing {
                    footer(model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(MMColor.bgSurface)

            if askingDelete {
                MMOverlayScrim { askingDelete = false }
                MMDialog(
                    title: "\(model.pickedCount)장을 삭제할까요?",
                    message: "삭제하면 되돌릴 수 없어요.",
                    confirmTitle: "삭제",
                    onCancel: { askingDelete = false },
                    onConfirm: {
                        askingDelete = false
                        Task { await model.deletePicked() }
                    }
                )
            }
        }
    }

    private func navBar(_ model: BriefCardListModel) -> some View {
        MMNavBar(
            title: "브리핑 카드",
            // 편집 중에도 뒤로가기는 그대로 있다(1j-4-D2).
            leading: .back,
            onLeading: { dismiss() },
            actionTitle: model.isEditing ? "취소" : "편집",
            onAction: {
                model.isEditing ? model.cancelEditing() : model.startEditing()
            }
        )
    }

    private func list(_ model: BriefCardListModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: MMSpace.s12) {
                ForEach(model.sections) { section in
                    MMSectionHeader(
                        title: section.month,
                        trailing: model.isEditing
                            ? .selected(CardRepository.countLabel(model.pickedCount(in: section), selected: true))
                            : .count(CardRepository.countLabel(section.items.count, selected: false))
                    )

                    ForEach(section.items) { item in
                        row(item, model: model)
                    }
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
    }

    private func row(_ item: CardListItem, model: BriefCardListModel) -> some View {
        MMListRow(
            title: item.title,
            meta: item.meta,
            badge: item.badge,
            // 편집 중에는 셋째 줄을 빼고 고르는 상자를 세운다(1j-4-D2).
            summary: model.isEditing ? nil : item.summary,
            summaryTone: item.summaryTone,
            selection: model.isEditing
                ? Binding(get: { model.isPicked(item) }, set: { _ in model.toggle(item) })
                : nil,
            // 편집 중에는 들어갈 곳이 없어 chevron도 빠진다(1j-4-D2).
            action: model.isEditing ? nil : { open(item) },
            onTap: model.isEditing ? { model.toggle(item) } : nil
        )
    }

    private func footer(_ model: BriefCardListModel) -> some View {
        MMButton("\(model.pickedCount)장 삭제", kind: .danger) {
            askingDelete = true
        }
        .disabled(model.pickedCount == 0)
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSpace.s24)
        .background(MMColor.bgSurface)
    }

    private func open(_ item: CardListItem) {
        switch item.kind {
        case .card(let id, _): onOpenCard(id)
        case .openIntake(let sessionId, _, _, _): onResumeIntake(sessionId)
        }
    }
}

#Preview {
    BriefCardListView()
}
