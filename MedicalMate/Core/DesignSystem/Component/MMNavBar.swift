import SwiftUI

/// 디자인 시스템 `Nav Bar` (Figma `298:739`).
///
/// Figma 설명 그대로:
/// > 상단 내비. 390 × 56. 좌우 48 슬롯 + 가운데 제목. 콘텐츠 위에 겹치므로
/// > `Surface/Glass`(흰 면 82% + 블러)를 쓴다. 스크롤하면 아래 내용이 비쳐 "더 있다"가
/// > 전달된다. **좌우 슬롯은 비어 있어도 48을 차지한다** — 제목이 항상 가운데 정렬로
/// > 고정되게 하기 위함이다. **우측 액션은 라벨 텍스트를 쓴다. 아이콘만 쓰면 무엇이
/// > 저장인지 알 수 없다.**
///
/// 제목은 좌우 슬롯 위에 겹쳐 가운데 정렬한다. 액션이 있으면 양쪽 여백이 88, 없으면
/// 60이다 — 제목이 길어도 액션을 덮지 않게 하는 값이다.
///
/// Android는 블러가 API 31부터라 Opaque 대안이 필수였다. iOS는 전 지원 버전에서 돈다.
struct MMNavBar: View {
    enum Leading { case back, close, none }
    enum ActionTone {
        case primary, subtle

        var color: Color {
            switch self {
            case .primary: MMColor.fgPrimary
            case .subtle: MMColor.fgSubtle
            }
        }
    }

    let title: String
    var leading: Leading = .back
    var onLeading: (() -> Void)?
    /// 우측 액션. 라벨을 반드시 적는다.
    var actionTitle: String?
    /// 액션의 색. 기본은 `fg/primary`이고, 되돌리는 액션("취소")은 `fg/subtle`이다
    /// (1e-1-E `3663:7530`).
    var actionTone: ActionTone = .primary
    var onAction: (() -> Void)?

    var body: some View {
        ZStack {
            HStack(spacing: NavBarMetrics.gap) {
                leadingSlot
                Spacer(minLength: 0)
                trailingSlot
            }
            .padding(.horizontal, MMSpace.s8)

            Text(title)
                .mmTextStyle(MMFont.headingS)
                .foregroundStyle(MMColor.fgDefault)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, actionTitle == nil ? NavBarMetrics.titleInset : NavBarMetrics.titleInsetWithAction)
                .frame(maxWidth: .infinity)
        }
        .frame(height: MMSize.navBarHeight)
        .background {
            MMColor.bgSurface.opacity(MMGlass.navBarOpacity)
                .background(.ultraThinMaterial)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MMColor.borderSubtle)
                .frame(height: NavBarMetrics.hairline)
        }
    }

    @ViewBuilder
    private var leadingSlot: some View {
        // 비어 있어도 자리를 차지한다. 제목을 가운데에 묶어 두기 위해서다.
        Group {
            switch leading {
            case .back: slotButton(.chevronLeft, label: "뒤로", action: onLeading)
            case .close: slotButton(.close, label: "닫기", action: onLeading)
            case .none: Color.clear
            }
        }
        .frame(width: NavBarMetrics.slot, height: NavBarMetrics.slot)
    }

    @ViewBuilder
    private var trailingSlot: some View {
        if let actionTitle {
            Button { onAction?() } label: {
                Text(actionTitle)
                    .mmTextStyle(MMFont.bodyLStrong)
                    .foregroundStyle(actionTone.color)
                    .padding(.leading, MMSpace.s8)
                    .padding(.trailing, MMSpace.s12)
                    .frame(height: NavBarMetrics.slot)
            }
        } else {
            Color.clear.frame(width: NavBarMetrics.slot, height: NavBarMetrics.slot)
        }
    }

    private func slotButton(_ icon: MMIcon, label: String, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            icon.view()
                .foregroundStyle(MMColor.fgDefault)
                .frame(width: NavBarMetrics.slot, height: NavBarMetrics.slot)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}

private enum NavBarMetrics {
    static let slot: CGFloat = MMSize.touchMin
    static let gap: CGFloat = MMSpace.s4
    static let hairline: CGFloat = 1
    static let titleInset: CGFloat = 60
    static let titleInsetWithAction: CGFloat = 88
}

#Preview {
    VStack(spacing: 0) {
        MMNavBar(title: "기록", leading: .back, actionTitle: "저장")
        MMNavBar(title: "기록", leading: .close)
        MMNavBar(title: "아주 긴 제목이 들어오면 가운데에서 잘립니다", leading: .back, actionTitle: "편집")
        MMNavBar(title: "제목만", leading: .none)
        Spacer()
    }
    .background(MMColor.bgCanvas)
}
