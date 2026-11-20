import SwiftUI

/// 디자인 시스템 `Time Wheel` (Figma `3645:2393`).
///
/// Figma 설명 그대로:
/// > **오전/오후 · 시 · 분 휠, 5줄 284×240.** 일정 추가 시간 휠과 같은 띠
/// > (`primary-faint`, 반경 14) · 글자(**선택 줄 `Heading/S`, 나머지 `Body/L muted`,
/// > 바깥 줄 `disabled`**). 1s-3 알림 시간 카드 안.
///
/// iOS의 `DatePicker(.wheel)`을 쓰지 않는다. 시스템 휠은 띠 모양과 글자 단계를
/// 디자인대로 바꿀 수 없다. 세 칸을 직접 그린다.
struct MMTimeWheel: View {
    /// 오전이면 true.
    @Binding var isMorning: Bool
    /// 1~12.
    @Binding var hour: Int
    /// 0 또는 30.
    @Binding var minute: Int

    var body: some View {
        ZStack {
            // 선택 줄을 가리키는 띠.
            RoundedRectangle(cornerRadius: MMRadius.buttonM)
                .fill(MMColor.bgPrimaryFaint)
                .frame(height: TimeWheelMetrics.band)

            HStack(spacing: 0) {
                column(values: ["오전", "오후"], selection: isMorning ? "오전" : "오후") {
                    isMorning = ($0 == "오전")
                }
                column(values: (1...12).map(String.init), selection: String(hour)) {
                    hour = Int($0) ?? hour
                }
                column(values: ["00", "30"], selection: String(format: "%02d", minute)) {
                    minute = Int($0) ?? minute
                }
            }
        }
        .frame(width: TimeWheelMetrics.width, height: TimeWheelMetrics.height)
        .clipped()
    }

    /// 한 칸. 선택한 값을 가운데 두고 위아래 두 줄씩 보인다.
    private func column(values: [String], selection: String, onPick: @escaping (String) -> Void) -> some View {
        let index = values.firstIndex(of: selection) ?? 0
        return VStack(spacing: TimeWheelMetrics.rowGap) {
            ForEach(-2...2, id: \.self) { offset in
                let value = values.indices.contains(index + offset) ? values[index + offset] : " "
                Text(value)
                    .mmTextStyle(offset == 0 ? MMFont.headingS : MMFont.bodyL)
                    .foregroundStyle(color(for: offset))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if value != " " { onPick(value) }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 가운데에서 멀어질수록 가라앉는다.
    private func color(for offset: Int) -> Color {
        switch abs(offset) {
        case 0: MMColor.fgDefault
        case 1: MMColor.fgMuted
        default: MMColor.fgDisabled
        }
    }
}

private enum TimeWheelMetrics {
    static let width: CGFloat = 284
    static let height: CGFloat = 240
    static let band: CGFloat = MMSize.controlMd
    static let rowGap: CGFloat = MMSpace.s14
}

#Preview {
    @Previewable @State var morning = false
    @Previewable @State var hour = 7
    @Previewable @State var minute = 0

    return MMTimeWheel(isMorning: $morning, hour: $hour, minute: $minute)
        .padding(MMSize.gutter)
        .background(MMColor.bgSurface)
}
