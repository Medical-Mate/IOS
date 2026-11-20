import SwiftUI

/// 디자인 시스템 `Section Header` (Figma `334:1156`).
///
/// Figma 설명 그대로:
/// > 목록 구간의 제목 + 보조 액션. **상단 여백 24가 앞 구간과의 거리를 만든다.** 보조
/// > 액션은 텍스트 링크다. **네이비 단색 체계라 링크와 버튼은 색이 아니라 면 유무로
/// > 갈린다.**
struct MMSectionHeader: View {
    let title: String
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack(spacing: MMSpace.s8) {
            Text(title)
                .mmTextStyle(MMFont.headingM)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle {
                Button { onAction?() } label: {
                    Text(actionTitle)
                        .mmTextStyle(MMFont.bodyMStrong)
                        .foregroundStyle(MMColor.fgLink)
                }
            }
        }
        .padding(.top, MMSpace.s24)
        .padding(.bottom, MMSpace.s10)
    }
}

#Preview {
    VStack(spacing: 0) {
        MMSectionHeader(title: "최근 진료 기록", actionTitle: "전체 보기")
        MMDivider()
        MMSectionHeader(title: "다가오는 일정")
    }
    .padding(.horizontal, MMSize.gutter)
    .background(MMColor.bgCanvas)
}
