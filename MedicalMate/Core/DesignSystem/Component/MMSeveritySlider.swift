import SwiftUI

/// 통증 강도 한 단계가 들고 있는 말.
///
/// **값을 색만으로 전달하지 않는다** — 낱말과 상황 서술을 항상 함께 둔다(D11).
/// 문구는 Figma 마스터(`339:1293`)의 다섯 변형에서 그대로 가져왔다.
struct MMSeverityLevel: Sendable, Equatable {
    let level: Int
    let title: String
    let detail: String
    /// 임상 척도 대응. 화면에서는 꺼 두고 필요할 때만 켠다.
    let nrs: String

    static let all: [MMSeverityLevel] = [
        .init(level: 1, title: "조금 불편해요", detail: "신경 쓰이지만 하던 일은 계속할 수 있어요", nrs: "NRS 1–2"),
        .init(level: 2, title: "은근히 아파요", detail: "자꾸 생각나고 집중이 잘 안 돼요", nrs: "NRS 3–4"),
        .init(level: 3, title: "꽤 아파요", detail: "하던 일을 멈추게 될 때가 있어요", nrs: "NRS 5–6"),
        .init(level: 4, title: "많이 아파요", detail: "일상생활이 어렵고 참기 힘들어요", nrs: "NRS 7–8"),
        .init(level: 5, title: "견디기 힘들어요", detail: "잠도 못 자고 아무것도 못 하겠어요", nrs: "NRS 9–10")
    ]

    static func of(_ level: Int) -> MMSeverityLevel {
        all[min(max(level, 1), 5) - 1]
    }
}

/// 디자인 시스템 `Severity Slider` (Figma `339:1293`).
///
/// Figma 설명 그대로:
/// > 통증 강도 입력. **5단계로 스냅되는 선형 슬라이더이고 드래그와 정지점 탭 둘 다
/// > 받는다.** 판독 영역에 고른 단계의 색이 옅게 깔리고(`severity/*-tint`), 칩과 트랙
/// > 채움에 원색이 들어간다. **손잡이는 4px 브랜드 링이다** — 조작 대상은 브랜드, 값은
/// > severity. 두 축을 색으로 분리한다. severity 색을 손잡이에 쓰면 1단계(#FFE3A8)가
/// > 흰 배경에서 1.25:1이라 경계가 사라진다. 손잡이 28 + 트랙 영역 44로 터치 하한을
/// > 넘는다. **정지점 5개가 스냅 위치를 형태로 알린다.**
/// > **[구현 필수] 드래그만이 아니라 정지점 탭으로도 값이 바뀌어야 한다.** 드래그를
/// > 못 하는 상황과 사용자가 있다. **값을 색만으로 전달하지 않는다**(D11).
struct MMSeveritySlider: View {
    @Binding var level: Int
    /// 임상 척도(NRS)를 함께 보일지. 마스터 기본은 꺼짐이다.
    var showsNRS: Bool = false

    private var current: MMSeverityLevel { .of(level) }

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
            readout
            slider
            endLabels
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("통증 강도")
        .accessibilityValue("\(level)단계, \(current.title)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: level = min(level + 1, 5)
            case .decrement: level = max(level - 1, 1)
            default: break
            }
        }
    }

    private var readout: some View {
        HStack(spacing: MMSpace.s12) {
            Text("\(level)")
                .mmTextStyle(MMFont.bodyLStrong)
                .foregroundStyle(MMColor.fgDefault)
                .frame(width: SeverityMetrics.chip, height: SeverityMetrics.chip)
                .background(MMColor.severity(level))
                .clipShape(RoundedRectangle(cornerRadius: SeverityMetrics.chipRadius))

            VStack(alignment: .leading, spacing: MMSpace.s2) {
                Text(current.title)
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)
                Text(current.detail)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsNRS {
                Text(current.nrs)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
            }
        }
        .padding(.leading, MMSpace.s12)
        .padding(.trailing, MMSpace.s16)
        .padding(.vertical, MMSpace.s12)
        .frame(maxWidth: .infinity)
        .background(MMColor.severityTint(level))
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.buttonM))
    }

    private var slider: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let center = Self.center(for: level, in: width)

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(MMColor.bgSubtle)
                    .frame(width: width, height: SeverityMetrics.track)
                    .offset(y: SeverityMetrics.trackTop)

                Capsule()
                    .fill(MMColor.severity(level))
                    .frame(width: center, height: SeverityMetrics.track)
                    .offset(y: SeverityMetrics.trackTop)

                // 정지점. 스냅 위치를 형태로 알린다.
                ForEach(1...5, id: \.self) { stop in
                    Circle()
                        .fill(stop <= level ? MMColor.bgSurface : MMColor.borderDefault)
                        .frame(width: SeverityMetrics.stop, height: SeverityMetrics.stop)
                        .offset(x: Self.center(for: stop, in: width) - SeverityMetrics.stop / 2,
                                y: SeverityMetrics.stopTop)
                        // 드래그를 못 하는 사용자를 위해 정지점도 눌린다.
                        .contentShape(Rectangle().size(width: SeverityMetrics.thumb, height: SeverityMetrics.area))
                        .onTapGesture { level = stop }
                }

                thumb
                    .offset(x: center - SeverityMetrics.thumb / 2, y: SeverityMetrics.thumbTop)
            }
            .frame(width: width, height: SeverityMetrics.area)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        level = Self.level(atX: value.location.x, in: width)
                    }
            )
        }
        .frame(height: SeverityMetrics.area)
    }

    private var thumb: some View {
        Circle()
            .fill(MMColor.bgSurface)
            .frame(width: SeverityMetrics.thumb, height: SeverityMetrics.thumb)
            .overlay {
                // 조작 대상은 브랜드 색이다. 값(severity)과 축을 나눈다.
                Circle().strokeBorder(MMColor.bgPrimary, lineWidth: SeverityMetrics.ring)
            }
            .mmShadow(MMElevation.float)
    }

    private var endLabels: some View {
        HStack {
            Text("가벼운 불편")
            Spacer()
            Text("매우 심함")
        }
        .mmTextStyle(MMFont.bodyS)
        .foregroundStyle(MMColor.fgSubtle)
    }

    /// 단계의 가운데 x. 손잡이가 양 끝에서 트랙 밖으로 나가지 않게 반지름만큼 줄인 폭에 나눈다.
    static func center(for level: Int, in width: CGFloat) -> CGFloat {
        let usable = max(width - SeverityMetrics.thumb, 0)
        return SeverityMetrics.thumb / 2 + usable * CGFloat(min(max(level, 1), 5) - 1) / 4
    }

    /// x 좌표를 가장 가까운 단계로 스냅한다.
    static func level(atX x: CGFloat, in width: CGFloat) -> Int {
        let usable = max(width - SeverityMetrics.thumb, 1)
        let ratio = (x - SeverityMetrics.thumb / 2) / usable
        return min(max(Int((ratio * 4).rounded()) + 1, 1), 5)
    }
}

enum SeverityMetrics {
    static let chip: CGFloat = 34
    static let chipRadius: CGFloat = 11
    /// 트랙을 포함한 조작 영역. 손잡이 28보다 커서 터치 하한을 넘는다.
    static let area: CGFloat = 44
    static let track: CGFloat = 10
    static let trackTop: CGFloat = 17
    static let stop: CGFloat = 6
    static let stopTop: CGFloat = 19
    static let thumb: CGFloat = 28
    static let thumbTop: CGFloat = 8
    static let ring: CGFloat = 4
}

#Preview {
    @Previewable @State var level = 3
    return VStack(spacing: MMSpace.s24) {
        MMSeveritySlider(level: $level)
        MMSeveritySlider(level: .constant(5), showsNRS: true)
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
