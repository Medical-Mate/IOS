import SwiftUI

/// 들어온 컴포넌트를 한 화면에 모아 Figma 마스터와 눈으로 대조하는 자리.
///
/// 화면이 아니다. Android의 `MedicalMateScreenPreviews`와 같은 쓰임이고, 새 컴포넌트를
/// 더할 때마다 여기에도 한 줄 넣는다. 대조는 Figma 마스터를 열어 나란히 본다.
struct MMComponentGallery: View {
    @State private var chipSelected = true
    @State private var agreed = false
    @State private var tab: Tab = .home
    @State private var text = ""
    @State private var memo = "지난번에 받은 약을 먹고 속이 쓰렸어요."
    @State private var query = ""
    @State private var message = ""
    @State private var toggleOn = true
    @State private var severity = 3
    @State private var tooltipOpen = false
    @State private var picked = false
    @State private var morning = false
    @State private var hour = 7
    @State private var minute = 0
    @State private var reminderOn = true
    @State private var axisValue = "복부 (명치 아래 · 배꼽 위)"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MMSpace.s24) {
                section("Button · 291:670") {
                    MMButton("다음 단계로", kind: .primary) {}
                    MMButton("진료 기록 보기", kind: .tonal) {}
                    MMButton("이전", kind: .outline) {}
                    MMButton("나중에 하기", kind: .ghost) {}
                    MMButton("예약 취소", kind: .danger) {}
                    MMButton("비활성", kind: .primary) {}.disabled(true)
                }

                section("Icon Button · 298:715") {
                    HStack(spacing: MMSpace.s8) {
                        MMIconButton(icon: .chevronLeft, label: "뒤로", style: .ghost) {}
                        MMIconButton(icon: .chevronLeft, label: "뒤로", style: .tonal) {}
                        MMIconButton(icon: .chevronLeft, label: "뒤로", style: .solid) {}
                        MMIconButton(icon: .chevronLeft, label: "뒤로", style: .outline) {}
                    }
                }

                section("Social Login Button · 383:1302") {
                    MMSocialLoginButton(provider: .kakao) {}
                }

                section("Nav Bar · 298:739 / Tab Bar · 319:1026") {
                    MMNavBar(title: "기록", leading: .back, actionTitle: "저장")
                    MMTabBar(selection: $tab)
                }

                section("Badge · 311:834 / Chip · 311:823 / Number Badge · 3644:7400") {
                    HStack(spacing: MMSpace.s8) {
                        MMBadge(text: "진료 전", tone: .brand)
                        MMBadge(text: "완료", tone: .success)
                        MMBadge(text: "임시 저장", tone: .warning)
                        MMBadge(text: "응급", tone: .danger)
                    }
                    HStack(spacing: MMSpace.s8) {
                        MMChip(text: "두통", isSelected: chipSelected) { chipSelected.toggle() }
                        MMChip(text: "복통") {}
                        MMInfoChip(text: "긴 이미지 1장")
                        MMNumberBadge(number: 1)
                        MMNumberBadge(number: 2, tone: .subtle)
                    }
                }

                section("Card · 293:656 / Section Header · 334:1156 / Divider · 333:1088") {
                    MMSectionHeader(title: "최근 진료 기록", actionTitle: "전체 보기")
                    MMCard {
                        Text("진료 전 정리").mmTextStyle(MMFont.labelS).foregroundStyle(MMColor.fgSubtle)
                        Text("복부 통증 · 3주").mmTextStyle(MMFont.headingS).foregroundStyle(MMColor.fgDefault)
                        Text("3주 전 시작 · 최근 악화.").mmTextStyle(MMFont.bodyM).foregroundStyle(MMColor.fgSubtle)
                    }
                    MMDivider()
                }

                section("List Row · 335:1114 / KV Row · 333:1100 / Avatar · 311:839") {
                    MMListRow(title: "복부 통증 · 3주", meta: "2026.09.04 · 서울OO병원", badge: ("진료 전", .brand), action: {})
                    MMListRow(title: "복부 통증 · 3주", meta: "2026.09.04", selection: $picked, action: {})
                    MMKVRow(key: "부위", value: "복부 (하복부 중앙)")
                    MMKVRow(key: "강도", value: "많이 아파요", kind: .emphasis)
                    MMKVRow(key: "복용약", value: "이부프로펜", kind: .link, action: {})
                    MMKVEditRow(key: "부위", value: $axisValue, onDelete: {})
                    HStack(spacing: MMSpace.s12) {
                        MMAvatar(initial: "나")
                        MMAvatar(initial: "김", kind: .doctor)
                        // 1s-1의 프로필만 56이다.
                        MMAvatar(initial: "김", size: 56)
                    }
                }

                section("Bottom Sheet · 3663:7479") {
                    MMBottomSheet {
                        Text("진료 날짜가 정해졌나요?")
                            .mmTextStyle(MMFont.headingM)
                            .foregroundStyle(MMColor.fgDefault)
                            .padding(.top, MMSpace.s14)
                    }
                }

                section("Text Field · 295:692 / Text Area · 334:1102 / Search Field · 590:1307") {
                    MMTextField(label: "어떻게 아프신가요", text: $text, placeholder: "증상을 입력하세요", description: "짧게 적어도 괜찮아요")
                    MMTextArea(text: $memo, placeholder: "진료실에서 꼭 묻고 싶은 것을 적어두세요", onMic: {})
                    MMSearchField(text: $query, placeholder: "병원 이름을 적어주세요")
                }

                section("Checkbox · 311:851 / Toggle · 334:1155 / Setting Row · 3645:2327") {
                    MMCheckbox(text: "진료 기록을 병원에 전달하는 것에 동의합니다", isOn: $agreed)
                    HStack(spacing: MMSpace.s16) {
                        MMToggle(isOn: $toggleOn)
                        MMToggle(isOn: .constant(false))
                    }
                    MMSettingRow(title: "진료 전 알림", kind: .toggle($reminderOn, description: "확정 시 24시간 전"))
                    // 1s-1의 토글 줄은 제목이 굵다(인스턴스 덮어쓰기 · COMPONENT-MAP #22).
                    MMSettingRow(
                        title: "진료 전 알림",
                        kind: .toggle($reminderOn, description: "확정 시 24시간 전"),
                        isTitleStrong: true
                    )
                    MMSettingRow(title: "알림 시간", kind: .navigation(value: "오후 7:00", action: {}))
                    MMSettingRow(title: "진료 전 알림", kind: .value("24시간 전"))
                }

                section("Notice · 292:668 / Callout · 293:657") {
                    MMNotice(title: "지난 진료 기록을 이어받았어요", message: "3주 전에 적어두신 내용을 함께 보여드릴게요", tone: .info)
                    MMNotice(title: "증상이 응급일 수 있어요", message: "지금 바로 병원에 연락하세요", tone: .danger)
                    MMCallout(title: "환자가 묻고 싶어 하는 것", questions: ["검사를 받아야 하나요?", "지금 진통제 계속 먹어도 되나요?"])
                }

                section("Dialog · 312:845 / Tooltip · 542:1295") {
                    MMDialog(
                        title: "이 기록을 삭제할까요?",
                        message: "삭제하면 되돌릴 수 없어요.",
                        confirmTitle: "삭제",
                        onCancel: {},
                        onConfirm: {}
                    )
                    HStack(alignment: .top) {
                        MMTooltip(isPresented: $tooltipOpen, label: "브리핑 카드란")
                        if tooltipOpen { MMTooltipBubble(text: "여기에 짧은 설명이 들어갑니다") }
                    }
                }

                section("Severity Slider · 339:1293 / Severity Readout · 333:1126") {
                    MMSeveritySlider(level: $severity)
                    MMSeverityReadout(level: severity)
                }

                section("Bubble · 313:999 / Question Row · 3644:7446") {
                    MMBubble(text: "언제부터 그러셨어요? 정확하지 않아도 괜찮아요.", sender: .ai)
                    HStack { Spacer(); MMBubble(text: "한 3주쯤 됐어요.", sender: .patient) }
                    MMQuestionRow(number: 1, text: "검사를 받아야 하나요?", state: .selected, action: {})
                    MMQuestionRow(number: 2, text: "질문 직접 추가", state: .add, action: {})
                    MMTypingIndicator()
                }

                section("Chat Composer · 295:692 + 631:1294") {
                    MMChatComposer(text: $message) { _ in }
                    MMChatComposer(text: $message, showsMic: false) { _ in }
                }

                section("Progress · 334:1139 · 1155:854 / Step·Hint Row · 3644:7457 · 3645:2369") {
                    MMProgressIndicator(label: "증상 문답", step: 2)
                    MMOnboardingProgress(step: 2)
                    MMStepRow(number: 1, text: "문자 앱에서 예약 문자를 길게 눌러요")
                    MMHintRow(text: "예약 문자를 공유하면 바로 채워져요")
                }

                section("Empty State · 335:1166") {
                    MMEmptyState(kind: .noRecord)
                }

                section("Date Cell · 335:1188 / Calendar Grid · 3778:1868") {
                    HStack(spacing: MMSpace.s8) {
                        MMDateCell(day: 14, state: .default, action: {})
                        MMDateCell(day: 14, state: .today, action: {})
                        MMDateCell(day: 14, state: .selected, action: {})
                        MMDateCell(day: 14, state: .disabled, hasRecord: false)
                    }
                    MMCalendarGrid(days: Self.sampleMonth)
                }

                section("Time Wheel · 3645:2393") {
                    MMTimeWheel(isMorning: $morning, hour: $hour, minute: $minute)
                }

                section("Mate Card · 3532:5543 / Voice Input Mate · 3539:5647") {
                    MMMateCard(state: .speaking(text: "다음 진료 언제", pending: "야"), onClose: {})
                    MMVoiceInputMate()
                }

                section("Export Preview · 3610:10245") {
                    MMExportPreview()
                }

                section("Logo · 351:1281 · 351:1303 / Illustration · 3610:10270") {
                    HStack(spacing: MMSpace.s16) {
                        MMLogo.Symbol.gradient.view()
                        MMLogo.Symbol.flat.view()
                        MMLogo.Lockup.flat.view(height: 28)
                    }
                    MMIllustration.onboarding1.view().frame(height: 140)
                }
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.vertical, MMSpace.s24)
        }
        .background(MMColor.bgCanvas)
    }

    /// 마스터 기본값: 2026년 9월(1일 화요일) · 4일 기록 · 18일 선택 · 21일 오늘 · 26일 예정
    static let sampleMonth: [MMCalendarGrid.Day] = {
        var list = [MMCalendarGrid.Day.empty, .empty]
        for date in 1...30 {
            var day = MMCalendarGrid.Day(date: date)
            if date == 4 { day.dot = .record }
            if date == 18 { day.state = .selected }
            if date == 21 { day.state = .today }
            if date == 26 { day.dot = .scheduled }
            list.append(day)
        }
        while list.count % 7 != 0 { list.append(.empty) }
        return list
    }()

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s12) {
            Text(title)
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgMuted)
            content()
        }
    }
}

#Preview {
    MMComponentGallery()
}
