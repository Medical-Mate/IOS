import SwiftUI

/// 디자인 시스템 `Hint Row` (Figma `3645:2369`).
///
/// Figma 설명 그대로: **하단 버튼 위 한 줄 안내.** 아이콘 18 + `Label/M` `fg/primary`,
/// 가운데. 1r-4 예약 문자 공유 · 1s-3 알림 시각 예시.
struct MMHintRow: View {
    let text: String
    var icon: MMIcon = .share

    var body: some View {
        HStack(spacing: MMSpace.s8) {
            icon.view(size: MMSize.iconSm)
            Text(text).mmTextStyle(MMFont.labelM)
        }
        .foregroundStyle(MMColor.fgPrimary)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// 디자인 시스템 `Step Row` (Figma `3644:7457`).
///
/// Figma 설명 그대로: 번호 + 한 줄 안내. **1r-4-S 예약 문자 방법 안내 시트의 단계
/// 목록.** 번호는 안쪽 `Number Badge`에서 바꾼다.
struct MMStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: MMSpace.s10) {
            MMNumberBadge(number: number)
            Text(text)
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: MMSpace.s12) {
        MMStepRow(number: 1, text: "문자 앱에서 예약 문자를 길게 눌러요")
        MMStepRow(number: 2, text: "공유에서 진료메이트를 골라요")
        MMHintRow(text: "예약 문자를 공유하면 바로 채워져요")
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
