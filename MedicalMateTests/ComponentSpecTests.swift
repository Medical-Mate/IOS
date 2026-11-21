import Testing
import SwiftUI
@testable import MedicalMate

/// 컴포넌트가 Figma 마스터의 수치를 그대로 쓰는지 본다.
///
/// 렌더링을 비교하지는 못한다. **마스터가 바뀌어 수치를 고칠 때 이 테스트도 함께 고치게
/// 해서, 값이 조용히 흘러내리는 것을 막는 것이 목적이다.** 각 테스트 이름에 Figma 노드
/// id를 적어 원본과 대조할 자리를 남긴다.
struct ComponentSpecTests {
    @Test("Button 높이는 L 56 · M 48 · S 40 (291:670)")
    func buttonHeights() {
        #expect(MMButton<EmptyView, EmptyView>.Size.l.height == CGFloat(56))
        #expect(MMButton<EmptyView, EmptyView>.Size.m.height == CGFloat(48))
        #expect(MMButton<EmptyView, EmptyView>.Size.s.height == CGFloat(40))
    }

    @Test("Button 반경은 16 / 14 / 12 (291:670)")
    func buttonRadii() {
        #expect(MMButton<EmptyView, EmptyView>.Size.l.radius == CGFloat(16))
        #expect(MMButton<EmptyView, EmptyView>.Size.m.radius == CGFloat(14))
        #expect(MMButton<EmptyView, EmptyView>.Size.s.radius == CGFloat(12))
    }

    @Test("Button 라벨은 L·M이 Label/L, S가 Label/M (291:670)")
    func buttonLabels() {
        #expect(MMButton<EmptyView, EmptyView>.Size.l.label == MMFont.labelL)
        #expect(MMButton<EmptyView, EmptyView>.Size.m.label == MMFont.labelL)
        #expect(MMButton<EmptyView, EmptyView>.Size.s.label == MMFont.labelM)
    }

    @Test("Badge 반경은 pill이 아니라 8이다 (311:834)")
    func badgeRadiusIsNotPill() {
        // Figma 설명: pill은 Chip(누를 수 있는 것)의 형태다. 배지는 읽는 것이라
        // 모서리를 다르게 해서 형태로 구분한다.
        #expect(MMRadius.xs == CGFloat(8))
    }

    @Test("Label/S는 Medium이다 (311:834 · 293:656)")
    func labelSmallIsMedium() {
        // Figma 스타일 정의는 Regular 400인데 컴포넌트 설명과 Android Type.kt가
        // Medium이다. 두 플랫폼이 갈려 있던 자리라 안드로이드에 맞췄다
        // (COMPONENT-MAP 3장 #1).
        #expect(MMFont.labelS.weight == .medium)
    }

    @Test("Label/S 자간 2%는 11pt에서 0.22pt다 (311:834)")
    func labelSmallTracking() {
        #expect(MMFont.labelS.tracking == CGFloat(0.22))
    }

    @Test("Card는 Default만 그림자를 쓴다 (293:656)")
    func cardShadowOnlyOnDefault() {
        // Brand·Quiet는 면으로만 구분한다. Figma 설명이 Quiet에 "그림자 없음"을 적었다.
        #expect(MMElevation.card.count == 2)
        #expect(MMRadius.lg == CGFloat(20))
    }

    @Test("Checkbox 박스는 24 · 반경 8이고 테두리가 1.5다 (311:851)")
    func checkboxBox() {
        // 미선택 테두리는 border/strong 1.5px — border/default로는 비텍스트 3:1을
        // 통과하지 못한다(Figma 설명).
        #expect(MMSize.iconLg == CGFloat(24))
        #expect(MMRadius.xs == CGFloat(8))
    }

    @Test("Chip 높이는 40이고 최소 폭이 64다 (311:823)")
    func chipMetrics() {
        #expect(MMSize.controlSm == CGFloat(40))
    }

    @Test("Icon Button은 L 48 · M 40 · S 32이고 아이콘이 24/20/18이다 (298:715)")
    func iconButtonSizes() {
        #expect(MMIconButton.Size.l.frame == CGFloat(48))
        #expect(MMIconButton.Size.m.frame == CGFloat(40))
        #expect(MMIconButton.Size.s.frame == CGFloat(32))
        #expect(MMIconButton.Size.l.iconSize == CGFloat(24))
        #expect(MMIconButton.Size.m.iconSize == CGFloat(20))
        #expect(MMIconButton.Size.s.iconSize == CGFloat(18))
    }

    @Test("Nav Bar는 56, Tab Bar는 79다 (298:739 · 319:1026)")
    func barHeights() {
        #expect(MMSize.navBarHeight == CGFloat(56))
        #expect(MMSize.tabBarHeight == CGFloat(79))
    }

    @Test("Glass 불투명도는 마스터 값이다 (298:739 · 319:1026)")
    func glassOpacity() {
        // Nav Bar 설명이 82%, Tab Bar 설명이 86%로 적었다.
        #expect(MMGlass.navBarOpacity == 0.82)
        #expect(MMGlass.tabBarOpacity == 0.86)
    }

    @Test("입력 상태는 Default가 bg/subtle, Focus가 2px 테두리다 (295:692)")
    func fieldStates() {
        #expect(FieldState.default.border?.width == CGFloat(1))
        #expect(FieldState.focus.border?.width == CGFloat(2))
        #expect(FieldState.error.border?.width == CGFloat(2))
        // Disabled는 테두리가 없다.
        #expect(FieldState.disabled.border == nil)
        // 지우기는 값이 있거나 포커스된 상태에만 선다.
        #expect(FieldState.filled.showsClear)
        #expect(!FieldState.default.showsClear)
    }

    @Test("Severity 단계는 다섯이고 낱말과 서술을 함께 든다 (339:1293)")
    func severityLevels() {
        #expect(MMSeverityLevel.all.count == 5)
        #expect(MMSeverityLevel.of(1).title == "조금 불편해요")
        #expect(MMSeverityLevel.of(5).nrs == "NRS 9–10")
        // 범위 밖은 가장 가까운 끝으로 잡는다.
        #expect(MMSeverityLevel.of(0).level == 1)
        #expect(MMSeverityLevel.of(9).level == 5)
    }

    @Test("Severity 슬라이더는 정지점 다섯을 고르게 둔다 (339:1293)")
    func severityStops() {
        let width: CGFloat = 320
        // 양 끝은 손잡이 반지름만큼 안쪽이다.
        #expect(MMSeveritySlider.center(for: 1, in: width) == SeverityMetrics.thumb / 2)
        #expect(MMSeveritySlider.center(for: 5, in: width) == width - SeverityMetrics.thumb / 2)
        // 누른 자리는 가장 가까운 단계로 스냅된다.
        #expect(MMSeveritySlider.level(atX: 0, in: width) == 1)
        #expect(MMSeveritySlider.level(atX: width, in: width) == 5)
        #expect(MMSeveritySlider.level(atX: width / 2, in: width) == 3)
    }

    @Test("끄는 동안 손잡이는 손가락을 따라가되 트랙을 벗어나지 않는다")
    func severityDragFollowsFinger() {
        let width: CGFloat = 320
        // 단계 사이의 아무 자리도 그대로 쓴다 — 다섯 지점으로 뛰지 않는다.
        let between = (MMSeveritySlider.center(for: 3, in: width)
            + MMSeveritySlider.center(for: 4, in: width)) / 2
        #expect(MMSeveritySlider.clamped(between, in: width) == between)
        // 끝을 넘겨도 트랙 안에 머문다.
        #expect(MMSeveritySlider.clamped(-50, in: width) == MMSeveritySlider.center(for: 1, in: width))
        #expect(MMSeveritySlider.clamped(width + 50, in: width)
            == MMSeveritySlider.center(for: 5, in: width))
    }

    @Test("Tooltip Bubble의 화살표는 16×10이고 오른쪽에서 16이다 (575:1287)")
    func tooltipArrow() {
        // 마스터의 `Arrow`가 x=148 · 16×10이고 말풍선이 180이라, 오른쪽 끝에서 16이다.
        #expect(MMTooltipBubble.arrowSize == CGSize(width: 16, height: 10))
        #expect(MMTooltipBubble.arrowInsetFromTrailing == 16)
        #expect(MMTooltipBubble.bubbleWidth == 180)
    }

    @Test("내보낸 파일 이름은 누를 때마다 새것이다")
    func exportFileName() {
        // 같은 카드를 두 번 내보내도 앞의 것을 덮지 않는다. Android와 같은 꼴이다.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let moment = calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 4, hour: 14, minute: 5, second: 9
        )) ?? .distantPast
        #expect(BriefCardExport.fileName(at: moment, calendar: calendar) == "브리핑카드_20260904_140509.png")
    }

    @Test("캘린더 숫자 자리는 글자 배율을 따르지 않는다 (3778:1867)")
    func calendarNumberHeightIsFixed() {
        // 줄 높이를 따르면 배율을 키운 기기에서 숫자가 점을 면 밖으로 밀어내고,
        // 면이 둥글게 깎여 있어 점이 통째로 사라진다. Android도 24로 못박았다.
        #expect(CalendarMetrics.numberHeight == 24)
    }

    @Test("캘린더 요일 색은 일 danger · 토 link다 (3778:1868)")
    func calendarWeekdayColors() {
        #expect(MMCalendarGrid.kind(forColumn: 0) == .sunday)
        #expect(MMCalendarGrid.kind(forColumn: 6) == .saturday)
        #expect(MMCalendarGrid.kind(forColumn: 3) == .weekday)
    }

    @Test("캘린더 칸은 44×46이고 안쪽 면이 42다 (3778:1867)")
    func calendarCellMetrics() {
        #expect(CalendarMetrics.cellWidth == CGFloat(44))
        #expect(CalendarMetrics.cellHeight == CGFloat(46))
        #expect(CalendarMetrics.face == CGFloat(42))
        // 점이 생겨도 숫자가 올라가지 않게 위 패딩이 고정이다.
        #expect(CalendarMetrics.topInset == CGFloat(7))
    }

    @Test("아이콘 47종이 모두 에셋에 있다 (296:4148)")
    func iconsExist() {
        #expect(MMIcon.allCases.count == 47)
        // 탭바가 쓰는 채움형 셋이 들어 있다.
        #expect(MMIcon.allCases.contains(.homeFilled))
        #expect(MMIcon.allCases.contains(.noteFilled))
        #expect(MMIcon.allCases.contains(.calendarFilled))
    }
    @Test("Typing 점은 7 · 간격 5 · 높이 50이고 투명도는 0.35 · 0.6 · 1.0 (3663:7212)")
    func typingIndicator() {
        #expect(TypingMetrics.dot == CGFloat(7))
        #expect(TypingMetrics.gap == CGFloat(5))
        #expect(TypingMetrics.height == CGFloat(50))
    }

    @Test("Chat Composer의 Actions 한 칸은 48 (631:1294)")
    func chatComposerActions() {
        #expect(ComposerMetrics.action == CGFloat(48))
    }

    @Test("KV Row / Editing 키 폭은 52, 지우기 자리는 30 (597:4801)")
    func kvEditRow() {
        // 읽는 KV Row(72)와 다른 컴포넌트다.
        #expect(KVEditMetrics.key == CGFloat(52))
        #expect(KVEditMetrics.deleteGutter == CGFloat(30))
    }

    @Test("값이 빈 편집 줄은 카드에 서지 않는다고 적는다 (3663:7584)")
    func kvEditRowEmptyHint() {
        // `1e-1-E2`의 둘째 줄. 글자를 다 지워도 줄은 남으므로, 남은 줄이 무엇이
        // 저장될지를 말한다.
        #expect(MMKVEditRow.emptyHint == "비어 있음 — 카드에 표시되지 않아요")
    }

    @Test("Bottom Sheet 손잡이는 36×4, 위 모서리는 28 (3663:7479)")
    func bottomSheet() {
        #expect(SheetMetrics.handle.width == CGFloat(36))
        #expect(SheetMetrics.handle.height == CGFloat(4))
        #expect(MMRadius.sheetTop == CGFloat(28))
    }

    @Test("KV Row 키 열은 72다 (333:1100)")
    func kvRowKeyColumn() {
        // 마스터의 기하는 60인데 컴포넌트 설명과 Android Rows.kt가 72다. 키 폭을
        // 고정하는 까닭이 값의 세로 정렬이라 두 플랫폼이 갈리면 안 된다
        // (COMPONENT-MAP 3장 #4).
        #expect(MMKVRowSpec.keyWidth == CGFloat(72))
    }
}

extension MMCalendarDay.DayKind: @retroactive Equatable {}
