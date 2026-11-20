import Foundation

/// 증상 정리 세션을 열고 이어 가는 자리.
///
/// **세션 생명주기**(FEATURE-SPEC 2.3):
/// 1. 세션은 **강도를 고르고 "다음"을 누를 때 연다.** 부위 + 강도를 함께 보낸다.
/// 2. 강도로 돌아가 다시 고르면 세션을 새로 열지 않고 `severity`만 고친다.
/// 3. **부위를 바꿔 다시 오면 그 세션은 버리고 새로 연다.**
struct IntakeRepository: Sendable {
    let client: ApiClient

    func start(site: IntakeSite, severity: Int) async -> ApiResult<SessionResponse> {
        let body = StartSessionRequest(
            siteNodeId: site.nodeId,
            side: site.side,
            siteText: site.text,
            profile: nil,
            severity: Self.severityRequest(level: severity)
        )
        return await client.send(.post("api/sessions", body: body), as: SessionResponse.self)
    }

    func session(id: Int64) async -> ApiResult<SessionResponse> {
        await client.send(.get("api/sessions/\(id)"), as: SessionResponse.self)
    }

    func send(sessionId: Int64, text: String, by method: IntakeInputMethod) async -> ApiResult<TurnResponse> {
        let body = SendMessageRequest(text: text, inputMethod: method.rawValue)
        return await client.send(.post("api/sessions/\(sessionId)/messages", body: body), as: TurnResponse.self)
    }

    /// 문답을 연 뒤 강도 단계로 돌아가 다시 골랐을 때만 쓴다. 처음 값은 세션을 여는
    /// 요청에 함께 간다. **이미 받은 질문 후보를 서버가 다시 만들지 않는다.**
    func updateSeverity(sessionId: Int64, level: Int) async -> ApiResult<SessionResponse> {
        let body = Self.severityRequest(level: level)
        return await client.send(.put("api/sessions/\(sessionId)/severity", body: body), as: SessionResponse.self)
    }

    func confirmQuestions(sessionId: Int64, questions: [String]) async -> ApiResult<SessionResponse> {
        let body = QuestionsRequest(questions: questions)
        return await client.send(.put("api/sessions/\(sessionId)/questions", body: body), as: SessionResponse.self)
    }

    /// 문답을 브리핑 카드로 굳힌다.
    ///
    /// 경로가 `api/sessions/...`라 여기 둔다. 카드 본문은 카드 화면이 따로 읽는다 —
    /// 이쪽은 어디로 갈지만 알면 된다.
    func createCard(
        sessionId: Int64,
        clinicName: String?,
        clinicAddress: String?
    ) async -> ApiResult<CardCreatedResponse> {
        let clinic = clinicName.map { ClinicRequest(name: $0, address: clinicAddress) }
        let body = GenerateCardRequest(clinic: clinic)
        return await client.send(.post("api/sessions/\(sessionId)/card", body: body), as: CardCreatedResponse.self)
    }

    func discard(sessionId: Int64) async -> ApiResult<Void> {
        await client.send(.delete("api/sessions/\(sessionId)"))
    }

    /// 강도 요청 한 벌. 낱말은 디자인 카피라 앱이 들고 보낸다.
    static func severityRequest(level: Int) -> SeverityRequest {
        SeverityRequest(level: level, label: MMSeverityLevel.of(level).title)
    }

    // MARK: - 화면이 쓰는 규칙

    /// 서버가 보낸 대화를 화면이 쓰는 모양으로. `role`은 `AI` 또는 `USER`다.
    static func messages(from responses: [MessageResponse]?) -> [IntakeMessage] {
        (responses ?? [])
            .sorted { $0.seq < $1.seq }
            .map { IntakeMessage(seq: $0.seq, fromPatient: $0.role.uppercased() == "USER", text: $0.text) }
    }

    /// 후보를 `rank` 순으로. **서버가 정렬해 주지만 순서를 믿지 않는다.**
    static func candidates(from responses: [QuestionCandidateResponse]?) -> [String] {
        (responses ?? [])
            .enumerated()
            .sorted { ($0.element.rank ?? $0.offset, $0.offset) < ($1.element.rank ?? $1.offset, $1.offset) }
            .map(\.element.text)
    }

    /// 서버 후보를 화면 줄로 바꾼다.
    ///
    /// **환자가 한 번이라도 손댔으면 덮지 않는다.** 덮으면 지운 질문이 되살아나고 직접
    /// 적은 줄이 사라진다(FEATURE-SPEC 2.3).
    static func rows(candidates: [String], existing: [IntakeQuestionRow]) -> [IntakeQuestionRow] {
        guard existing.isEmpty else { return existing }
        return candidates.map { IntakeQuestionRow(text: $0) }
    }

    /// 체크한 줄만 **화면 순서대로**.
    static func selected(in rows: [IntakeQuestionRow]) -> [String] {
        rows.filter(\.isSelected).map(\.text)
    }

    /// 빈 칸("질문 직접 추가")을 보일지.
    ///
    /// **다섯 개가 차면 사라진다**(FEATURE-SPEC 2.3).
    static func showsBlankRow(_ rows: [IntakeQuestionRow]) -> Bool {
        selected(in: rows).count < BriefCardQuestions.max
    }

    /// 줄 아래 서는 AI 말(1c-D1 · 1c-D4). 고른 것이 없으면 서지 않는다.
    ///
    /// 둘째 줄이 1c-D1과 1c-D4에서 다른데 **무엇이 그것을 가르는지 마스터가 말하지
    /// 않는다.** 두 화면의 차이는 직접 적은 질문의 유무뿐이라 그것으로 갈랐다.
    /// 디자인 트랙 확인 대기 — COMPONENT-MAP 3장 11번.
    static func summary(rows: [IntakeQuestionRow]) -> String? {
        let picked = rows.filter(\.isSelected)
        guard !picked.isEmpty else { return nil }
        let tail = picked.contains(where: \.isOwn)
            ? "진료실에서 순서대로 물어보세요."
            : "더 묻고 싶은 게 있으면 빈 칸에 적어주세요."
        return "질문 \(picked.count)개를 카드에 담을게요.\n\(tail)"
    }
}
