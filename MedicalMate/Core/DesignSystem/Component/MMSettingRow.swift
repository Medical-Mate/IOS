import SwiftUI

/// 디자인 시스템 `Setting Row` (Figma `3645:2327`).
///
/// Figma 설명 그대로:
/// > 설정 카드 안 한 줄, 폭 284(카드 패딩 안). **Type = Toggle(제목 + 설명 + 토글) ·
/// > Navigation(제목 + 값 선택 + 화살표, 최소 56) · Value(제목 + 읽기 전용 값, 최소 56).**
/// > 제목 `Body/L`, 설명 `Body/S subtle`, 값 `Body/M subtle`. 1s-1 내 정보 · 1s-3 알림 시간.
struct MMSettingRow: View {
    enum Kind {
        /// 제목 + 설명 + 토글. 누르는 순간 반영된다.
        case toggle(Binding<Bool>, description: String)
        /// 제목 + (값) + 화살표. 눌러서 들어간다.
        case navigation(value: String? = nil, action: () -> Void)
        /// 제목 + 읽기 전용 값.
        case value(String)
    }

    let title: String
    let kind: Kind
    /// 제목을 굵게. 마스터는 `Body/L`인데 **1s-1의 토글 줄 셋이 `Body/L Strong`으로
    /// 덮여 있다**(COMPONENT-MAP 3장 #22).
    var isTitleStrong = false

    var body: some View {
        switch kind {
        case .toggle(let isOn, let description):
            HStack {
                VStack(alignment: .leading, spacing: MMSpace.s2) {
                    Text(title)
                        .mmTextStyle(isTitleStrong ? MMFont.bodyLStrong : MMFont.bodyL)
                        .foregroundStyle(MMColor.fgDefault)
                    Text(description)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MMToggle(isOn: isOn)
            }
            .padding(.vertical, MMSpace.s12)

        case .navigation(let value, let action):
            Button(action: action) {
                HStack {
                    Text(title)
                        .mmTextStyle(MMFont.bodyL)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: MMSpace.s4) {
                        if let value {
                            Text(value)
                                .mmTextStyle(MMFont.bodyM)
                                .foregroundStyle(MMColor.fgSubtle)
                        }
                        MMIcon.chevronRight.view(size: MMSize.iconMd)
                            .foregroundStyle(MMColor.fgDefault)
                    }
                }
                .padding(.vertical, MMSpace.s12)
                .frame(minHeight: SettingRowMetrics.minHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

        case .value(let value):
            HStack(spacing: MMSpace.s12) {
                Text(title)
                    .mmTextStyle(MMFont.bodyL)
                    .foregroundStyle(MMColor.fgDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(value)
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
            }
            .padding(.vertical, MMSpace.s12)
            .frame(minHeight: SettingRowMetrics.minHeight)
        }
    }
}

private enum SettingRowMetrics {
    static let minHeight: CGFloat = MMSize.controlLg
}

#Preview {
    @Previewable @State var on = true
    return VStack(spacing: 0) {
        MMSettingRow(title: "진료 전 알림", kind: .toggle($on, description: "확정 시 24시간 전, 미정이면 전날 오후 7시"))
        MMSettingRow(title: "알림 시간", kind: .navigation(value: "오후 7:00", action: {}))
        MMSettingRow(title: "앱 버전", kind: .value("0.1.0"))
    }
    .padding(.horizontal, MMSize.gutter)
    .background(MMColor.bgSurface)
}
