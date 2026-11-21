import Foundation

/// 인증 토큰을 읽고 쓰는 자리.
///
/// `Core`가 `Auth`를 참조하지 않기 위한 경계다. 구현은 `Auth` 쪽에 있고 조립 지점에서
/// 넣는다. 반대로 두면 다른 도메인이 네트워크 계층을 쓸 때마다 `Auth`가 따라온다.
protocol TokenProviding: Actor {
    func accessToken() -> String?
    func refreshToken() -> String?
    func update(access: String, refresh: String)
    func clear()
}

/// 만료된 토큰을 다시 받아오는 자리.
protocol TokenRefreshing: Sendable {
    /// 성공하면 새 토큰 쌍을 돌려준다. 실패하면 `nil`이고 호출자는 세션을 끝낸다.
    func refresh(using refreshToken: String) async -> TokenPair?
}

struct TokenPair: Sendable, Equatable {
    let access: String
    let refresh: String
}

/// 서버와 이야기하는 유일한 자리.
///
/// **401 재발급을 여기서 한다.** 요청이 401을 받으면 refresh 토큰으로 다시 받아 원 요청을
/// **한 번만** 더 보낸다. 두 번 이상 돌지 않는다 — 재발급한 토큰으로도 401이면 토큰 문제가
/// 아니다.
///
/// **재발급은 동시에 하나만 돈다.** 화면 여러 개가 함께 열려 요청이 동시에 401을 받으면
/// 재발급도 그 수만큼 나간다. 서버가 refresh 토큰을 한 번 쓰고 버리는 방식이면 첫 번째만
/// 성공하고 나머지는 세션이 끊긴다. ``refreshTask``가 도는 재발급에 다른 요청을 태운다.
///
/// **재발급 호출은 인증을 붙이지 않는다.** ``TokenRefreshing`` 구현이 `authFree` 요청으로
/// 보낸다. 같은 경로로 보내면 만료된 헤더를 달고 나가고 그 401이 다시 재발급을 부른다.
actor ApiClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokens: any TokenProviding
    private let refresher: any TokenRefreshing
    private let onSessionExpired: @Sendable () async -> Void

    private var refreshTask: Task<TokenPair?, Never>?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(
        baseURL: URL,
        session: URLSession = .shared,
        tokens: any TokenProviding,
        refresher: any TokenRefreshing,
        onSessionExpired: @escaping @Sendable () async -> Void = {}
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokens = tokens
        self.refresher = refresher
        self.onSessionExpired = onSessionExpired
    }

    func send<Response: Decodable & Sendable>(
        _ request: HTTPRequest,
        as type: Response.Type = Response.self
    ) async -> ApiResult<Response> {
        let first = await perform(request, as: Response.self)

        // 인증을 붙이지 않은 요청은 재발급 대상이 아니다. 재발급 호출 자신이 여기 온다.
        guard case .rejected(let error) = first, error.isUnauthorized, !request.authFree else {
            return first
        }

        guard await renewTokens() else {
            await onSessionExpired()
            return first
        }

        return await perform(request, as: Response.self)
    }

    /// 본문을 쓰지 않는 호출.
    func send(_ request: HTTPRequest) async -> ApiResult<Void> {
        await send(request, as: EmptyResponse.self).map { _ in () }
    }

    // MARK: - 내부

    private func renewTokens() async -> Bool {
        if let running = refreshTask {
            return await running.value != nil
        }

        guard let refreshToken = await tokens.refreshToken() else { return false }

        let task = Task<TokenPair?, Never> { [refresher] in
            await refresher.refresh(using: refreshToken)
        }
        refreshTask = task
        let pair = await task.value
        refreshTask = nil

        guard let pair else {
            await tokens.clear()
            return false
        }
        await tokens.update(access: pair.access, refresh: pair.refresh)
        return true
    }

    private func perform<Response: Decodable & Sendable>(
        _ request: HTTPRequest,
        as type: Response.Type
    ) async -> ApiResult<Response> {
        guard let urlRequest = await makeURLRequest(request) else {
            return .rejected(ApiError(statusCode: -1, message: "요청을 만들 수 없습니다"))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            // 보내지 못한 것만 여기 온다. 서버가 답했으면 아래로 간다.
            return .networkUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            return .rejected(ApiError(statusCode: -1, message: nil))
        }

        guard (200..<300).contains(http.statusCode) else {
            return .rejected(ApiClient.error(statusCode: http.statusCode, body: data, decoder: decoder))
        }

        // 본문이 없거나 쓰지 않는 응답. 빈 바디를 디코딩하려다 실패하지 않게 막는다.
        if let empty = EmptyResponse() as? Response {
            return .success(empty)
        }

        // **직렬화 실패는 잡지 않는다.** 서버와 클라이언트의 계약이 어긋난 것을
        // "다시 시도해주세요"로 감추면 원인을 찾을 수 없게 된다. 개발 중에 바로 터뜨리되,
        // 어느 타입이 어긋났는지 남긴다.
        do {
            return .success(try decoder.decode(Response.self, from: data))
        } catch {
            fatalError("\(Response.self) 응답을 읽지 못했다. 서버 계약이 바뀌었는지 본다: \(error)")
        }
    }

    private func makeURLRequest(_ request: HTTPRequest) async -> URLRequest? {
        guard var components = URLComponents(
            url: baseURL.appending(path: request.path),
            resolvingAgainstBaseURL: false
        ) else { return nil }

        if !request.query.isEmpty {
            components.queryItems = request.query
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { return nil }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = request.body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try? encoder.encode(body)
        }

        if !request.authFree, let token = await tokens.accessToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }

    /// 서버의 공통 에러 봉투를 푼다.
    ///
    /// **전에는 맨 위의 `message`를 찾았는데 그 자리에는 없다.** 그래서 서버가 준 말이
    /// 한 번도 화면에 닿지 않았고, 모든 화면이 제 기본 문구로 받치고 있었다.
    nonisolated static func error(statusCode: Int, body: Data, decoder: JSONDecoder) -> ApiError {
        guard let envelope = try? decoder.decode(ApiErrorEnvelope.self, from: body),
              let error = envelope.error
        else {
            return ApiError(statusCode: statusCode, message: nil)
        }
        return ApiError(
            statusCode: statusCode,
            message: error.message,
            code: error.code,
            isRetryable: error.retryable ?? false,
            details: error.details ?? [:]
        )
    }
}

/// 백엔드의 공통 에러 봉투.
///
/// 스키마 목록에 없고 실제 응답으로 확인한 형태다.
///
/// ```json
/// {"error":{"code":"UNAUTHORIZED","message":"...","retryable":false},
///  "meta":{"requestId":"req_61c3205bdfee"}}
/// ```
private struct ApiErrorEnvelope: Decodable {
    struct Body: Decodable {
        let code: String?
        let message: String?
        let retryable: Bool?
        let details: [String: ApiErrorDetail]?
    }

    let error: Body?
}
