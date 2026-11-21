import Foundation
import Observation

/// 증상 정리 2 · 3단계의 상태.
///
/// 한 모델이 두 단계를 들고 있는 이유: **세션이 두 단계에 걸쳐 산다.** 강도에서 열고
/// 문답에서 이어 가며, 강도로 돌아가 다시 고르면 세션을 새로 열지 않고 그 값만 고친다
/// (FEATURE-SPEC 2.3). 단계마다 모델을 두면 그 세션 id를 어디에 둘지가 애매해진다.
@MainActor
@Observable
final class IntakeModel {
    enum Phase: Equatable {
        /// 1d — 통증 강도(2/3).
        case severity
        /// 1c-2 · 1c-3 · 1c-D~D4 — 문답과 추천 질문(3/3).
        case chat
        /// 1c-5 — 증상 정리 완료.
        case done
        /// 1m-B — 진료받을 병원 찾기. 완료 화면에서 "먼저 찾기"로 들어온다.
        case hospital
    }

    private(set) var phase: Phase = .severity
    /// 짚은 부위. 1단계가 넘겨주고, 이어서 하는 경우에는 서버가 들고 있다.
    private(set) var site: IntakeSite

    /// 통증 강도. 마스터의 기본값은 3이다.
    var severity: Int = 3

    private(set) var sessionId: Int64?
    private(set) var messages: [IntakeMessage] = []
    /// AI가 답을 짓는 중(1c-3). 점 셋이 선다.
    private(set) var isAnswering = false
    /// 문답이 끝났는지. 서면 추천 질문 줄이 선다.
    private(set) var isEnded = false
    private(set) var rows: [IntakeQuestionRow] = []
    private(set) var isBusy = false
    private(set) var errorMessage: String?

    /// 빈 칸을 눌러 직접 적는 중인지(1c-D2 · 1c-D3).
    private(set) var isWritingOwn = false
    /// 입력 줄에 적힌 글.
    var draft = ""
    /// 받아쓰기를 켜기 전에 적어 둔 글. 끄면 이것으로 되돌린다.
    private var draftBeforeVoice: String?

    private let repository: IntakeRepository

    init(site: IntakeSite, repository: IntakeRepository) {
        self.site = site
        self.repository = repository
    }

    /// 열린 문답을 이어서 한다(홈 · 1j-4의 "이어서 정리하기").
    ///
    /// 부위는 서버가 들고 있다 — 이어서 하는 길에서는 1단계를 다시 지나지 않는다.
    /// 대화가 이미 쌓여 있으면 문답 자리로, 강도만 골라 둔 상태면 강도 자리로 선다.
    func resume(sessionId id: Int64) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        switch await repository.session(id: id) {
        case .success(let response):
            apply(response)
            if let text = response.siteText, !text.isEmpty {
                site = IntakeSite(nodeId: response.siteNodeId, text: text)
            }
            isEnded = !IntakeRepository.candidates(from: response.questionCandidates).isEmpty
            phase = messages.isEmpty ? .severity : .chat
        case .rejected(let error):
            errorMessage = error.message ?? "이어서 하지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
    }

    // MARK: - 읽는 값

    var step: IntakeStep { phase == .severity ? .severity : .chat }

    var selectedQuestions: [String] { IntakeRepository.selected(in: rows) }

    var showsBlankRow: Bool { IntakeRepository.showsBlankRow(rows) }

    /// 빈 칸 번호. 줄 다음 번호다.
    var blankNumber: Int { rows.count + 1 }

    /// 줄 아래 서는 AI 말(1c-D1 · 1c-D4).
    /// 질문 줄 위의 AI 말(`1c-D`). 추천이 하나도 없으면 서지 않는다.
    var questionIntro: String? { IntakeRepository.intro(rows: rows) }
    var questionSummary: String? { IntakeRepository.summary(rows: rows) }

    /// 더 담을 수 있는지. 차면 체크도 빈 칸도 막힌다.
    var isFull: Bool { selectedQuestions.count >= BriefCardQuestions.max }

    // MARK: - 2단계

    /// 강도를 정하고 문답으로 넘어간다.
    ///
    /// **세션은 여기서 한 번만 연다.** 돌아와 다시 고르면 새로 열지 않고 값만 고친다.
    func confirmSeverity() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        if let sessionId {
            switch await repository.updateSeverity(sessionId: sessionId, level: severity) {
            case .success:
                phase = .chat
            case .rejected(let error):
                errorMessage = error.message ?? "강도를 고치지 못했어요."
            case .networkUnavailable:
                errorMessage = "연결이 끊어졌어요."
            }
            return
        }

        switch await repository.start(site: site, severity: severity) {
        case .success(let response):
            apply(response)
            phase = .chat
        case .rejected(let error):
            errorMessage = error.message ?? "문답을 열지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
    }

    func backToSeverity() {
        phase = .severity
    }

    /// 완료 화면에서 뒤로. 고른 질문은 그대로 있고 다시 고칠 수 있다.
    func backToChat() {
        phase = .chat
    }

    func goToHospital() {
        errorMessage = nil
        phase = .hospital
    }

    func backToDone() {
        errorMessage = nil
        phase = .done
    }

    // MARK: - 3단계 · 문답

    func send(_ text: String, by method: IntakeInputMethod = .text) async {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let sessionId, !value.isEmpty, !isAnswering else { return }

        // 보낸 말을 먼저 세운다. 서버가 돌아올 때까지 화면이 비어 있으면 눌렀는지
        // 알 수 없다. 서버 응답이 대화 전체를 주므로 이 임시 줄은 그때 덮인다.
        messages.append(IntakeMessage(seq: nextSeq, fromPatient: true, text: value))
        draft = ""
        isAnswering = true
        errorMessage = nil

        let result = await repository.send(sessionId: sessionId, text: value, by: method)
        isAnswering = false

        switch result {
        case .success(let turn):
            apply(turn)
        case .rejected(let error):
            errorMessage = error.message ?? "보내지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
    }

    // MARK: - 3단계 · 추천 질문

    func toggle(_ row: IntakeQuestionRow) {
        guard let index = rows.firstIndex(where: { $0.id == row.id }) else { return }
        // 다섯 개가 차면 더 체크되지 않는다. 푸는 것은 언제나 된다.
        if !rows[index].isSelected, isFull { return }
        rows[index].isSelected.toggle()
    }

    /// 빈 칸을 눌렀다(1c-D2). 입력 줄이 선다.
    func beginWritingOwn() {
        guard !isFull else { return }
        draft = ""
        isWritingOwn = true
    }

    /// 직접 적은 질문을 줄로 세운다. 적자마자 체크된 상태로 들어간다.
    func addOwn(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isWritingOwn = false
        draft = ""
        guard !value.isEmpty, !isFull else { return }
        rows.append(IntakeQuestionRow(text: value, isSelected: true, isOwn: true))
    }

    func cancelWritingOwn() {
        isWritingOwn = false
        draft = ""
    }

    /// 고른 질문을 확정하고 완료 화면으로.
    func confirmQuestions() async {
        guard let sessionId, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        switch await repository.confirmQuestions(sessionId: sessionId, questions: selectedQuestions) {
        case .success:
            phase = .done
        case .rejected(let error):
            // 상한을 넘기면 서버가 거절한다. **버리지 말고 알린다** — Android의 결함이다.
            errorMessage = error.message ?? "질문을 담지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
    }

    // MARK: - 카드 만들기

    /// 문답을 브리핑 카드로 굳힌다.
    ///
    /// 병원은 **선택이다** — 완료 화면에서 바로 만들면 비어 있고, 1m-B를 지나 왔으면
    /// 고른 곳이 실린다. 고르지 않고 지나왔어도 비운다(건너뛸 수 있다).
    func createCard(clinicName: String? = nil, clinicAddress: String? = nil) async -> Int64? {
        guard let sessionId, !isBusy else { return nil }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        let result = await repository.createCard(
            sessionId: sessionId,
            clinicName: clinicName,
            clinicAddress: clinicAddress
        )
        switch result {
        case .success(let created):
            return created.cardId
        case .rejected(let error):
            errorMessage = error.message ?? "카드를 만들지 못했어요."
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요."
        }
        return nil
    }

    // MARK: - 받아쓰기

    /// 켜기 전 글을 적어 둔다. 끄면 이것으로 되돌린다.
    func rememberDraftBeforeVoice() {
        draftBeforeVoice = draft
    }

    func restoreDraftBeforeVoice() {
        draft = draftBeforeVoice ?? ""
        draftBeforeVoice = nil
    }

    func previewVoice(_ text: String) {
        draft = text
    }

    func clearError() { errorMessage = nil }

    // MARK: - 안쪽

    private var nextSeq: Int64 { (messages.last?.seq ?? 0) + 1 }

    private func apply(_ response: SessionResponse) {
        sessionId = response.sessionId
        let incoming = IntakeRepository.messages(from: response.messages)
        if !incoming.isEmpty { messages = incoming }
        if let level = response.severity?.level { severity = level }
        rows = IntakeRepository.rows(
            candidates: IntakeRepository.candidates(from: response.questionCandidates),
            existing: rows
        )
    }

    private func apply(_ turn: TurnResponse) {
        let incoming = IntakeRepository.messages(from: turn.messages)
        if !incoming.isEmpty {
            messages = incoming
        } else if let reply = turn.reply, !reply.isEmpty {
            messages.append(IntakeMessage(seq: nextSeq, fromPatient: false, text: reply))
        }

        if turn.ended == true {
            isEnded = true
            rows = IntakeRepository.rows(
                candidates: IntakeRepository.candidates(from: turn.questionCandidates),
                existing: rows
            )
        }
    }
}
