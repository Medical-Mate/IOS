import SwiftUI

/// `1r-1-S · 캘린더 · 카드만 있는 날 시트` (Figma `3663:14570`).
///
/// 일정이 없고 카드만 쓴 날을 눌렀을 때 뜬다. **갈 화면이 없는 날이라** 그 자리에서
/// 무엇이 있는지 보여주고, 일정을 만들면 그때부터 일자 화면이 열린다.
///
/// 이 카드로 이미 만든 일정이 있으면 "만들기"가 아니라 "보러가기"가 된다 — 14일 카드로
/// 16일 일정을 만든 뒤 14일을 다시 눌러도 또 만들라고 하던 자리다.
struct CalendarCardSheet: View {
    let dayTitle: String
    let card: CalendarDayCard
    let calendar: Calendar

    var onOpenCard: (Int64) -> Void = { _ in }
    var onSchedule: () -> Void = {}

    var body: some View {
        MMBottomSheet {
            // 날짜 · 안내 · 구간 제목 · 줄을 한 묶음으로 둔다. 시안이 이 넷을 붙여 두고
            // `Section Header`의 안쪽 여백으로만 띄운다.
            VStack(alignment: .leading, spacing: 0) {
                Text(dayTitle)
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)
                    .padding(.top, MMSpace.s14)

                Text(hint)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
                    .padding(.top, MMSpace.s4)

                MMSectionHeader(title: "작성한 브리핑 카드")

                MMListRow(
                    title: card.title,
                    meta: card.meta(calendar: calendar),
                    badge: badge,
                    action: { onOpenCard(card.id) }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MMButton(buttonTitle, kind: .primary, action: onSchedule)
                .padding(.top, MMSpace.s16)
        }
    }

    /// 이미 만든 일정이 있으면 그 사실을 적는다.
    var hint: String {
        card.scheduled == nil
            ? "이 카드를 가져갈 일정을 만들 수 있어요"
            : "이 카드로 만들어진 일정이 있어요"
    }

    var buttonTitle: String {
        card.scheduled == nil ? "이 카드로 일정 만들기" : "일정 보러가기"
    }

    /// 배지는 **확정 여부가 아니라 `visited`로 가른다** — 서버 문서가 둘을 다른 축으로
    /// 둔다. 목록의 카드 줄(`Card.badge`)과 같은 값이다.
    private var badge: (text: String, tone: MMBadge.Tone) {
        card.visited ? ("진료 완료", .success) : ("진료 전", .brand)
    }
}
