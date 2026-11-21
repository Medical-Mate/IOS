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
    /// 같은 목록이 하는 두 가지 일.
    ///
    /// **`1j-4`는 브리핑 카드만, `1j-1`은 진료를 마친 기록까지** 세운다. 내비와 빈
    /// 자리도 갈린다 — `1j-1`은 탭의 1Depth라 뒤로가기가 없다.
    enum Kind: Sendable {
        /// `1j-4` 브리핑 카드 전체.
        case briefCards
        /// `1j-1` 기록.
        case records

        var title: String {
            switch self {
            case .briefCards: "브리핑 카드"
            case .records: "기록"
            }
        }

        var leading: MMNavBar.Leading {
            switch self {
            case .briefCards: .back
            case .records: .none
            }
        }

        /// 세는 말. **기록은 "건", 카드는 "장"이다**(Android `record_count` ·
        /// `brief_card_list_count`).
        var unit: String {
            switch self {
            case .briefCards: "장"
            case .records: "건"
            }
        }

        /// 삭제 확인(`1j-4-DC`)의 제목. 무엇이 몇 개 사라지는지를 적는다.
        func deleteTitle(_ count: Int) -> String {
            switch self {
            case .briefCards: "브리핑 카드 \(count)장을 삭제할까요?"
            case .records: "기록 \(count)건을 삭제할까요?"
            }
        }

        /// 삭제 확인의 본문. **카드를 지워도 진료 기록은 남는다**는 것이 1j-4의 핵심이라
        /// 두 화면이 다른 말을 한다.
        var deleteBody: String {
            switch self {
            case .briefCards: "연결된 진료 기록은 남고 선택한 카드는 사라져요."
            case .records: "선택한 기록이 사라지고 되돌릴 수 없어요."
            }
        }

        /// 비었을 때의 제목. `1j-2`는 기록, `1j-4`는 카드를 가리킨다.
        var emptyTitle: String {
            switch self {
            case .briefCards: "아직 브리핑 카드가 없어요"
            case .records: "아직 진료 기록이 없어요"
            }
        }
    }

    var kind: Kind = .briefCards

    @Environment(\.appEnvironment) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var model: BriefCardListModel?
    @State private var askingDelete = false

    var onOpenCard: (Int64) -> Void = { _ in }
    var onResumeIntake: (Int64) -> Void = { _ in }
    /// 기록 줄. 1j-1에서만 쓴다.
    var onOpenRecord: (Int64) -> Void = { _ in }
    /// 기록이 하나도 없을 때의 길(1j-2).
    var onStartIntake: () -> Void = {}

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
                model = BriefCardListModel(
                    repository: app.cards,
                    home: app.home,
                    visits: kind == .records ? app.visits : nil
                )
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
                    title: kind.deleteTitle(model.pickedCount),
                    message: kind.deleteBody,
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
            title: kind.title,
            // 편집 중에도 뒤로가기는 그대로 있다(1j-4-D2). 기록 탭은 1Depth라 없다.
            leading: kind.leading,
            onLeading: { dismiss() },
            actionTitle: model.isEditing ? "취소" : "편집",
            onAction: {
                model.isEditing ? model.cancelEditing() : model.startEditing()
            }
        )
    }

    /// `1j-2` 기록이 하나도 없을 때. **액션이 면 없는 링크다**(마스터의 Tonal을
    /// 인스턴스가 바꿔 놓았다 — 1m-B · 1r-2와 같은 자리).
    @ViewBuilder
    private var emptyState: some View {
        MMEmptyState(
            icon: .emptyBox,
            title: kind.emptyTitle,
            message: "증상을 정리해두면 진료실에서 바로 보여줄 수 있어요",
            actionTitle: "증상 정리하기",
            actionStyle: .link,
            onAction: onStartIntake
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func list(_ model: BriefCardListModel) -> some View {
        if !model.isLoading, model.sections.isEmpty, model.errorMessage == nil {
            emptyState
        } else {
            rows(model)
        }
    }

    private func rows(_ model: BriefCardListModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: MMSpace.s12) {
                ForEach(model.sections) { section in
                    MMSectionHeader(
                        title: section.month,
                        trailing: model.isEditing
                            ? .selected(CardRepository.countLabel(
                                model.pickedCount(in: section), unit: kind.unit, selected: true
                            ))
                            : .count(CardRepository.countLabel(
                                section.items.count, unit: kind.unit, selected: false
                            ))
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
            .padding(.bottom, kind == .records ? CardListMetrics.tabBottom : MMSpace.s16)
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
        // 고른 것이 없으면 "삭제"만 적는다. "0장 삭제"는 세는 말이 되지 않는다.
        MMButton(Self.deleteTitle(model.pickedCount, unit: kind.unit), kind: .danger) {
            askingDelete = true
        }
        .disabled(model.pickedCount == 0)
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSpace.s24)
        .background(MMColor.bgSurface)
    }

    /// "삭제" · "2장 삭제" · "2건 삭제".
    nonisolated static func deleteTitle(_ count: Int, unit: String) -> String {
        count == 0 ? "삭제" : "\(count)\(unit) 삭제"
    }

    private func open(_ item: CardListItem) {
        switch item.kind {
        case .card(let id, _): onOpenCard(id)
        case .openIntake(let sessionId, _, _, _): onResumeIntake(sessionId)
        case .visit(let id, _): onOpenRecord(id)
        }
    }
}

private enum CardListMetrics {
    /// 기록 탭은 탭바가 아래를 가린다.
    static let tabBottom: CGFloat = MMSize.tabBarHeight + MMSpace.s16
}

#Preview {
    BriefCardListView()
}
