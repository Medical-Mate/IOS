import SwiftUI

/// 디자인 시스템 `Empty State` (Figma `335:1166`).
///
/// Figma 설명 그대로:
/// > 비어 있는 화면. **사과가 아니라 초대다** — "아직 없어요"로 끝내지 않고 무엇을 하면
/// > 되는지로 잇는다. **액션은 Tonal이다. 빈 화면에서 채워진 브랜드 버튼은 과하다.**
/// > Offline은 **"작성한 내용은 남아 있다"를 먼저 말한다.** 사용자가 가장 먼저 걱정하는
/// > 것이 그것이다. MicDenied는 **권한을 요구하는 대신 대안을 준다.**
struct MMEmptyState: View {
    enum Kind { case noRecord, noResult, offline, micDenied }

    let kind: Kind
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: MMSpace.s12) {
            kind.icon.view(size: EmptyStateMetrics.icon)
                .foregroundStyle(MMColor.fgPrimary)
                .frame(width: EmptyStateMetrics.wrap, height: EmptyStateMetrics.wrap)
                .background(MMColor.bgPrimaryFaint)
                .clipShape(Circle())

            VStack(spacing: MMSpace.s6) {
                Text(kind.title)
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)
                Text(kind.message)
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
            }
            .multilineTextAlignment(.center)
            .padding(.top, MMSpace.s4)
            .frame(maxWidth: .infinity)

            MMButton(kind.actionTitle, kind: .tonal, size: .m, fill: false) { onAction?() }
        }
        .padding(.vertical, MMSpace.s40)
        .frame(maxWidth: .infinity)
    }
}

private enum EmptyStateMetrics {
    static let wrap: CGFloat = 72
    static let icon: CGFloat = 32
}

private extension MMEmptyState.Kind {
    var icon: MMIcon {
        switch self {
        case .noRecord: .emptyBox
        case .noResult: .searchOff
        case .offline: .wifiOff
        case .micDenied: .micOff
        }
    }

    var title: String {
        switch self {
        case .noRecord: "아직 진료 기록이 없어요"
        case .noResult: "찾는 기록이 없어요"
        case .offline: "연결이 끊어졌어요"
        case .micDenied: "마이크를 쓸 수 없어요"
        }
    }

    var message: String {
        switch self {
        case .noRecord: "증상을 정리해두면 진료실에서 바로 보여줄 수 있어요"
        case .noResult: "다른 날짜나 증상으로 다시 찾아보세요"
        case .offline: "작성한 내용은 이 기기에 남아 있어요.\n연결되면 이어서 저장할게요."
        case .micDenied: "설정에서 마이크 권한을 켜면 말로 입력할 수 있어요"
        }
    }

    var actionTitle: String {
        switch self {
        case .noRecord: "증상 정리하기"
        case .noResult: "전체 보기"
        case .offline: "다시 시도"
        case .micDenied: "직접 입력하기"
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            MMEmptyState(kind: .noRecord)
            MMEmptyState(kind: .noResult)
            MMEmptyState(kind: .offline)
            MMEmptyState(kind: .micDenied)
        }
        .padding(.horizontal, MMSize.gutter)
    }
    .background(MMColor.bgCanvas)
}
