import SwiftUI

/// `1r-4 · 일정 추가` (Figma `3663:14772` 외 다섯 상태).
///
/// 여섯 장이 한 화면이다 — 병원 미등록, 병원 자동, 날짜 시트, 시간 시트, 할 일 목록,
/// 예약 문자 안내 시트.
///
/// **날짜만 있으면 저장된다.** 시각과 카드와 할 일은 선택이다 — 카드 없이
/// "다음 주 치과"만 적을 수 있어야 한다.
struct ScheduleAddView: View {
    @Environment(\.appEnvironment) private var app

    var initialDate: Date?
    let onBack: () -> Void
    let onSaved: (Int64) -> Void
    var onNewCard: () -> Void = {}

    @State private var model: ScheduleAddModel?
    /// 병원 찾기를 이 화면 안에서 연다. 고른 결과를 되돌려 받아야 해서 라우트로
    /// 내보내지 않는다.
    @State private var isPickingClinic = false

    var body: some View {
        Group {
            if let model {
                if isPickingClinic {
                    HospitalPickView(
                        purpose: .beforeVisit,
                        onBack: { isPickingClinic = false },
                        onSubmit: { hospital in
                            model.pick(clinic: hospital)
                            isPickingClinic = false
                        }
                    )
                } else {
                    content(model)
                }
            } else {
                Color.clear
            }
        }
        .task {
            guard model == nil else { return }
            let created = ScheduleAddModel(
                initialDate: initialDate,
                repository: app.appointments,
                cards: app.cards
            )
            model = created
            await created.load()
        }
    }

    private func content(_ model: ScheduleAddModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                MMNavBar(title: "일정 추가", leading: .back, onLeading: onBack)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        field(label: "병원") {
                            picker(model.clinicLabel, icon: .chevronRight, isFilled: model.hasClinic) {
                                isPickingClinic = true
                            }
                        }

                        Color.clear.frame(height: MMSpace.s16)

                        field(label: "날짜 · 시간") {
                            HStack(spacing: MMSpace.s10) {
                                picker(model.dateLabel, icon: .calendar, isFilled: model.on != nil) {
                                    model.openDateSheet()
                                }
                                picker(model.timeLabel, icon: .clock, isFilled: model.time != nil) {
                                    model.openTimeSheet()
                                }
                            }
                        }

                        MMSectionHeader(title: "가져갈 브리핑 카드", trailing: .count(model.pickedLabel))

                        cardList(model)

                        addRow(title: "새 카드 만들기", action: onNewCard)

                        MMSectionHeader(title: "진료 전 할 일")

                        todoList(model)

                        addRow(title: "할 일 추가") { model.addTodo() }

                        if let message = model.errorMessage {
                            Text(message)
                                .mmTextStyle(MMFont.bodyS)
                                .foregroundStyle(MMColor.fgDanger)
                                .padding(.top, MMSpace.s8)
                        }
                    }
                    .padding(.horizontal, MMSize.gutter)
                    .padding(.top, MMSpace.s8)
                    .padding(.bottom, MMSize.safeBottom)
                }
                .scrollBounceBehavior(.basedOnSize)

                footer(model)
            }

            overlays(model)
        }
        .background(MMColor.bgSurface)
    }

    // MARK: - 입력 칸

    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ScheduleMetrics.labelGap) {
            Text(label)
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }

    /// 눌러서 고르는 칸.
    ///
    /// **값이 차면 테두리가 `fg/default`로 올라간다**(`3663:14874`) — 비어 있을 때는
    /// `border/strong`이다. 값이 없으면 글자도 `fg/muted`로 가라앉는다.
    private func picker(_ title: String, icon: MMIcon, isFilled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MMSpace.s6) {
                Text(title)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(isFilled ? MMColor.fgDefault : MMColor.fgMuted)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                icon.view(size: MMSize.iconMd)
                    .foregroundStyle(MMColor.fgDefault)
            }
            .padding(.leading, MMSpace.s16)
            .padding(.trailing, MMSpace.s12)
            .frame(height: MMSize.controlLg)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .strokeBorder(isFilled ? MMColor.fgDefault : MMColor.borderStrong, lineWidth: 1)
            }
            // 면이 없는 칸이라 글자만 눌리는 것을 막는다.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 카드

    @ViewBuilder
    private func cardList(_ model: ScheduleAddModel) -> some View {
        VStack(spacing: MMSpace.s10) {
            ForEach(model.cards) { item in
                cardRow(item, model: model)
            }
        }
    }

    private func cardRow(_ item: CardListItem, model: ScheduleAddModel) -> some View {
        let isPicked: Bool = {
            guard case .card(let id, _) = item.kind else { return false }
            return model.isPicked(id)
        }()

        return Button { model.toggleCard(item) } label: {
            HStack(spacing: MMSpace.s10) {
                MMSelectBox(isOn: .constant(isPicked))
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: MMSpace.s2) {
                    Text(item.title)
                        .mmTextStyle(MMFont.bodyLStrong)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.meta)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, ScheduleMetrics.cardInset)
            .padding(.vertical, MMSpace.s16)
            .frame(maxWidth: .infinity)
            .background(MMColor.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
            .overlay {
                // 고른 카드만 1.5px 브랜드 테두리를 두른다.
                if isPicked {
                    RoundedRectangle(cornerRadius: MMRadius.lg)
                        .strokeBorder(MMColor.bgPrimary, lineWidth: ScheduleMetrics.pickedBorder)
                }
            }
            .mmShadow(MMElevation.card)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isPicked ? [.isSelected] : [])
    }

    // MARK: - 할 일

    private func todoList(_ model: ScheduleAddModel) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(model.todos.enumerated()), id: \.element.id) { index, todo in
                HStack(spacing: MMSpace.s10) {
                    MMSelectBox(isOn: .constant(todo.isDone))
                        .allowsHitTesting(false)
                        .onTapGesture { model.toggleTodo(todo) }

                    // **빈 칸에는 안내 글을 넣지 않는다.** 시안(`3663:15151`)이 밑줄 친
                    // 빈 자리를 그려 두었고, 적기 시작하면 밑줄이 사라진다
                    // (`3663:15250`). 질문 빈 칸(`MMCallout`)과 같은 모양이다.
                    VStack(spacing: ScheduleMetrics.todoFieldGap) {
                        TextField("", text: model.todo(at: index))
                            .mmTextStyle(MMFont.bodyM)
                            .foregroundStyle(MMColor.fgDefault)
                            .textFieldStyle(.plain)
                        if todo.text.isEmpty {
                            Rectangle()
                                .fill(MMColor.borderSubtle)
                                .frame(height: 1)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Button { model.deleteTodo(todo) } label: {
                        MMIcon.close.view(size: MMSize.iconMd)
                            .foregroundStyle(MMColor.fgSubtle)
                            .frame(width: MMSize.touchMin, height: MMSize.touchMin)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("할 일 지우기")
                }
                .frame(height: ScheduleMetrics.rowHeight)
            }
        }
    }

    /// "새 카드 만들기" · "할 일 추가". 플러스 18 + `fg/primary` 글자.
    private func addRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MMSpace.s8) {
                MMIcon.plus.view(size: MMSize.iconSm)
                Text(title).mmTextStyle(MMFont.bodyLStrong)
            }
            .foregroundStyle(MMColor.fgPrimary)
            .frame(height: ScheduleMetrics.rowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 아래 칸

    private func footer(_ model: ScheduleAddModel) -> some View {
        VStack(spacing: MMSpace.s12) {
            // 병원을 아직 안 골랐을 때만 예약 문자 길을 알린다.
            if !model.hasClinic {
                Button { model.sheet = .shareGuide } label: {
                    MMHintRow(text: "예약 문자를 공유하면 바로 채워져요", icon: .export)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }

            MMButton("저장하기") {
                Task {
                    if let id = await model.save() { onSaved(id) }
                }
            }
            .disabled(!model.canSave)
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .background(MMColor.bgSurface)
    }

    // MARK: - 시트

    @ViewBuilder
    private func overlays(_ model: ScheduleAddModel) -> some View {
        if let sheet = model.sheet {
            MMOverlayScrim(onTap: { model.sheet = nil })
            VStack {
                Spacer(minLength: 0)
                switch sheet {
                case .date: dateSheet(model)
                case .time: timeSheet(model)
                case .shareGuide: shareGuideSheet(model)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func dateSheet(_ model: ScheduleAddModel) -> some View {
        MMBottomSheet {
            VStack(spacing: MMSpace.s16) {
                Text("날짜 선택")
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)
                    .padding(.top, MMSpace.s14)

                HStack(spacing: MMSpace.s8) {
                    MMIconButton(icon: .chevronLeft, label: "이전 달") { model.sheetGoToPreviousMonth() }
                    Text(model.sheetMonth.title)
                        .mmTextStyle(MMFont.headingM)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity)
                    MMIconButton(icon: .chevronRight, label: "다음 달") { model.sheetGoToNextMonth() }
                }

                // 시트의 그리드는 범례를 끈다. 고르는 자리라 보여 줄 상태가 없다.
                MMCalendarGrid(days: model.sheetDays, showsLegend: false) { model.sheetSelect(day: $0) }

                MMButton("확인") { model.confirmDate() }
            }
        }
    }

    private func timeSheet(_ model: ScheduleAddModel) -> some View {
        @Bindable var model = model

        return MMBottomSheet {
            VStack(spacing: MMSpace.s16) {
                Text("시간 선택")
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)
                    .padding(.top, MMSpace.s14)

                MMTimeWheel(
                    isMorning: $model.sheetIsMorning,
                    hour: $model.sheetHour,
                    minute: $model.sheetMinute
                )

                MMButton("확인") { model.confirmTime() }
            }
        }
    }

    /// `1r-4-S` 예약 문자 방법 안내 (Figma `3663:14855`).
    ///
    /// **가져오기 자체는 Share Extension이 필요해 M4다.** 지금은 방법만 알린다.
    private func shareGuideSheet(_ model: ScheduleAddModel) -> some View {
        MMBottomSheet {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                VStack(alignment: .leading, spacing: MMSpace.s4) {
                    Text("예약 문자로 일정 채우기")
                        .mmTextStyle(MMFont.headingM)
                        .foregroundStyle(MMColor.fgDefault)
                    Text("병원에서 받은 문자를 공유하면 돼요.")
                        .mmTextStyle(MMFont.bodyM)
                        .foregroundStyle(MMColor.fgSubtle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Color.clear.frame(height: MMSpace.s16)

                MMIllustration.shareSheet.view()
                    .frame(maxWidth: .infinity)

                Color.clear.frame(height: MMSpace.s16)

                VStack(alignment: .leading, spacing: MMSpace.s12) {
                    MMStepRow(number: 1, text: "문자 앱에서 예약 문자를 길게 눌러요")
                    MMStepRow(number: 2, text: "공유를 누르고 진료메이트를 골라요")
                    MMStepRow(number: 3, text: "채워진 병원, 날짜, 시간을 확인하고 저장해요")
                    MMStepRow(number: 4, text: "진료메이트가 안 보이면 더보기에서 찾아주세요")
                }
            }
        }
    }
}

private enum ScheduleMetrics {
    /// 라벨과 칸 사이.
    static let labelGap: CGFloat = 7
    static let cardInset: CGFloat = 18
    static let pickedBorder: CGFloat = 1.5
    /// "새 카드 만들기" 같은 한 줄의 높이.
    static let rowHeight: CGFloat = MMSize.controlMd
    /// 빈 할 일 칸의 글자와 밑줄 사이. `MMCallout`의 빈 질문 칸과 같다.
    static let todoFieldGap: CGFloat = 5
}
