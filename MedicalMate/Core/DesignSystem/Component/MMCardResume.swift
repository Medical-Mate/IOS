import SwiftUI

/// 디자인 시스템 `Card / Resume` (Figma `3313:4957`).
///
/// Figma 설명 그대로:
/// > 홈 "이어서 하기". 흰 카드 + 진행 원(n/3, Label/XS) + 화살표. 증상 정리를 멈춘
/// > 단계로 돌아감.
///
/// **프레임 이름이 `제안 · 미게시`라 한동안 옮기지 않았다.** 2026-11-22에 다시 보니
/// 라이브러리에는 게시돼 있었고, 그동안 iOS 홈은 `openIntake`를 읽기만 하고 그리지
/// 않아서 **문답을 멈춘 사람이 홈에서 돌아갈 길이 없었다.** 프레임 이름이 아니라
/// 라이브러리를 봐야 했다(COMPONENT-MAP 2장 2절).
struct MMCardResume: View {
    /// 몇 단계까지 했는지. 진행 원이 이만큼 찬다.
    let done: Int
    let total: Int
    /// 윗줄. "이어서 하기".
    var label: String = MMCardResume.defaultLabel
    /// 아랫줄. "두통 · 1단계까지 했어요".
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ResumeMetrics.gap) {
                ring

                VStack(alignment: .leading, spacing: MMSpace.s2) {
                    Text(label)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                    Text(title)
                        .mmTextStyle(MMFont.bodyLStrong)
                        .foregroundStyle(MMColor.fgDefault)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MMIcon.chevronRight.view(size: MMSize.iconMd)
                    .foregroundStyle(MMColor.fgDefault)
            }
            .padding(.horizontal, ResumeMetrics.insetH)
            .padding(.vertical, ResumeMetrics.insetV)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MMColor.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
            .mmShadow(MMElevation.card)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// 진행 원. **12시에서 시작해 시계 방향으로 찬다.**
    private var ring: some View {
        ZStack {
            Circle()
                .strokeBorder(MMColor.bgPrimarySubtle, lineWidth: ResumeMetrics.ring)
            Circle()
                .trim(from: 0, to: MMCardResume.fraction(done: done, total: total))
                .stroke(
                    MMColor.bgPrimary,
                    style: StrokeStyle(lineWidth: ResumeMetrics.ring, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(ResumeMetrics.ring / 2)

            Text(MMCardResume.progressLabel(done: done, total: total))
                .font(.pretendard(.bold, size: MMFont.labelXS.size))
                .foregroundStyle(MMColor.fgPrimary)
        }
        .frame(width: ResumeMetrics.size, height: ResumeMetrics.size)
    }

    static let defaultLabel = "이어서 하기"

    /// 가운데 글. "1/3".
    nonisolated static func progressLabel(done: Int, total: Int) -> String {
        "\(done)/\(max(total, 1))"
    }

    /// 원이 차는 비율. **총이 0이면 비워 둔다** — 나누지 않는다.
    nonisolated static func fraction(done: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        return min(max(CGFloat(done) / CGFloat(total), 0), 1)
    }

    /// 아랫줄의 글. Android `home_resume_step`과 같다.
    nonisolated static func stepTitle(_ site: String, done: Int) -> String {
        "\(site) · \(done)단계까지 했어요"
    }
}

enum MMCardResumeSpec {
    static let size = ResumeMetrics.size
    static let gap = ResumeMetrics.gap
    static let insetH = ResumeMetrics.insetH
    static let insetV = ResumeMetrics.insetV
}

private enum ResumeMetrics {
    /// 진행 원의 지름.
    static let size: CGFloat = 44
    static let ring: CGFloat = 4
    static let gap: CGFloat = 14
    static let insetH: CGFloat = 18
    static let insetV: CGFloat = 16
}

#Preview {
    MMCardResume(done: 1, total: 3, title: "두통 · 1단계까지 했어요", action: {})
        .padding(MMSize.gutter)
        .background(MMColor.bgCanvas)
}
