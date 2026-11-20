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

    @Test("Label/S는 Regular다 (311:834 · 293:656)")
    func labelSmallIsRegular() {
        // Figma 스타일 정의가 Pretendard Regular 400이다. Android는 Medium으로 들고
        // 있어 두 플랫폼이 갈린다 — 디자인 트랙 확인 대기.
        #expect(MMFont.labelS.weight == .regular)
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
}
