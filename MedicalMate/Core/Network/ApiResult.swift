import Foundation

/// API 호출의 결과.
///
/// **API 실패는 예외가 아니라 값이다.** 호출자가 `do/catch`로 받으면 무엇이 날아올지
/// 모르는 채 모든 오류를 한 덩어리로 다루게 되고, 네트워크 끊김과 서버 거절이 같은
/// 메시지로 뭉개진다. 그래서 세 갈래를 타입으로 드러낸다.
///
/// Android `core/network/ApiResult`와 같은 모양이다.
enum ApiResult<Value: Sendable>: Sendable {
    /// 2xx. 본문이 없는 응답은 `Void`다.
    case success(Value)
    /// 서버가 받아들이지 않았다. 상태 코드와 서버가 준 메시지를 들고 있다.
    case rejected(ApiError)
    /// 보내지 못했다. 비행기 모드 · 신호 없음 · 타임아웃.
    case networkUnavailable

    var value: Value? {
        if case .success(let value) = self { return value }
        return nil
    }

    func map<T: Sendable>(_ transform: (Value) -> T) -> ApiResult<T> {
        switch self {
        case .success(let value): .success(transform(value))
        case .rejected(let error): .rejected(error)
        case .networkUnavailable: .networkUnavailable
        }
    }
}

/// 서버가 거절한 내용.
///
/// 봉투는 `{"error":{"code","message","retryable","details"},"meta":{"requestId"}}`이다.
/// 스키마 목록에 없고 실제 응답으로 확인한 형태다 — Android의 `ApiErrorEnvelope`와 같다.
struct ApiError: Error, Sendable, Equatable {
    let statusCode: Int
    /// 서버가 준 메시지. 없을 수 있다. **화면에 그대로 내보내기 전에 민감정보가 없는지 본다.**
    let message: String?
    /// 서버가 정한 코드. `CARD_ALREADY_EDITED` 같은 것이다.
    let code: String?
    /// 다시 해 볼 여지가 있는지. 서버가 말해 준다.
    let isRetryable: Bool
    /// **오류마다 다른 값이 오는 자리다.** 도메인 필드를 봉투에 박으면 오류가 늘 때마다
    /// 봉투가 늘고 파싱이 갈린다.
    let details: [String: ApiErrorDetail]

    init(
        statusCode: Int,
        message: String?,
        code: String? = nil,
        isRetryable: Bool = false,
        details: [String: ApiErrorDetail] = [:]
    ) {
        self.statusCode = statusCode
        self.message = message
        self.code = code
        self.isRetryable = isRetryable
        self.details = details
    }

    var isUnauthorized: Bool { statusCode == 401 }
}

/// `details`에 담겨 오는 값 하나. 서버가 숫자 · 글 · 참거짓을 섞어 보낸다.
enum ApiErrorDetail: Sendable, Equatable, Decodable {
    case int(Int64)
    case text(String)
    case flag(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int64.self) {
            self = .int(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .flag(value)
        } else {
            self = .text(try container.decode(String.self))
        }
    }

    var intValue: Int64? {
        if case .int(let value) = self { return value }
        return nil
    }
}
