import SwiftUI

/// 진료 후 기록 네 자리를 묶는 자리(F 섹션).
///
/// 1m-12 확인 → (1m 찾기) → 1p 메모 → 1q-1 기록. **마지막에 한 번만 저장한다** —
/// 그 전까지는 서버에 아무것도 남지 않아서, 도중에 나가도 반쪽짜리 기록이 생기지 않는다.
struct VisitFlowView: View {
    @Environment(\.appEnvironment) private var app

    let cardId: Int64
    let onClose: () -> Void
    let onSaved: (Int64) -> Void

    @State private var model: VisitFlowModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            guard model == nil else { return }
            let created = VisitFlowModel(cardId: cardId, cards: app.cards, visits: app.visits)
            model = created
            await created.load()
        }
    }

    @ViewBuilder
    private func content(_ model: VisitFlowModel) -> some View {
        switch model.phase {
        case .confirmClinic:
            if let clinic = model.clinic {
                ClinicConfirmView(
                    clinic: clinic,
                    message: model.confirmMessage,
                    onBack: onClose,
                    onChange: model.changeClinic,
                    onConfirm: model.confirmClinic
                )
            } else {
                Color.clear
            }

        case .pickClinic:
            HospitalPickView(
                purpose: .afterVisit,
                onBack: model.backFromPick,
                onSubmit: model.pick
            )

        case .note:
            VisitNoteView(model: model, onBack: model.backToClinic)

        case .record:
            VisitRecordView(model: model, onBack: model.backToNote, onSaved: onSaved)
        }
    }
}
