import SwiftUI

/// `1e-1` 위에 뜨는 것들 — 내보내기 시트(`1e-1-X`) · 저장 직후 일정 시트(`1e-1-S`) ·
/// 삭제 확인(`1e-1-DC`) · 툴팁(`1e-1-T`).
///
/// **화면 본문과 파일을 나눠 둔다.** 한 타입에 다 두면 본문이 300줄을 넘어 무엇이 화면이고
/// 무엇이 덮개인지 읽기 어렵다.
extension BriefCardView {
    @ViewBuilder
    func overlays(_ model: BriefCardModel) -> some View {
        if model.isDeleteRequested {
            MMOverlayScrim(onTap: { model.isDeleteRequested = false })
            MMDialog(
                title: "이 브리핑 카드를 삭제할까요?",
                message: "연결된 진료 기록은 남고 카드만 사라져요.",
                confirmTitle: "삭제",
                onCancel: { model.isDeleteRequested = false },
                onConfirm: {
                    Task {
                        if await model.delete() { onDeleted() }
                    }
                }
            )
            .padding(.horizontal, MMSize.gutter)
        }

        if let sheet = model.sheet {
            MMOverlayScrim(onTap: { model.sheet = nil })
            VStack {
                Spacer(minLength: 0)
                switch sheet {
                case .export:
                    exportSheet(model)
                case .schedule:
                    scheduleSheet(model)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    /// `1e-1-X` 이미지로 내보내기.
    private func exportSheet(_ model: BriefCardModel) -> some View {
        @Bindable var model = model

        return MMBottomSheet {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                Text("카드를 이미지로 내보내요")
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)

                Color.clear.frame(height: MMSpace.s4)

                Text("카드 전체가 긴 이미지 한 장으로 만들어져요.")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)

                Color.clear.frame(height: MMSpace.s16)

                MMExportPreview()

                Color.clear.frame(height: MMSpace.s8)

                HStack {
                    Text("이름·나이 가리기")
                        .mmTextStyle(MMFont.bodyM)
                        .foregroundStyle(MMColor.fgDefault)
                    Spacer(minLength: 0)
                    MMToggle(isOn: $model.masksPatient)
                }
                .padding(.vertical, MMSpace.s8)

                Color.clear.frame(height: MMSpace.s8)

                MMButton("이미지 저장") { model.sheet = nil }

                Color.clear.frame(height: MMSpace.s8)

                MMButton("공유하기", kind: .outline) { model.sheet = nil }
            }
        }
    }

    /// `1e-1-S` 저장 직후 일정.
    private func scheduleSheet(_ model: BriefCardModel) -> some View {
        MMBottomSheet {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                Text("진료 날짜가 정해졌나요?")
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)

                Color.clear.frame(height: MMSpace.s4)

                Text("일정에 넣어두면 진료 전과 진료 뒤에 알려드려요.")
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
                    .fixedSize(horizontal: false, vertical: true)

                Color.clear.frame(height: MMSpace.s20)

                MMButton("진료 일정 잡기") {
                    model.sheet = nil
                    onSchedule()
                }

                Color.clear.frame(height: MMSpace.s8)

                MMButton("아직 안 정했어요", kind: .ghost) { model.sheet = nil }
            }
        }
    }
}
