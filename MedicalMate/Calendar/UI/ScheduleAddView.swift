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
    /// 재방문을 확정하러 들어왔으면 그 카드. 손으로 만들 때는 `nil`이다.
    var followUpCardId: Int64?
    let onBack: () -> Void
    let onSaved: (Int64) -> Void
    var onNewCard: () -> Void = {}

    @State private var model: ScheduleAddModel?
    /// 병원 찾기를 이 화면 안에서 연다. 고른 결과를 되돌려 받아야 해서 라우트로
    /// 내보내지 않는다.
    @State private var isPickingClinic = false
    /// 방금 선 할 일 줄. **더하면 바로 적을 수 있게 커서를 준다** — Android의
    /// `UnderlinedField`도 뜨자마자 초점을 가져간다. 빈 줄을 하나 더 눌러야
    /// 적기 시작하는 것은 "추가"를 두 번 누르게 하는 것과 같다.
    @FocusState private var focusedTodo: UUID?

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
                followUpCardId: followUpCardId,
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

                ScrollViewReader { proxy in
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

                        MMSectionHeader(title: "진료 전 할 일")

                        todoList(model, focus: $focusedTodo)

                        // **늘어난 줄을 따라간다.** 할 일을 더하면 키보드가 올라오고
                        // 방금 선 빈 줄이 그 뒤로 들어간다. 지우거나 처음 불러온
                        // 때에는 움직이지 않는다 — 보던 자리가 까닭 없이 튄다.
                        // Android `TodoSection`이 같은 규칙이다.
                        addRow(title: "할 일 추가") { model.addTodo() }
                            .id(ScheduleAnchor.addTodo)

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
                .onChange(of: model.todos.count) { was, now in
                    followNewTodo(model, was: was, now: now, proxy: proxy)
                }
                }

                footer(model)
            }

            overlays(model)
        }
        .background(MMColor.bgSurface)
    }

    /// 방금 선 할 일 줄에 커서를 주고 시야로 부른다.
    ///
    /// **지우거나 처음 불러온 때에는 움직이지 않는다** — 보던 자리가 까닭 없이 튄다.
    /// 키보드가 다 올라오기를 기다렸다 옮긴다. 올라오는 동안 옮기면 그때의 높이에
    /// 맞춰 놓고 끝나 도로 가려진다. Android `TodoSection`이 같은 규칙이다.
    private func followNewTodo(_ model: ScheduleAddModel, was: Int, now: Int, proxy: ScrollViewProxy) {
        guard now > was else { return }
        focusedTodo = model.todos.last?.id
        Task {
            try? await Task.sleep(for: .milliseconds(ScheduleMetrics.imeSettle))
            withAnimation { proxy.scrollTo(ScheduleAnchor.addTodo, anchor: .bottom) }
        }
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
                // **안내 문구는 `fg/subtle`이다.** 시안(`3663:14777`)은 `fg/muted`로
                // 그렸지만 그 토큰의 설명이 **"3.78:1 — 글자에 쓰지 않습니다 …
                // 플레이스홀더와 캡션은 fg/subtle을 씁니다"**라고 못박는다. Android도
                // 설명 쪽을 구현해 두었다(`PickerField.kt`). 두 기기를 맞춘다.
                //
                // **잘라내지 않는다.** 긴 병원 이름이 들어오는 칸이고 Android의
                // `PickerRow`도 `maxLines` 없이 `heightIn(min=)`으로 는다.
                Text(title)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(isFilled ? MMColor.fgDefault : MMColor.fgSubtle)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                icon.view(size: MMSize.iconMd)
                    .foregroundStyle(MMColor.fgDefault)
            }
            .padding(.leading, MMSpace.s16)
            .padding(.trailing, MMSpace.s12)
            // **칸이 는다.** 위에서 줄 수를 풀었으니 테두리도 따라 늘어야 둘째 줄이
            // 밖으로 새지 않는다. Android의 `PickerRow`도 `heightIn(min=)`이다.
            // 기본 글자 크기에서는 한 줄이라 56으로 서고 시안과 같다.
            .frame(minHeight: MMSize.controlLg)
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
        // **"새 카드 만들기"가 카드 목록 안에 든다.** 시안 `1r-4`(`3663:14803`)가 마지막
        // 카드와 이 줄 사이에 **10**을 두고, Android의 `CardSection`도 `AddRow`를 같은
        // `Column(spacedBy(s10))`에 넣는다. 밖에 두면 붙어 버려 카드 목록의 리듬이 깨진다.
        // 할 일 쪽은 반대다 — `TodoSection`이 `AddRow`를 바깥에 두고 시안도 0이다.
        VStack(spacing: ScheduleMetrics.cardListGap) {
            ForEach(model.cards) { item in
                cardRow(item, model: model)
            }

            addRow(title: "새 카드 만들기", action: onNewCard)
        }
    }

    private func cardRow(_ item: CardListItem, model: ScheduleAddModel) -> some View {
        let isPicked: Bool = {
            guard case .card(let id, _) = item.kind else { return false }
            return model.isPicked(id)
        }()

        return Button { model.toggleCard(item) } label: {
            HStack(spacing: MMSpace.s10) {
                // **체크박스가 제 줄 높이 52를 갖는다.** 시안(`3663:14792`)의 체크박스
                // 감싸개가 `py-14`라 24 상자가 52짜리 줄이 되고, 그래서 카드가 84로
                // 선다(16 + 52 + 16). 글 칸은 48뿐이라 이것 없이는 80으로 섰다.
                // `Checkbox` 마스터 설명도 "행 높이 52로 터치 하한을 넘는다"고 못박는다.
                MMSelectBox(isOn: .constant(isPicked))
                    .allowsHitTesting(false)
                    .padding(.vertical, ScheduleMetrics.selectBoxRowPad)

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

    /// 위 12 · 줄 사이 **10** · 아래 24. 시안 `1r-4`(`3663:14810`)가 안내 줄을 12에
    /// 두고 버튼을 40에 세운다(18 + 10). Android의 `MedicalMateFooter`도 `s10`이다.
    private func footer(_ model: ScheduleAddModel) -> some View {
        VStack(spacing: ScheduleMetrics.footerGap) {
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
                    if let id = await model.save() {
                        // 일정이 생겼으니 걸린 알림을 다시 맞춘다.
                        await app.reminders.refresh()
                        onSaved(id)
                    }
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
                    MMIconButton(icon: .chevronLeft, label: "지난달") { model.sheetGoToPreviousMonth() }
                    Text(model.sheetMonth.title)
                        .mmTextStyle(MMFont.headingM)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity)
                    MMIconButton(icon: .chevronRight, label: "다음달") { model.sheetGoToNextMonth() }
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

/// 스크롤을 부를 자리.
private enum ScheduleAnchor {
    case addTodo
}

enum ScheduleMetrics {
    /// 키보드가 다 올라오기를 기다리는 시간(ms). Android의 `IME_SETTLE_MS`와 같다.
    static let imeSettle = 120
    /// 라벨과 칸 사이.
    static let labelGap: CGFloat = 7
    static let cardInset: CGFloat = 18
    static let pickedBorder: CGFloat = 1.5
    /// "새 카드 만들기" 같은 한 줄의 높이.
    static let rowHeight: CGFloat = MMSize.controlMd
    /// 빈 할 일 칸의 글자와 밑줄 사이. `MMCallout`의 빈 질문 칸과 같다.
    static let todoFieldGap: CGFloat = 5
    /// 카드 줄과 "새 카드 만들기" 사이. 시안 `1r-4`와 Android `CardSection`이 둘 다 10이다.
    static let cardListGap = MMSpace.s10
    /// 아래 칸의 안내 줄과 버튼 사이. Android `MedicalMateFooter`와 같다.
    static let footerGap = MMSpace.s10
    /// 체크박스 줄(52)을 만드는 위아래 여백. 24 + 14 × 2 = 52.
    static let selectBoxRowPad = MMSpace.s14
    /// 그래서 선 카드의 높이. 16 + 52 + 16.
    static let cardPickHeight: CGFloat = 84
}
