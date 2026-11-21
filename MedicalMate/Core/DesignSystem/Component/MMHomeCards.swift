import SwiftUI

/// 디자인 시스템 `Card / Action` (Figma `3313:4946`).
///
/// Figma 설명 그대로: 홈 **"증상 정리 시작하기" 진입 카드.** `bg/primary` 면 +
/// 아이콘 원(`bg/on-dark`) + `Elevation/Primary`.
///
/// **마스터가 `홈 · 신규 컴포넌트 (제안 · 미게시)` 프레임에 있다.** 그래도 게시된
/// 와이어프레임 `1n-2`(`3663:7011`) · `1n-1`(`3663:7018`)이 쓰고 있어서 화면에서
/// 읽어 옮겼다. 마스터가 게시되면 그쪽 값으로 다시 맞춘다.
struct MMCardAction: View {
    let caption: String
    let title: String
    var icon: MMIcon = .stethoscope
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: MMSpace.s2) {
                    Text(caption).mmTextStyle(MMFont.bodyS)
                    Text(title).mmTextStyle(MMFont.headingM)
                }
                .foregroundStyle(MMColor.fgOnPrimary)

                Spacer(minLength: 0)

                icon.view(size: MMSize.iconMd)
                    .foregroundStyle(MMColor.fgOnPrimary)
                    .frame(width: HomeCardMetrics.orb, height: HomeCardMetrics.orb)
                    .background(MMColor.bgOnDark)
                    .clipShape(Circle())
            }
            .padding(MMSpace.s20)
            .frame(maxWidth: .infinity)
            .background(MMColor.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
            .mmPrimaryElevation()
        }
        .buttonStyle(.plain)
    }
}

/// 디자인 시스템 `Card / Schedule` (Figma `3313:4967`).
///
/// Figma 설명 그대로: 홈 **"다가오는 일정".** 흰 카드 + 날짜 블록 + D-day `Badge`(Brand).
///
/// **D-day 배지는 이 화면에서 16 높이다.** `Badge` 마스터는 26인데 `1n-1`의 인스턴스가
/// 16으로 눌려 있다. 화면을 따랐고, 마스터를 쓰면 카드가 세로로 커진다.
struct MMCardSchedule: View {
    /// "9월" 같은 달.
    let month: String
    /// "25" 같은 날.
    let day: String
    /// "서울OO병원 · 금 오전 10:30".
    let meta: String
    /// "내과 재진".
    let title: String
    /// "D-7". 없으면 배지를 그리지 않는다.
    var dday: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MMSpace.s14) {
                VStack(spacing: 0) {
                    Text(month)
                        .mmTextStyle(MMFont.labelS)
                        .foregroundStyle(MMColor.fgSubtle)
                    Text(day)
                        .mmTextStyle(MMFont.numericM)
                        .foregroundStyle(MMColor.fgPrimary)
                }
                .frame(width: HomeCardMetrics.dateWidth, height: HomeCardMetrics.dateHeight)
                .background(MMColor.bgPrimaryFaint)
                .clipShape(RoundedRectangle(cornerRadius: MMRadius.sm))

                VStack(alignment: .leading, spacing: MMSpace.s2) {
                    Text(meta)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                    Text(title)
                        .mmTextStyle(MMFont.bodyLStrong)
                        .foregroundStyle(MMColor.fgDefault)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

                if let dday {
                    Text(dday)
                        .mmTextStyle(MMFont.labelS)
                        .foregroundStyle(MMColor.fgPrimary)
                        .padding(.horizontal, MMSpace.s8)
                        .frame(height: HomeCardMetrics.ddayHeight)
                        .background(MMColor.bgPrimarySubtle)
                        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xs))
                }
            }
            .padding(.horizontal, HomeCardMetrics.scheduleLeading)
            .padding(.vertical, MMSpace.s16)
            .frame(maxWidth: .infinity)
            .background(MMColor.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
            .mmShadow(MMElevation.card)
        }
        .buttonStyle(.plain)
    }
}

private enum HomeCardMetrics {
    static let orb: CGFloat = 44
    static let dateWidth: CGFloat = 44
    static let dateHeight: CGFloat = MMSize.controlMd
    static let ddayHeight: CGFloat = 16
    static let scheduleLeading: CGFloat = 18
}

extension View {
    /// `Elevation/Primary` — `#3B4FC0 28% (0, 8) blur 30 **spread -18**`.
    ///
    /// `.shadow`에 spread가 없어서 **도형을 18 줄여 뒤에 깔고 거기에 그림자를 건다.**
    /// 줄인 도형은 카드가 덮어 보이지 않고 그림자만 남는다. 그냥 `.shadow`를 걸면
    /// 그림자가 카드보다 커져 번져 보인다.
    func mmPrimaryElevation() -> some View {
        background {
            RoundedRectangle(cornerRadius: MMRadius.lg)
                .fill(MMColor.bgPrimary)
                .padding(PrimaryElevation.spread)
                .shadow(
                    // 날것의 `0x3B4FC0`을 적지 않는다 — `primary600`과 같은 값인데
                    // 팔레트가 바뀌면 이 자리만 어긋난다(CLAUDE.md 5장).
                    color: PrimaryElevation.color,
                    radius: PrimaryElevation.blur / 2,
                    y: PrimaryElevation.y
                )
        }
    }
}

private enum PrimaryElevation {
    /// `Elevation/Primary`의 그림자 색. 팔레트의 `primary600`이다.
    static let color = Palette.primary600.opacity(opacity)
    static let opacity: Double = 0.28
    static let blur: CGFloat = 30
    static let y: CGFloat = 8
    /// Figma의 spread -18.
    static let spread: CGFloat = 18
}

#Preview {
    VStack(spacing: MMSpace.s12) {
        MMCardAction(caption: "진료 전에", title: "증상 정리 시작하기") {}
        MMCardSchedule(
            month: "9월", day: "25",
            meta: "서울OO병원 · 금 오전 10:30",
            title: "내과 재진",
            dday: "D-7"
        ) {}
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
