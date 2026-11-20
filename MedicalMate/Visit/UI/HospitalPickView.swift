import SwiftUI

/// `1m-B · 병원 찾기 · 진료 전` (Figma `3663:7302` 입력 전 · `3663:7311` 결과).
///
/// 두 장은 같은 화면의 두 상태다 — 검색 결과가 비면 빈 자리가 서고, 차면 목록이 선다.
/// **검색 전에도 빈 자리다**: 서버 검색은 질의가 있어야 답이 오고, 시안의 "결과 네 곳이
/// 먼저 보이는" 모양은 픽스처였다(Android #155, 디자인 트랙에 올라가 있다).
///
/// 진료 **후**(`1m`)도 같은 화면이고 제목 · 안내 · 버튼 라벨만 다르다. F 섹션에서 그
/// 마스터를 읽고 갈래를 더한다.
struct HospitalPickView: View {
    @Environment(\.appEnvironment) private var app

    let onBack: () -> Void
    /// 고른 병원을 들고 카드를 만든다. 고르지 않았으면 `nil`이다 — **건너뛸 수 있다.**
    let onSubmit: (Hospital?) -> Void
    /// 카드를 만드는 중인지. 흐름이 들고 있다.
    var isSubmitting = false
    var errorMessage: String?

    @State private var model: HospitalPickModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil {
                model = HospitalPickModel(repository: app.hospitals)
            }
        }
        .onDisappear { model?.cancel() }
    }

    private func content(_ model: HospitalPickModel) -> some View {
        @Bindable var model = model

        return VStack(spacing: 0) {
            MMNavBar(title: "병원 찾기", leading: .back, onLeading: onBack)

            VStack(alignment: .leading, spacing: MMSpace.s20) {
                VStack(alignment: .leading, spacing: MMSpace.s8) {
                    Text("진료받을 병원을 찾아주세요")
                        .mmTextStyle(MMFont.headingL)
                        .foregroundStyle(MMColor.fgDefault)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("아직 정하지 않았다면 건너뛰어도 돼요.\n진료 후에 등록할 수 있어요.")
                        .mmTextStyle(MMFont.bodyM)
                        .foregroundStyle(MMColor.fgSubtle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, MMSpace.s8)
                .frame(maxWidth: .infinity, alignment: .leading)

                MMSearchField(text: $model.query, placeholder: "병원 이름 검색")

                Text(model.resultLabel)
                    .mmTextStyle(MMFont.labelM)
                    .foregroundStyle(labelColor(model))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let errorMessage {
                    Text(errorMessage)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgDanger)
                }

                // 빈 자리는 남은 높이를 채우고 가운데에 선다(`3663:7310`). 목록은
                // 넘치면 구르고, 그때 빈 자리는 없다.
                if model.showsEmptyState {
                    emptyState
                } else {
                    ScrollView {
                        results(model)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.top, MMSpace.s12)
            .padding(.bottom, MMSpace.s16)
            .frame(maxHeight: .infinity, alignment: .top)

            footer(model)
        }
        .background(MMColor.bgSurface)
    }

    /// 결과 줄의 색. 개수는 `fg/primary`, 없음·실패·안내는 `fg/subtle`이다(`3663:7318` · `7309`).
    private func labelColor(_ model: HospitalPickModel) -> Color {
        model.result.hospitals.isEmpty || model.isSearching || model.hasFailed || model.result.isTruncated
            ? MMColor.fgSubtle
            : MMColor.fgPrimary
    }

    /// **병원 아이콘이다.** 시안의 인스턴스가 `search-off`를 `hospital`로 바꿔 놓았다.
    private var emptyState: some View {
        MMEmptyState(
            icon: .hospital,
            title: "아직 검색 기록이 없어요",
            message: "병원 명을 입력하면 진료받을 병원을 찾을 수 있어요"
        )
        .frame(maxWidth: .infinity)
        .frame(maxWidth: HospitalPickMetrics.emptyWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func results(_ model: HospitalPickModel) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(model.result.hospitals.enumerated()), id: \.element.id) { index, hospital in
                if index > 0 { MMDivider() }
                row(hospital, model: model)
            }
        }
    }

    /// 고른 줄은 제목이 `fg/primary`가 되고 오른쪽에 체크가 선다.
    ///
    /// 이 화면은 `List Row`를 **카드가 아니라 평평한 줄**로 쓰고 사이에 `Divider`를
    /// 둔다(`3663:7319`). `List Row` 설명은 "인터랙션이 있는 행과 구분선을 함께 쓰지
    /// 않는다"고 적었는데, 시안이 그렇게 그려 두었다 — 검색 결과는 밀도가 높아 선이
    /// 필요한 자리다.
    private func row(_ hospital: Hospital, model: HospitalPickModel) -> some View {
        HStack(spacing: MMSpace.s8) {
            VStack(alignment: .leading, spacing: MMSpace.s4) {
                Text(hospital.name)
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(model.isPicked(hospital) ? MMColor.fgPrimary : MMColor.fgDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let address = hospital.address, !address.isEmpty {
                    Text(address)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if model.isPicked(hospital) {
                MMIcon.check.view()
                    .foregroundStyle(MMColor.fgPrimary)
            }
        }
        .padding(.vertical, MMSpace.s16)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { model.toggle(hospital) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(model.isPicked(hospital) ? [.isSelected, .isButton] : .isButton)
    }

    private func footer(_ model: HospitalPickModel) -> some View {
        VStack(spacing: 0) {
            MMButton("브리핑 카드 만들기") {
                onSubmit(model.picked)
            }
            .disabled(isSubmitting)
        }
        .padding(.horizontal, MMSize.gutter)
        .padding(.top, MMSpace.s12)
        .padding(.bottom, MMSize.safeBottom)
        .background(MMColor.bgSurface)
    }
}

private enum HospitalPickMetrics {
    /// 빈 자리의 폭. 마스터가 320이다.
    static let emptyWidth: CGFloat = MMSize.contentWidth
}
