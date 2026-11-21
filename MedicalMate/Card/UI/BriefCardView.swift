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
                column(card, model: model)
            }
            .scrollBounceBehavior(.basedOnSize)

            footer(model)
        }
    }

    /// 화면에 흐르는 본문. **이미지로 내보내는 것도 이것이다** — 시트가
    /// "카드 전체가 긴 이미지 한 장"이라고 적어 두었고, 카드만 찍으면 알러지 경고와
    /// 묻고 싶은 것이 빠진다. Android도 스크롤 안쪽을 통째로 찍는다.
    private func column(_ card: BriefCard, model: BriefCardModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
                briefCard(card, model: model)
                    // 툴팁 말풍선은 카드 밖으로 흘러나온다(`1e-1-T` `3663:7496`).
                    // **뒤에 오는 알러지 경고가 그 위에 그려지면 글이 가려진다** —
                    // 열려 있는 동안만 카드를 위로 올린다.
                    .zIndex(model.isTooltipOpen ? 1 : 0)

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
                    Text("저장하지 못했어요. 다시 눌러주세요.")
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgDanger)
                }
                }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSpace.s16)
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
        // **면만 둥글게 깎는다.** `clipShape`을 카드 전체에 걸면 툴팁 말풍선
        // (`1e-1-T` `3663:7496`)이 카드 밖으로 못 나가 잘린다 — 시안은 카드 아래로
        // 흘러나온다. 1q-1도 같은 자리다.
        .background(RoundedRectangle(cornerRadius: MMRadius.lg).fill(MMColor.bgSurface))
        .overlay {
            if model.isEditing {
                RoundedRectangle(cornerRadius: MMRadius.lg)
                    .strokeBorder(MMColor.borderFocus, lineWidth: CardMetrics.editBorder)
            }
        }
        .mmShadow(MMElevation.card)
    }

    /// 카드를 이미지로 찍는다.
    ///
    /// **찍는 동안만 내보내기 단추를 감춘다**(`isCapturing`). 시안 폭(`320`) 그대로
    /// 그리고 화면 배율로 키운다 — 진료실에서 확대해 보여 줄 수 있어야 한다.
    /// "이름·나이 가리기"는 `model.patientLine`이 이미 보고 있어 따로 손대지 않는다.
    func captureImage(_ card: BriefCard, model: BriefCardModel) -> UIImage? {
        model.isCapturing = true
        defer { model.isCapturing = false }
        return BriefCardExport.render(
            column(card, model: model),
            width: MMSize.contentWidth + MMSize.gutter * 2,
            scale: UITraitCollection.current.displayScale
        )
    }

    private func head(_ card: BriefCard, model: BriefCardModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s4) {
            HStack(alignment: .firstTextBaseline, spacing: MMSpace.s8) {
                // **잘라내지 않는다.** 글자를 키워 쓰는 분에게 "복부 통…"으로 끊기면
                // 진료실에서 보여 줄 카드의 제목이 사라진다. 기본 크기에서는 한 줄에
                // 들어가 시안과 같고, 길어지면 줄이 는다. Android도 줄 수를 묶지 않는다.
                Text(card.title)
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)
                    .fixedSize(horizontal: false, vertical: true)

                MMBadge(text: card.badge.text, tone: card.badge.tone)

                Spacer(minLength: 0)

                // 편집 중에는 내보내기를 숨긴다 — 아직 저장되지 않은 값을 내보낼 수
                // 없다. **찍는 동안에도 감춘다** — 그림에 단추가 같이 찍힌다.
                if !model.isEditing, !model.isCapturing {
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

    /// 툴팁 말풍선의 글(`1e-1-T` `3663:7496`).
    nonisolated static let tooltipText = "말씀하신 내용을 항목별로 정리했어요. 원문도 함께 남아요"

    private func aiCaption(_ model: BriefCardModel) -> some View {
        @Bindable var model = model

        return HStack(spacing: MMSpace.s2) {
            Text("AI가 말씀하신 내용을 정리했어요")
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            MMTooltip(isPresented: $model.isTooltipOpen, label: "AI가 어떻게 정리했는지 보기")
        }
        .overlay(alignment: .topTrailing) {
            if model.isTooltipOpen {
                MMTooltipBubble(text: BriefCardView.tooltipText)
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
                MMButton(action.title, kind: action.kind) {
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
