import SwiftUI

/// `1q-1 · 자동 분류 결과` (Figma `3663:14427` 외 네 상태).
///
/// 다섯 장이 한 화면이다 — 읽기, 툴팁, 편집, 변경 있음, 삭제 확인. 1e-1과 같은 골격이고
/// `Callout` 자리에 **원문 메모 인용**이 선다.
///
/// **원문을 함께 남기는 것이 이 화면의 요점이다.** AI가 나눈 결과가 틀릴 수 있고, 그때
/// 환자가 돌아갈 곳은 자기가 적은 말이다.
struct VisitRecordView: View {
    @Bindable var model: VisitFlowModel
    let onBack: () -> Void
    let onSaved: (Int64) -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MMNavBar(
                    title: "진료 후 기록",
                    leading: .back,
                    onLeading: { model.isEditing ? model.cancelEditing() : onBack() },
                    actionTitle: model.actionTitle,
                    actionTone: model.actionTone,
                    onAction: model.commitAction
                )

                ScrollView {
                    recordCard
                        .padding(.horizontal, MMSize.gutter)
                        .padding(.top, MMSpace.s12)
                        .padding(.bottom, MMSpace.s16)
                }
                .scrollBounceBehavior(.basedOnSize)

                footer
            }

            overlays
        }
        .background(MMColor.bgSurface)
    }

    // MARK: - 카드

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            head

            MMDivider()

            if let draft = model.draft {
                ForEach(draft) { item in
                    MMKVEditRow(
                        key: item.label,
                        value: model.value(for: item),
                        onDelete: { model.deleteItem(item) }
                    )
                }
            } else {
                ForEach(model.items) { item in
                    MMKVRow(key: item.label, value: item.value, kind: item.isEmphasized ? .emphasis : .default)
                }
            }

            MMDivider()

            quote

            // 편집 중에는 설명 줄을 숨긴다(마스터가 끈다).
            if !model.isEditing {
                aiCaption
            }
        }
        .padding(.horizontal, RecordMetrics.inset)
        .padding(.top, RecordMetrics.inset)
        .padding(.bottom, model.isEditing ? RecordMetrics.inset : RecordMetrics.readBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .mmShadow(MMElevation.card)
    }

    private var head: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("진료 후 기록")
                .mmTextStyle(MMFont.headingS)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(model.recordMeta)
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, MMSpace.s14)
    }

    /// 환자가 적은 원문. `bg/primary-subtle` — **환자의 것**이라는 표시다.
    private var quote: some View {
        VStack(alignment: .leading, spacing: MMSpace.s6) {
            Text("진료 메모")
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: MMSpace.s4) {
                Text("내가 적은 그대로")
                    .mmTextStyle(MMFont.labelS)
                    .foregroundStyle(MMColor.fgPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(model.memo)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(MMSpace.s12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MMColor.bgPrimarySubtle)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.sm))
        }
        .padding(.top, MMSpace.s14)
    }

    private var aiCaption: some View {
        HStack(spacing: MMSpace.s4) {
            Text("AI가 메모를 \(model.items.count)가지로 나눴어요")
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            MMTooltip(isPresented: $model.isTooltipOpen, label: "분류 기준 설명")
        }
        .overlay(alignment: .topTrailing) {
            if model.isTooltipOpen {
                MMTooltipBubble(text: "소견·검사·약·재방문으로 나눴어요.\n원문 메모도 함께 남아요")
                    .offset(y: RecordMetrics.tooltipOffset)
            }
        }
    }

    // MARK: - 아래 칸

    private var footer: some View {
        VStack(spacing: 0) {
            if model.isEditing {
                MMButton("진료 후 기록 삭제", kind: .danger) {
                    model.isDeleteRequested = true
                }
                .disabled(model.isBusy)
            } else {
                MMButton("저장하기") {
                    Task {
                        if let id = await model.save() { onSaved(id) }
                    }
                }
                .disabled(model.isBusy)
            }

            if let message = model.errorMessage {
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgDanger)
                    .padding(.top, MMSpace.s8)
            }
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .background(MMColor.bgSurface)
    }

    @ViewBuilder
    private var overlays: some View {
        if model.isDeleteRequested {
            MMOverlayScrim(onTap: { model.isDeleteRequested = false })
            MMDialog(
                title: "이 진료 후 기록을 삭제할까요?",
                message: "원문 메모까지 사라지고 되돌릴 수 없어요.",
                confirmTitle: "삭제",
                onCancel: { model.isDeleteRequested = false },
                onConfirm: { Task { _ = await model.delete() } }
            )
            .padding(.horizontal, MMSize.gutter)
        }
    }
}

private enum RecordMetrics {
    static let inset: CGFloat = 18
    static let readBottom: CGFloat = 6
    static let tooltipOffset: CGFloat = 44
}
