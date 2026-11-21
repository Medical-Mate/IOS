import Foundation
import Observation
import SwiftUI
import UIKit

/// 1e-1 브리핑 카드의 상태.
///
/// **읽기와 편집을 한 화면의 두 모드로 둔다.** 1e-1과 1e-1-E가 같은 카드의 두 모습이다.
/// 모드를 따로 두지 않고 `draft`의 유무로 가른다 — 둘을 따로 두면 "편집 중이라면서 사본이
/// 없는" 상태를 만들 수 있다.
@MainActor
@Observable
final class BriefCardModel {
    enum Sheet: Equatable {
        /// 1e-1-X 이미지로 내보내기.
        case export
        /// 1e-1-S 저장 직후 일정.
        case schedule
    }

    private(set) var card: BriefCard?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// 있으면 편집 모드다.
    private(set) var draft: BriefCardDraft?
    private(set) var isSaving = false
    /// 확인을 눌렀는데 서버가 받지 못했다. **편집 모드를 그대로 두고 알리기만 한다** —
    /// 닫아 버리면 방금 고친 것이 사라진다.
    private(set) var saveFailed = false

    /// 삭제 확인(1e-1-DC)이 떠 있는지. **편집 상태와 분리한다** — 삭제를 취소하면 편집
    /// 모드는 그대로 남아 있어야 한다.
    var isDeleteRequested = false
    var isTooltipOpen = false
    var sheet: Sheet?
    /// 내보내기 시트의 "이름·나이 가리기". **처음부터 켜 둔다** — 카드를 남에게
    /// 보이는 자리라 덜 내보내는 쪽이 기본이다. 시안(`1e-1-X` `3663:7479`)의 토글이
    /// 켜져 있고 Android도 `maskPatient = true`다.
    var masksPatient = true
    /// 이미지로 찍는 중인지. **찍는 동안만 켠다** — 내보내기 단추가 그림에 같이
    /// 찍히면 안 된다. Android도 찍는 동안 그 단추를 감춘다(#306 · #314).
    var isCapturing = false
    /// 공유 시트에 넘길 이미지. 있으면 시트가 뜬다.
    var sharing: UIImage?
    /// 사진에 넣지 못했을 때 적을 말. 넣은 것은 사진 앱이 알리므로 적지 않는다.
    var saveFailure: String?

    private let cardId: Int64
    private let repository: CardRepository
    private let calendar: Calendar
    private let today: @Sendable () -> Date

    init(
        cardId: Int64,
        repository: CardRepository,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.cardId = cardId
        self.repository = repository
        self.calendar = calendar
        self.today = today
    }

    // MARK: - 읽는 값

    var isEditing: Bool { draft != nil }

    var footerAction: BriefCardFooterAction? {
        card.map { BriefCardMapping.footerAction(for: $0, today: today(), calendar: calendar) }
    }

    /// 고친 것이 있는지. 상단 액션이 "취소"와 "확인"으로 갈린다(1e-1-E · 1e-1-E2).
    var hasChanges: Bool {
        guard let card, let draft else { return false }
        return draft.items != card.items || draft.questions != card.questions
    }

    /// 상단 오른쪽 액션.
    var actionTitle: String {
        guard isEditing else { return "편집" }
        return hasChanges ? "확인" : "취소"
    }

    var actionTone: MMNavBar.ActionTone {
        isEditing && !hasChanges ? .subtle : .primary
    }

    /// 카드 머리의 환자 줄.
    ///
    /// **가리기는 찍는 동안에만 건다.** 토글은 내보낼 이미지를 정하는 값이지 화면의
    /// 카드를 바꾸는 값이 아니다 — 켜 둔 채 시트를 닫으면 내 화면의 내 이름까지
    /// 가려진 채 남는다. Android도 `capturingMasked`를 찍는 동안만 켠다.
    var patientLine: String {
        guard let card else { return "" }
        return BriefCardModel.patientLine(card, masked: masksPatient && isCapturing)
    }

    /// 내보내기 시트의 미리보기가 보일 환자 줄. **토글을 따라 그 자리에서 바뀐다** —
    /// 토글이 무엇을 바꾸는지 보이는 곳이 여기뿐이다(Android도 같다).
    var exportPatientLine: String {
        guard let card else { return "" }
        return BriefCardModel.patientLine(card, masked: masksPatient)
    }

    nonisolated static func patientLine(_ card: BriefCard, masked: Bool) -> String {
        masked ? card.maskedPatientLine : card.patientLine
    }

    // MARK: - 읽기

    func load() async {
        errorMessage = nil
        switch await repository.card(id: cardId) {
        case .success(let response):
            card = BriefCardMapping.card(from: response, calendar: calendar)
            // **진료를 마쳤는지는 상세에 없을 수 있다**(Android `Backend#101`). 값이
            // 비어 오면 목록에서 본다 — 그러지 않으면 `1e-1`의 배지가 다녀온 뒤에도
            // 영영 "진료 전"이다. 고친 카드는 새 id를 받아서 옛 id로는 목록에 없을
            // 수 있고, 그때는 "진료 전"으로 남는다(Android도 같다).
            if response.visited == nil { await fillVisited() }
        case .rejected(let error):
            errorMessage = error.message ?? "카드를 불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isLoading = false
    }

    /// 목록에서 `visited`를 채운다. 못 받아도 조용히 둔다 — 카드는 이미 그려져 있다.
    private func fillVisited() async {
        guard let id = card?.id, case .success(let list) = await repository.cards() else { return }
        guard let listed = list.first(where: { $0.cardId == id }) else { return }
        card?.visited = listed.visited ?? false
    }

    // MARK: - 편집

    /// **항목별로 열지 않고 카드 전체를 한 번에 연다.** 그래야 "내가 직접 고칠 수 있다"가
    /// 전달된다.
    func beginEditing() {
        guard let card else { return }
        saveFailed = false
        draft = BriefCardDraft(card: card)
    }

    func cancelEditing() {
        draft = nil
        saveFailed = false
    }

    /// 상단 오른쪽을 눌렀을 때. 고친 것이 없으면 그냥 닫는다.
    func commitAction() async {
        guard isEditing else { return beginEditing() }
        guard hasChanges else { return cancelEditing() }
        await save()
    }

    func value(for item: BriefCardItem) -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.draft?.items.first { $0.id == item.id }?.value ?? item.value
            },
            set: { [weak self] newValue in
                guard let index = self?.draft?.items.firstIndex(where: { $0.id == item.id }) else { return }
                self?.draft?.items[index].value = newValue
            }
        )
    }

    func deleteItem(_ item: BriefCardItem) {
        draft?.items.removeAll { $0.id == item.id }
    }

    func deleteQuestion(at index: Int) {
        guard draft?.questions.indices.contains(index) == true else { return }
        draft?.questions.remove(at: index)
    }

    /// 빈 질문을 더한다(1e-1-A). **다섯이 차면 더해지지 않는다** — 증상 정리 3단계와
    /// 같은 상한이다.
    func addQuestion() {
        guard let draft, draft.questions.count < BriefCardQuestions.max else { return }
        self.draft?.questions.append("")
    }

    func question(at index: Int) -> Binding<String> {
        Binding(
            get: { [weak self] in
                guard let questions = self?.draft?.questions, questions.indices.contains(index) else { return "" }
                return questions[index]
            },
            set: { [weak self] newValue in
                guard self?.draft?.questions.indices.contains(index) == true else { return }
                self?.draft?.questions[index] = newValue
            }
        )
    }

    var canAddQuestion: Bool {
        (draft?.questions.count ?? 0) < BriefCardQuestions.max
    }

    private func save() async {
        guard let card, let draft, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        saveFailed = false

        let axes = BriefCardMapping.changedAxes(from: card.items, to: draft.items)
        let questions = draft.questions != card.questions ? BriefCardMapping.cleaned(draft.questions) : nil

        switch await repository.update(cardId: card.id, axes: axes, questions: questions) {
        case .success(let response):
            // **확정된 카드를 고치면 서버가 새 버전을 만든다.** 응답의 카드를 다시 그린다.
            self.card = BriefCardMapping.card(from: response, calendar: calendar)
            self.draft = nil
        case .rejected, .networkUnavailable:
            saveFailed = true
        }
    }

    // MARK: - 삭제

    func delete() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        switch await repository.delete(cardId: cardId) {
        case .success:
            return true
        case .rejected(let error):
            errorMessage = error.message ?? "삭제하지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        isDeleteRequested = false
        return false
    }
}
