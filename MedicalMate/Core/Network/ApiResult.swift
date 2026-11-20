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
struct ApiError: Error, Sendable, Equatable {
    let statusCode: Int
    /// 서버가 준 메시지. 없을 수 있다. **화면에 그대로 내보내기 전에 민감정보가 없는지 본다.**
    let message: String?

    var isUnauthorized: Bool { statusCode == 401 }
}
