import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// 서버에 보낼 요청 하나.
///
/// 경로는 `api/auth/kakao`처럼 **앞 슬래시 없이** 적는다. base URL에 이어 붙일 때
/// 슬래시가 겹치거나 경로가 통째로 날아가는 것을 막는다.
struct HTTPRequest: Sendable {
    let method: HTTPMethod
    let path: String
    var query: [String: String] = [:]
    var body: (any Encodable & Sendable)?
    /// 인증 헤더를 붙이지 않는다. 토큰 재발급처럼 인증이 필요 없는 호출이 쓴다.
    var authFree: Bool = false

    static func get(_ path: String, query: [String: String] = [:]) -> HTTPRequest {
        HTTPRequest(method: .get, path: path, query: query)
    }

    static func post(_ path: String, body: (any Encodable & Sendable)? = nil) -> HTTPRequest {
        HTTPRequest(method: .post, path: path, body: body)
    }

    static func put(_ path: String, body: (any Encodable & Sendable)? = nil) -> HTTPRequest {
        HTTPRequest(method: .put, path: path, body: body)
    }

    static func patch(_ path: String, body: (any Encodable & Sendable)? = nil) -> HTTPRequest {
        HTTPRequest(method: .patch, path: path, body: body)
    }

    static func delete(_ path: String) -> HTTPRequest {
        HTTPRequest(method: .delete, path: path)
    }
}

/// 본문이 없는 응답을 받을 때 쓰는 빈 타입.
struct EmptyResponse: Decodable, Sendable {}
