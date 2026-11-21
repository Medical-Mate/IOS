import SwiftUI

/// `1m-12 · 진료한 병원 선택` (Figma `3663:14315`).
///
/// 일정에 등록해 둔 병원을 먼저 보여 주고 맞는지만 묻는다. **검색을 거치지 않는 길이
/// 기본이다** — 병원을 막 나온 사람에게 다시 찾게 하지 않는다.
struct ClinicConfirmView: View {
    let clinic: BriefCardHospital
    let message: String
    let onBack: () -> Void
    let onChange: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MMNavBar(title: "진료 후 기록", leading: .back, onLeading: onBack)

            VStack(alignment: .leading, spacing: MMSpace.s20) {
                VStack(alignment: .leading, spacing: MMSpace.s8) {
                    Text("진료 받은 병원이 맞나요?")
                        .mmTextStyle(MMFont.headingL)
                        .foregroundStyle(MMColor.fgDefault)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(message)
                        .mmTextStyle(MMFont.bodyM)
                        .foregroundStyle(MMColor.fgSubtle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, MMSpace.s8)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    row
                    MMDivider()
                }

                changeButton
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.top, MMSpace.s12)
            .padding(.bottom, MMSpace.s16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            VStack(spacing: 0) {
                MMButton("이 병원이 맞아요", action: onConfirm)
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.top, MMSpace.s12)
            .padding(.bottom, MMSize.safeBottom)
            .background(MMColor.bgSurface)
        }
        .background(MMColor.bgSurface)
    }

    /// "다른 병원이에요".
    ///
    /// 마스터는 `Button / Ghost`인데 **인스턴스가 96×20으로 눌려 있다**(`3663:14326`) —
    /// 세 크기(56 · 48 · 40) 어디에도 맞지 않고 좌우 여백도 없다. 그래서 컴포넌트를
    /// 그대로 쓰지 않고 글자만 왼쪽에 세운다. 누르는 영역은 44를 확보한다.
    /// 디자인 트랙 확인 대기 — COMPONENT-MAP 3장 18번.
    private var changeButton: some View {
        Button(action: onChange) {
            Text("다른 병원이에요")
                .mmTextStyle(MMFont.labelL)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(minHeight: MMSize.touchMin, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 고른 줄이라 제목이 `fg/primary`다. 1m-B의 결과 줄과 같은 모양이고 **체크는
    /// 꺼져 있다**(마스터가 숨겼다) — 고를 것이 하나뿐이라 표시할 것이 없다.
    private var row: some View {
        VStack(alignment: .leading, spacing: MMSpace.s4) {
            Text(clinic.name)
                .mmTextStyle(MMFont.bodyLStrong)
                .foregroundStyle(MMColor.fgPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let address = clinic.address, !address.isEmpty {
                Text(address)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, MMSpace.s16)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ClinicConfirmView(
        clinic: BriefCardHospital(name: "서울OO병원 내과", address: "서울 관악구 남부순환로 1820, 3층"),
        message: "9월 12일 일정에 등록해둔 병원이에요.\n다른 곳에서 진료받았다면 바꿀 수 있어요.",
        onBack: {},
        onChange: {},
        onConfirm: {}
    )
}
