import SwiftUI

/// 디자인 시스템 `Section Header` (Figma `334:1156`).
///
/// Figma 설명 그대로:
/// > 목록 구간의 제목 + 보조 액션. **상단 여백 24가 앞 구간과의 거리를 만든다.** 보조
/// > 액션은 텍스트 링크다. **네이비 단색 체계라 링크와 버튼은 색이 아니라 면 유무로
/// > 갈린다.**
struct MMSectionHeader: View {
    /// 오른쪽에 붙는 보조 글의 성격.
    enum Trailing {
        /// 눌러서 들어가는 링크. `fg/link`.
        case link(String, action: () -> Void)
        /// 세어 보여 주기만 하는 글. `fg/subtle`. 예: 1j-4의 "2장".
        case count(String)
        /// 고른 수. `fg/primary`. 예: 1j-4 편집의 "1장 선택됨".
        case selected(String)
    }

    let title: String
    var actionTitle: String?
    var onAction: (() -> Void)?
    /// `actionTitle`보다 먼저 본다. 셋 중 하나를 고른다.
    var trailing: Trailing?

    var body: some View {
        HStack(spacing: MMSpace.s8) {
            Text(title)
                .mmTextStyle(MMFont.headingM)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch trailing {
            case .link(let text, let action):
                Button(action: action) {
                    Text(text)
                        .mmTextStyle(MMFont.bodyMStrong)
                        .foregroundStyle(MMColor.fgLink)
                }
            case .count(let text):
                Text(text)
                    .mmTextStyle(MMFont.bodyMStrong)
                    .foregroundStyle(MMColor.fgSubtle)
            case .selected(let text):
                Text(text)
                    .mmTextStyle(MMFont.bodyMStrong)
                    .foregroundStyle(MMColor.fgPrimary)
            case .none:
                if let actionTitle {
                    Button { onAction?() } label: {
                        Text(actionTitle)
                            .mmTextStyle(MMFont.bodyMStrong)
                            .foregroundStyle(MMColor.fgLink)
                    }
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
