import SwiftUI

/// 디자인 시스템 `Bubble` (Figma `313:999`).
///
/// Figma 설명 그대로:
/// > AI 문답의 발화 단위. **AI는 면색도 테두리도 없이 본문 + "AI" 라벨만 쓴다** —
/// > AI 대화 제품 관례(사용자만 버블, AI는 본문)를 따른다. 메신저의 "상대=회색 면"과
/// > 반대다. 환자는 `bg/primary-subtle` 면 + **우하 꼬리**. 화면에서 유색 큰 면을 가진
/// > 유일한 요소다. **AI에 테두리를 주지 않는 이유**: 카드·필드·알림이 이미 형태를
/// > 갖고 있어 선을 더하면 화면이 무거워진다. 그리고 **AI가 물러나 있어야 환자의 말이
/// > 남는다.**
struct MMBubble: View {
    enum Sender { case ai, patient }

    let text: String
    let sender: Sender

    var body: some View {
        switch sender {
        case .ai:
            VStack(alignment: .leading, spacing: MMSpace.s4) {
                Text("AI")
                    .mmTextStyle(MMFont.labelS)
                    .foregroundStyle(MMColor.fgSubtle)
                Text(text)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(MMColor.fgDefault)
            }
            .frame(maxWidth: BubbleMetrics.maxWidth, alignment: .leading)

        case .patient:
            Text(text)
                .mmTextStyle(MMFont.bodyL)
                .foregroundStyle(MMColor.fgDefault)
                .padding(.horizontal, MMSpace.s16)
                .padding(.vertical, MMSpace.s12)
                .frame(maxWidth: BubbleMetrics.maxWidth, alignment: .leading)
                .background(MMColor.bgPrimarySubtle)
                // 우하 꼬리. 한 모서리만 작게 둔다.
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: BubbleMetrics.radius,
                        bottomLeadingRadius: BubbleMetrics.radius,
                        bottomTrailingRadius: BubbleMetrics.tail,
                        topTrailingRadius: BubbleMetrics.radius
                    )
                )
        }
    }
}

private enum BubbleMetrics {
    static let maxWidth: CGFloat = 280
    static let radius: CGFloat = 18
    static let tail: CGFloat = 6
}

#Preview {
    VStack(alignment: .leading, spacing: MMSpace.s16) {
        MMBubble(text: "언제부터 그러셨어요? 정확하지 않아도 괜찮아요.", sender: .ai)
        HStack {
            Spacer()
            MMBubble(text: "한 3주쯤 됐어요. 요즘 더 아파요.", sender: .patient)
        }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
