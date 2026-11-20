import SwiftUI

/// `1e-1` 브리핑 카드 (Figma `3663:7335` 외 11개 상태).
///
/// **와이어프레임의 열한 장이 한 화면이다.** 읽기 셋(일정 없음 · 일정 보기 · 진료 지남)은
/// 하단 버튼만 다르고, 편집 넷(편집 · 변경 있음 · 질문 추가 · 적는 중)은 같은 편집 모드의
/// 단계이며, 나머지는 그 위에 뜨는 것들(내보내기 시트 · 일정 시트 · 툴팁 · 삭제 확인)이다.
struct BriefCardView: View {
    @Environment(\.appEnvironment) private var app

    let cardId: Int64
    /// 방금 만든 카드인지. 그러면 일정 시트(1e-1-S)가 먼저 뜬다.
    var justCreated = false

    let onBack: () -> Void
    var onChangeHospital: () -> Void = {}
    var onSchedule: () -> Void = {}
    var onViewSchedule: (Int64) -> Void = { _ in }
    var onRecordVisit: () -> Void = {}
    var onDeleted: () -> Void = {}

    @State private var model: BriefCardModel?

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
            let created = BriefCardModel(cardId: cardId, repository: app.cards)
            model = created
            await created.load()
            if justCreated, created.card != nil {
                created.sheet = .schedule
            }
        }
    }

    @ViewBuilder
    private func content(_ model: BriefCardModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                MMNavBar(
                    title: "브리핑 카드",
                    leading: .back,
                    onLeading: { model.isEditing ? model.cancelEditing() : onBack() },
                    actionTitle: model.card == nil ? nil : model.actionTitle,
                    actionTone: model.actionTone,
                    onAction: { Task { await model.commitAction() } }
                )

                if let card = model.card {
                    body(card, model: model)
                } else {
                    placeholder(model)
                }
            }

            overlays(model)
        }
        .background(MMColor.bgSurface)
    }

    @ViewBuilder
    private func placeholder(_ model: BriefCardModel) -> some View {
        VStack(spacing: MMSpace.s12) {
            if let message = model.errorMessage {
                Text(message)
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, MMSize.gutter)
    }

    private func body(_ card: BriefCard, model: BriefCardModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: MMSpace.s14) {
                    briefCard(card, model: model)

                    // 알러지는 카드 밖 경고다. **처방을 바꾸는 값이라 다른 정보와 같은
                    // 무게로 두지 않는다.** 편집 중에는 숨는다(마스터가 끈다).
                    if !model.isEditing, !card.allergies.isEmpty {
                        MMNotice(
                            title: "알러지 · \(card.allergies.joined(separator: " · "))",
                            message: "처방 전에 꼭 확인해 주세요",
                            tone: .warning
                        )
                    }

                    callout(card, model: model)

                    MMSectionHeader(
                        title: "진료받을 병원",
                        actionTitle: "변경",
                        onAction: onChangeHospital
                    )

                    if let hospital = card.hospital {
                        hospitalCard(hospital)
                    }

                    if model.saveFailed {
                        Text("고친 내용을 저장하지 못했어요. 잠시 뒤 다시 해주세요.")
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
    }

    // MARK: - 카드

    private func briefCard(_ card: BriefCard, model: BriefCardModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            head(card, model: model)

            MMDivider()

            if let draft = model.draft {
                ForEach(draft.items) { item in
                    MMKVEditRow(
                        key: item.key,
                        value: model.value(for: item),
                        // 축에서 오지 않은 줄은 고쳐도 보낼 곳이 없다.
                        isEditable: item.axis != nil,
                        onDelete: { model.deleteItem(item) }
                    )
                }
            } else {
                ForEach(card.items) { item in
                    MMKVRow(key: item.key, value: item.value, kind: item.isEmphasized ? .emphasis : .default)
                }
            }

            if let severity = card.severity {
                MMSeverityReadout(level: severity)
            }

            // 편집 중에는 설명 줄을 숨긴다. 고치는 중에 "AI가 정리했다"는 말은 맞지 않는다.
            if !model.isEditing {
                aiCaption(model)
            }
        }
        .padding(.horizontal, CardMetrics.inset)
        .padding(.top, CardMetrics.inset)
        .padding(.bottom, model.isEditing ? CardMetrics.inset : CardMetrics.readBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .overlay {
            if model.isEditing {
                RoundedRectangle(cornerRadius: MMRadius.lg)
                    .strokeBorder(MMColor.borderFocus, lineWidth: CardMetrics.editBorder)
            }
        }
        .mmShadow(MMElevation.card)
    }

    private func head(_ card: BriefCard, model: BriefCardModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s4) {
            HStack(spacing: MMSpace.s8) {
                Text(card.title)
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)
                    .lineLimit(1)

                MMBadge(text: card.badge.text, tone: card.badge.tone)

                Spacer(minLength: 0)

                // 편집 중에는 내보내기를 숨긴다 — 아직 저장되지 않은 값을 내보낼 수 없다.
                if !model.isEditing {
                    MMIconButton(icon: .export, label: "이미지로 내보내기", style: .ghost, size: .s) {
                        model.sheet = .export
                    }
                }
            }

            Text(model.patientLine)
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, MMSpace.s14)
    }

    private func aiCaption(_ model: BriefCardModel) -> some View {
        @Bindable var model = model

        return HStack(spacing: MMSpace.s2) {
            Text("AI가 말씀하신 내용을 정리했어요")
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            MMTooltip(isPresented: $model.isTooltipOpen, label: "이 카드가 어떻게 만들어졌는지")
        }
        .overlay(alignment: .topTrailing) {
            if model.isTooltipOpen {
                MMTooltipBubble(text: "말씀하신 내용을 항목별로 정리했어요. 원문도 함께 남아요")
                    .offset(y: TooltipMetrics.offset)
            }
        }
    }

    // MARK: - 질문

    private func callout(_ card: BriefCard, model: BriefCardModel) -> some View {
        MMCallout(
            title: "환자가 묻고 싶어 하는 것",
            questions: model.draft?.questions ?? card.questions,
            isEditing: model.isEditing,
            onDelete: { model.deleteQuestion(at: $0) },
            onAdd: model.canAddQuestion ? { model.addQuestion() } : nil,
            editableFrom: card.questions.count,
            value: { model.question(at: $0) }
        )
    }

    // MARK: - 병원

    private func hospitalCard(_ hospital: BriefCardHospital) -> some View {
        HStack(alignment: .top, spacing: CardMetrics.hospitalGap) {
            MMIcon.hospital.view(size: CardMetrics.hospitalIcon)
                .foregroundStyle(MMColor.fgPrimary)
                .frame(width: CardMetrics.hospitalBox, height: CardMetrics.hospitalBox)
                .background(MMColor.bgPrimaryFaint)
                .clipShape(RoundedRectangle(cornerRadius: CardMetrics.hospitalBoxRadius))

            VStack(alignment: .leading, spacing: MMSpace.s2) {
                Text(hospital.name)
                    .mmTextStyle(MMFont.bodyLStrong)
                    .foregroundStyle(MMColor.fgDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let address = hospital.address {
                    Text(address)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(MMSpace.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .mmShadow(MMElevation.card)
    }

    // MARK: - 아래 칸

    @ViewBuilder
    private func footer(_ model: BriefCardModel) -> some View {
        VStack(spacing: 0) {
            if model.isEditing {
                MMButton("브리핑 카드 삭제", kind: .danger) {
                    model.isDeleteRequested = true
                }
                .disabled(model.isSaving)
            } else if let action = model.footerAction {
                MMButton(action.title, kind: .outline) {
                    switch action {
                    case .schedule: onSchedule()
                    case .viewSchedule: model.card?.appointment.map { onViewSchedule($0.id) }
                    case .recordVisit: onRecordVisit()
                    }
                }
            }
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .background(MMColor.bgSurface)
    }

    // MARK: - 위에 뜨는 것

    @ViewBuilder
    private func overlays(_ model: BriefCardModel) -> some View {
        if model.isDeleteRequested {
            MMOverlayScrim(onTap: { model.isDeleteRequested = false })
            MMDialog(
                title: "이 브리핑 카드를 삭제할까요?",
                message: "연결된 진료 기록은 남고 카드만 사라져요.",
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

        if let sheet = model.sheet {
            MMOverlayScrim(onTap: { model.sheet = nil })
            VStack {
                Spacer(minLength: 0)
                switch sheet {
                case .export:
                    exportSheet(model)
                case .schedule:
                    scheduleSheet(model)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    /// `1e-1-X` 이미지로 내보내기.
    private func exportSheet(_ model: BriefCardModel) -> some View {
        @Bindable var model = model

        return MMBottomSheet {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                Text("카드를 이미지로 내보내요")
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)

                Color.clear.frame(height: MMSpace.s4)

                Text("카드 전체가 긴 이미지 한 장으로 만들어져요.")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)

                Color.clear.frame(height: MMSpace.s16)

                MMExportPreview()

                Color.clear.frame(height: MMSpace.s8)

                HStack {
                    Text("이름·나이 가리기")
                        .mmTextStyle(MMFont.bodyM)
                        .foregroundStyle(MMColor.fgDefault)
                    Spacer(minLength: 0)
                    MMToggle(isOn: $model.masksPatient)
                }
                .padding(.vertical, MMSpace.s8)

                Color.clear.frame(height: MMSpace.s8)

                MMButton("이미지 저장") { model.sheet = nil }

                Color.clear.frame(height: MMSpace.s8)

                MMButton("공유하기", kind: .outline) { model.sheet = nil }
            }
        }
    }

    /// `1e-1-S` 저장 직후 일정.
    private func scheduleSheet(_ model: BriefCardModel) -> some View {
        MMBottomSheet {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                Text("진료 날짜가 정해졌나요?")
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)

                Color.clear.frame(height: MMSpace.s4)

                Text("일정에 넣어두면 진료 전과 진료 뒤에 알려드려요.")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
                    .fixedSize(horizontal: false, vertical: true)

                Color.clear.frame(height: MMSpace.s20)

                MMButton("진료 일정 잡기") {
                    model.sheet = nil
                    onSchedule()
                }

                Color.clear.frame(height: MMSpace.s8)

                MMButton("아직 안 정했어요", kind: .ghost) { model.sheet = nil }
            }
        }
    }
}

private enum CardMetrics {
    /// 카드 안쪽 여백.
    static let inset: CGFloat = 18
    /// 읽기 모드의 아래 여백. 설명 줄이 아래를 메워 18보다 좁다.
    static let readBottom: CGFloat = 6
    static let editBorder: CGFloat = 2
    static let hospitalGap: CGFloat = 13
    static let hospitalBox: CGFloat = 44
    static let hospitalBoxRadius: CGFloat = 13
    static let hospitalIcon: CGFloat = 22
}

private enum TooltipMetrics {
    /// 말풍선이 트리거 아래로 내려오는 거리.
    static let offset: CGFloat = 44
}
