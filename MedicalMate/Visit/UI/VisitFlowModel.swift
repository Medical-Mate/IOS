import Foundation
import SwiftUI
import Observation

/// 진료 후 기록 흐름(1m-12 → 1m → 1p → 1q-1)의 상태.
///
/// 한 모델이 네 자리를 들고 있는 이유: **고른 병원과 적은 메모가 끝까지 따라간다.**
/// 기록은 마지막 자리에서 한 번에 저장되고, 그 전까지는 서버에 아무것도 남지 않는다.
@MainActor
@Observable
final class VisitFlowModel {
    enum Phase: Equatable {
        /// 1m-12 — 일정에 등록해 둔 병원이 맞는지.
        case confirmClinic
        /// 1m — 다른 병원을 찾는다.
        case pickClinic
        /// 1p — 진료실에서 들은 말을 적는다.
        case note
        /// 1q-1 — AI가 나눈 결과를 보고 고치고 저장한다.
        case record
    }

    private(set) var phase: Phase = .confirmClinic

    private(set) var card: BriefCard?
    private(set) var clinic: BriefCardHospital?
    /// 진료받은 날. 일정이 있으면 그 날, 없으면 오늘이다.
    private(set) var visitedOn: Date?

    var memo = ""
    private(set) var classification: VisitClassification?
    /// 1q-1이 그리는 줄. 편집 사본이다.
    private(set) var items: [VisitItem] = []
    private(set) var savedVisitId: Int64?

    private(set) var isBusy = false
    private(set) var errorMessage: String?

    /// 다시 눌러 보라고 할지. **서버가 말해 준다** — 잠시 받지 못한 것(`retryable`)은
    /// 다시 누를 수 있고, 받지 않는 요청은 다시 눌러도 같다.
    nonisolated static func saveMessage(retryable: Bool) -> String {
        retryable ? saveFailed : saveRejected
    }

    /// 다시 누르면 되는 실패. 네트워크가 끊겼을 때다.
    nonisolated static let saveFailed = "저장하지 못했어요. 다시 눌러주세요."
    /// 다시 눌러도 안 되는 실패. **무엇을 먼저 해야 하는지**를 적는다 — 기록은 카드에
    /// 붙는 것이라 카드가 없으면 받아 줄 곳이 없다.
    nonisolated static let saveRejected = "다시 눌러도 저장되지 않아요. 브리핑 카드를 먼저 저장해야 기록을 남길 수 있어요."
    var isTooltipOpen = false
    var isDeleteRequested = false

    /// 기록에서 나온 재방문을 일정으로 올리는 쪽. 조립하는 자리가 잇는다.
    private let followUp: FollowUpScheduler?

    /// 편집 중인지. 1q-1-E의 사본이다.
    private(set) var draft: [VisitItem]?

    private let cardId: Int64
    private let cards: CardRepository
    private let visits: VisitRepository
    private let calendar: Calendar
    private let today: @Sendable () -> Date

    init(
        cardId: Int64,
        cards: CardRepository,
        visits: VisitRepository,
        followUp: FollowUpScheduler? = nil,
        calendar: Calendar = .current,
        today: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.cardId = cardId
        self.cards = cards
        self.visits = visits
        self.followUp = followUp
        self.calendar = calendar
        self.today = today
    }

    // MARK: - 읽는 값

    var isEditing: Bool { draft != nil }

    var hasChanges: Bool {
        guard let draft else { return false }
        return draft != items
    }

    var actionTitle: String {
        guard isEditing else { return "편집" }
        return hasChanges ? "확인" : "취소"
    }

    var actionTone: MMNavBar.ActionTone {
        isEditing && !hasChanges ? .subtle : .primary
    }

    /// 1p 카드의 "오늘 진료 · 9월 12일".
    var visitDayLabel: String {
        guard let visitedOn else { return "" }
        return VisitMapping.monthDay(visitedOn, calendar: calendar)
    }

    var isVisitToday: Bool {
        guard let visitedOn else { return true }
        return calendar.isDate(visitedOn, inSameDayAs: today())
    }

    /// 1m-12의 "9월 12일 일정에 등록해둔 병원이에요."
    var confirmMessage: String {
        "\(visitDayLabel) 일정에 등록해둔 병원이에요.\n다른 곳에서 진료받았다면 바꿀 수 있어요."
    }

    /// 1q-1 머리의 "서울OO병원 내과 · 2026.09.18".
    var recordMeta: String {
        VisitMapping.recordMeta(clinicName: clinic?.name, visitedOn: visitedOn, calendar: calendar)
    }

    /// 1p 카드의 둘째 줄.
    var cardLine: String {
        guard let card, !card.title.isEmpty else { return "브리핑 카드로 진료받았어요" }
        return "\(card.title) 브리핑 카드로 진료받았어요"
    }

    var canSaveNote: Bool {
        !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 들어오기

    func load() async {
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        switch await cards.card(id: cardId) {
        case .success(let response):
            let card = BriefCardMapping.card(from: response, calendar: calendar)
            self.card = card
            clinic = card.hospital
            visitedOn = card.appointment?.date ?? today()
            // 일정에 병원이 없으면 확인할 것이 없다. 바로 찾는 자리로 간다.
            phase = card.hospital == nil ? .pickClinic : .confirmClinic
        case .rejected(let error):
            errorMessage = error.message ?? "카드를 불러오지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
    }

    // MARK: - 병원

    func confirmClinic() {
        phase = .note
    }

    func changeClinic() {
        phase = .pickClinic
    }

    func pick(_ hospital: Hospital?) {
        if let hospital {
            clinic = BriefCardHospital(name: hospital.name, address: hospital.address)
        }
        phase = .note
    }

    func backFromPick() {
        // 확인할 병원이 있었으면 그 자리로 돌아간다. 없었으면 흐름을 나간다.
        phase = card?.hospital == nil ? .pickClinic : .confirmClinic
    }

    // MARK: - 메모

    func backToClinic() {
        phase = card?.hospital == nil ? .pickClinic : .confirmClinic
    }

    /// 메모를 항목으로 나눈다. **저장은 아직 하지 않는다.**
    func classifyMemo() async {
        let text = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        let result = await visits.classify(
            memo: text,
            visitedOn: visitedOn.map { VisitMapping.day($0, calendar: calendar) },
            clinicName: clinic?.name,
            labels: classification?.labels
        )

        switch result {
        case .success(let response):
            let classified = VisitMapping.classification(from: response, calendar: calendar)
            classification = classified
            items = classified.items
            phase = .record
        case .rejected(let error):
            errorMessage = error.message ?? "메모를 정리하지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
    }

    // MARK: - 기록

    func backToNote() {
        draft = nil
        phase = .note
    }

    func beginEditing() {
        draft = items
    }

    func cancelEditing() {
        draft = nil
    }

    func commitAction() {
        guard isEditing else { return beginEditing() }
        if hasChanges, let draft { items = draft }
        self.draft = nil
    }

    func value(for item: VisitItem) -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.draft?.first { $0.id == item.id }?.value ?? item.value
            },
            set: { [weak self] newValue in
                guard let index = self?.draft?.firstIndex(where: { $0.id == item.id }) else { return }
                self?.draft?[index].value = newValue
            }
        )
    }

    func deleteItem(_ item: VisitItem) {
        draft?.removeAll { $0.id == item.id }
    }

    /// 기록을 남긴다. **여기서 처음으로 서버에 쓴다.**
    func save() async -> Int64? {
        guard !isBusy else { return nil }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        let request = VisitMapping.createRequest(
            VisitMapping.Draft(
                clinicName: clinic?.name,
                visitedOn: visitedOn,
                items: items,
                followUp: classification?.followUp,
                patientNotes: classification?.patientNotes ?? [],
                rawNote: memo.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            calendar: calendar
        )

        switch await visits.create(cardId: cardId, request: request) {
        case .success(let response):
            savedVisitId = response.visitId
            // **저장이 곧 확인이다.** 재방문 줄의 날짜가 이 화면에 보이고 고칠 수 있어서,
            // 저장한 그 날짜로 일정을 만든다. 서버는 기록에서 일정을 만들지 않는다 —
            // AI가 날짜를 잘못 뽑아도 조용히 일정이 생기면 안 되기 때문이다.
            // **거절되면 만들지 않는다** — 이 자리는 성공한 뒤다.
            if let on = classification?.followUp?.date {
                await followUp?.schedule(clinic: clinic?.name, on: on, cardId: cardId)
            }
            return response.visitId
        case .rejected(let error):
            errorMessage = error.message ?? VisitFlowModel.saveMessage(retryable: error.isRetryable)
        case .networkUnavailable:
            errorMessage = VisitFlowModel.saveFailed
        }
        return nil
    }

    /// 저장하기 전에는 지울 것이 서버에 없다. 화면만 비우고 메모로 돌아간다.
    func delete() async -> Bool {
        isDeleteRequested = false
        guard let savedVisitId else {
            items = []
            classification = nil
            phase = .note
            return false
        }

        isBusy = true
        defer { isBusy = false }

        switch await visits.delete(visitId: savedVisitId) {
        case .success:
            return true
        case .rejected(let error):
            errorMessage = error.message ?? "삭제하지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        return false
    }

    func clearError() { errorMessage = nil }
}
