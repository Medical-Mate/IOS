import SwiftUI

/// 디자인 시스템 `Notice` (Figma `292:668`).
///
/// Figma 설명 그대로:
/// > 화면에 **남는** 인라인 안내. 파스텔 면 + 흰 원형 아이콘 배지 + 제목/본문 2단.
/// > 이전 버전은 회색 상자에 아이콘 하나였고 Danger는 진한 빨강 채우기라 화면을
/// > 위협했다. 지금은 **톤이 면색으로만 말하고** 제목이 무슨 일인지, 본문이 무엇을
/// > 하면 되는지를 나눠 말한다. **아이콘을 흰 원형 배지에 얹는 이유**: 파스텔 면 위에
/// > 아이콘을 직접 놓으면 대비가 낮아 묻힌다. **제목은 `fg/{tone}`, 본문은 `fg/subtle`**
/// > — 톤 색을 본문까지 쓰면 읽기 피로하다. **Toast(사라짐)와 구분된다. Notice는 남는다.**
struct MMNotice: View {
    enum Tone { case info, success, warning, danger }

    let title: String
    let message: String
    var tone: Tone = .info

    var body: some View {
        HStack(alignment: .top, spacing: MMSpace.s12) {
            badge
            VStack(alignment: .leading, spacing: NoticeMetrics.textGap) {
                Text(title)
                    .mmTextStyle(MMFont.bodyMStrong)
                    .foregroundStyle(tone.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, MMSpace.s4)
        }
        .padding(.leading, MMSpace.s14)
        .padding(.trailing, MMSpace.s16)
        .padding(.vertical, MMSpace.s14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.container)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
    }

    private var badge: some View {
        tone.icon.view(size: MMSize.iconMd)
            .foregroundStyle(tone.accent)
            .frame(width: NoticeMetrics.badge, height: NoticeMetrics.badge)
            .background(MMColor.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
    }
}

private enum NoticeMetrics {
    static let badge: CGFloat = 32
    static let textGap: CGFloat = 3
}

private extension MMNotice.Tone {
    var container: Color {
        switch self {
        case .info: MMColor.bgInfo
        case .success: MMColor.bgSuccess
        case .warning: MMColor.bgWarning
        case .danger: MMColor.bgDanger
        }
    }

    var accent: Color {
        switch self {
        case .info: MMColor.fgInfo
        case .success: MMColor.fgSuccess
        case .warning: MMColor.fgWarning
        case .danger: MMColor.fgDanger
        }
    }

    var icon: MMIcon {
        switch self {
        case .info: .info
        case .success: .checkCircle
        case .warning: .alertTriangle
        case .danger: .alertCircle
        }
    }
}

#Preview {
    VStack(spacing: MMSpace.s12) {
        MMNotice(title: "지난 진료 기록을 이어받았어요", message: "3주 전에 적어두신 내용을 함께 보여드릴게요", tone: .info)
        MMNotice(title: "브리핑 카드를 저장했어요", message: "진료실에서 바로 보여주실 수 있어요", tone: .success)
        MMNotice(title: "알레르기를 확인하지 못했어요", message: "진료실에서 꼭 말씀해 주세요", tone: .warning)
        MMNotice(title: "증상이 응급일 수 있어요", message: "지금 바로 병원에 연락하세요", tone: .danger)
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
