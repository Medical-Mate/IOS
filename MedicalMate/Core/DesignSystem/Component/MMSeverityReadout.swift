import SwiftUI

/// 디자인 시스템 `Severity Readout` (Figma `333:1126`).
///
/// Figma 설명 그대로:
/// > 브리핑 카드에서 통증 강도를 보여주는 **출력 전용.** 입력은 Severity Slider가 맡는다.
/// > **환자가 고른 낱말 + 단계 숫자 + NRS 등가를 함께 놓는다** — 환자는 낱말로 말하고
/// > 의사는 NRS로 읽는 격차를 여기서 메운다. **severity 색은 이 컴포넌트에만 쓴다.**
/// > 5단계 전부 잉크 글자가 4.80 이상으로 통과해 **글자색이 단계마다 바뀌지 않는다.**
struct MMSeverityReadout: View {
    let level: Int

    private var severity: MMSeverityLevel { .of(level) }

    var body: some View {
        HStack(spacing: MMSpace.s12) {
            Text("\(level)")
                .mmTextStyle(MMFont.bodyMStrong)
                .foregroundStyle(MMColor.fgDefault)
                .frame(width: ReadoutMetrics.chip, height: ReadoutMetrics.chip)
                .background(MMColor.severity(level))
                .clipShape(RoundedRectangle(cornerRadius: ReadoutMetrics.chipRadius))

            Text(severity.title)
                .mmTextStyle(MMFont.bodyLStrong)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(severity.nrs)
                .mmTextStyle(MMFont.bodyS)
                .foregroundStyle(MMColor.fgSubtle)
        }
        .accessibilityElement(children: .combine)
    }
}

private enum ReadoutMetrics {
    static let chip: CGFloat = 32
    static let chipRadius: CGFloat = 10
}

#Preview {
    VStack(spacing: MMSpace.s12) {
        ForEach(1...5, id: \.self) { MMSeverityReadout(level: $0) }
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
