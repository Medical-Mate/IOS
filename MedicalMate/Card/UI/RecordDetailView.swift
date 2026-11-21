import SwiftUI

/// `1j-3 · 기록 상세` (Figma `3663:15567` 외 두 상태).
///
/// 세 장이 한 화면이다 — 카드 접힘, 카드 펼침(`1j-3-X`), 재방문 누적(`1j-3-R`).
///
/// **한 증상의 일대기를 시간 순으로 편다.** 왼쪽 레일이 칸을 잇고, 칸마다 그날 무슨
/// 일이 있었는지가 선다.
struct RecordDetailView: View {
    @Environment(\.appEnvironment) private var app

    let visitId: Int64
    let onBack: () -> Void
    var onOpenCard: (Int64) -> Void = { _ in }

    @State private var model: RecordDetailModel?

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
            let created = RecordDetailModel(
                visitId: visitId,
                visits: app.visits,
                cards: app.cards,
                appointments: app.appointments
            )
            model = created
            await created.load()
        }
    }

    private func content(_ model: RecordDetailModel) -> some View {
        VStack(spacing: 0) {
            // **"기록 상세"다.** 탭의 1Depth인 기록 목록이 "기록"이라 같은 말을 쓰면
            // 어느 자리인지 알 수 없다. 시안(`3663:15567`)과 Android
            // (`record_detail_title`)가 같다.
            MMNavBar(title: "기록 상세", leading: .back, onLeading: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    head(model)
                    timeline(model)

                    if let message = model.errorMessage {
                        Text(message)
                            .mmTextStyle(MMFont.bodyS)
                            .foregroundStyle(MMColor.fgDanger)
                    }
                }
                .padding(.horizontal, MMSize.gutter)
                .padding(.top, MMSpace.s16)
                .padding(.bottom, MMSpace.s24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(MMColor.bgSurface)
    }

    private func head(_ model: RecordDetailModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s6) {
            HStack(spacing: MMSpace.s6) {
                Text(model.title)
                    .mmTextStyle(MMFont.headingL)
                    .foregroundStyle(MMColor.fgDefault)
                    .lineLimit(1)

                if let badge = model.badge {
                    // 이 자리의 배지는 Badge 마스터보다 크다(Label/M · py 3).
                    Text(badge.text)
                        .mmTextStyle(MMFont.labelM)
                        .foregroundStyle(MMColor.fgSuccess)
                        .padding(.horizontal, MMSpace.s8)
                        .padding(.vertical, TimelineMetrics.badgeV)
                        .background(MMColor.bgSuccess)
                        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xs))
                }

                Spacer(minLength: 0)
            }

            Text(model.meta)
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, TimelineMetrics.headBottom)
    }

    // MARK: - 타임라인

    /// 왼쪽 레일이 칸을 잇는다. 점 가운데(5)를 지나도록 2px 선을 깐다.
    private func timeline(_ model: RecordDetailModel) -> some View {
        VStack(alignment: .leading, spacing: TimelineMetrics.stepGap) {
            ForEach(model.steps) { step in
                stepView(step, model: model)
            }
        }
        .background(alignment: .topLeading) {
            Rectangle()
                .fill(MMColor.borderSubtle)
                .frame(width: TimelineMetrics.rail)
                .padding(.leading, TimelineMetrics.railLeading)
                .padding(.top, TimelineMetrics.dot / 2)
                .padding(.bottom, TimelineMetrics.railBottom)
        }
    }

    private func stepView(_ step: RecordDetailModel.Step, model: RecordDetailModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s6) {
            HStack(spacing: MMSpace.s10) {
                Circle()
                    .fill(MMColor.bgPrimary)
                    .frame(width: TimelineMetrics.dot, height: TimelineMetrics.dot)
                Text(step.when)
                    .mmTextStyle(MMFont.labelM)
                    .foregroundStyle(MMColor.fgSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Group {
                switch step.kind {
                case .card: cardBlock(step, model: model)
                case .visit: block(step)
                case .scheduled: scheduledBlock(step)
                }
            }
            .padding(.leading, TimelineMetrics.indent)
        }
    }

    /// 기록 칸. 흰 면 · 반경 16 · 패딩 16 · `Elevation/Card`.
    private func block(_ step: RecordDetailModel.Step) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s8) {
            Text(step.title)
                .mmTextStyle(MMFont.headingS)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(step.items) { item in
                kvRow(item)
            }
        }
        .padding(MMSpace.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
        .mmShadow(MMElevation.card)
    }

    /// 카드 칸. 접으면 **부위 · 기간 · 양상 셋만** 남고 아래에 펼치는 줄이 선다.
    private func cardBlock(_ step: RecordDetailModel.Step, model: RecordDetailModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s8) {
            Text(step.title)
                .mmTextStyle(MMFont.headingS)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(model.cardItems) { item in
                kvRow(item)
            }

            if model.isCardExpanded, let card = model.card {
                if let severity = card.severity {
                    MMSeverityReadout(level: severity)
                }
                if !card.allergies.isEmpty {
                    MMNotice(
                        title: "알러지 · \(card.allergies.joined(separator: " · "))",
                        message: "처방 전에 꼭 확인해 주세요",
                        tone: .warning
                    )
                }
                if !card.questions.isEmpty {
                    MMCallout(title: "환자가 묻고 싶어 하는 것", questions: card.questions)
                }
            }

            Rectangle()
                .fill(MMColor.borderSubtle)
                .frame(height: 1)
                .padding(.trailing, MMSpace.s16)

            Button { model.toggleCard() } label: {
                HStack(spacing: MMSpace.s8) {
                    Text(model.disclosureTitle)
                        .mmTextStyle(MMFont.bodyMStrong)
                        .foregroundStyle(MMColor.fgPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    (model.isCardExpanded ? MMIcon.chevronUp : MMIcon.chevronDown).view(size: MMSize.iconMd)
                        .foregroundStyle(MMColor.fgPrimary)
                }
                .padding(.top, MMSpace.s12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(MMSpace.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
        .mmShadow(MMElevation.card)
    }

    /// 예정 칸. **`Notice`인데 면이 `bg/primary`이고 글자가 희다** — 마스터의 네 톤에
    /// 없는 인스턴스라 여기서 그린다.
    private func scheduledBlock(_ step: RecordDetailModel.Step) -> some View {
        HStack(alignment: .top, spacing: MMSpace.s12) {
            MMIcon.info.view(size: MMSize.iconMd)
                .foregroundStyle(MMColor.fgPrimary)
                .frame(width: TimelineMetrics.badge, height: TimelineMetrics.badge)
                .background(MMColor.bgSurface)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: MMSpace.s2) {
                Text(step.notice?.title ?? "")
                    .mmTextStyle(MMFont.bodyMStrong)
                    .foregroundStyle(MMColor.fgOnPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(step.notice?.message ?? "")
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgOnPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, MMSpace.s4)
        }
        .padding(.leading, MMSpace.s14)
        .padding(.trailing, MMSpace.s16)
        .padding(.vertical, MMSpace.s14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
    }

    /// 타임라인의 KV 줄. 카드 화면의 `KV Row`보다 작다 — 키 52 · 값 `Body/M`.
    private func kvRow(_ item: BriefCardItem) -> some View {
        HStack(alignment: .top, spacing: MMSpace.s14) {
            Text(item.key)
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(width: TimelineMetrics.key, alignment: .leading)
            Text(item.value)
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(item.isEmphasized ? MMColor.fgPrimary : MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, TimelineMetrics.kvV)
    }
}

private enum TimelineMetrics {
    static let dot: CGFloat = 10
    static let rail: CGFloat = 2
    /// 점 가운데를 지나도록.
    static let railLeading: CGFloat = 4
    /// 마지막 칸의 점까지만 잇는다.
    static let railBottom: CGFloat = 80
    static let indent: CGFloat = 20
    static let stepGap: CGFloat = 16
    static let key: CGFloat = 52
    static let kvV: CGFloat = 3
    static let badge: CGFloat = 32
    static let badgeV: CGFloat = 3
    static let headBottom: CGFloat = 18
}
