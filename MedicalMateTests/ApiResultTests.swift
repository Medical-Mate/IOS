import Foundation
import Testing
@testable import MedicalMate

struct ApiResultTests {
    @Test("성공만 값을 들고 있다")
    func value() {
        #expect(ApiResult.success(7).value == 7)
        #expect(ApiResult<Int>.networkUnavailable.value == nil)
        #expect(ApiResult<Int>.rejected(ApiError(statusCode: 400, message: nil)).value == nil)
    }

    @Test("map은 실패 갈래를 그대로 지나보낸다")
    func mapKeepsFailure() {
        let rejected = ApiResult<Int>.rejected(ApiError(statusCode: 409, message: "중복"))
        guard case .rejected(let error) = rejected.map(String.init) else {
            Issue.record("거절이 다른 갈래로 바뀌었다")
            return
        }
        #expect(error.statusCode == 409)
        #expect(error.message == "중복")
    }

    @Test("401만 재발급 대상이다")
    func unauthorized() {
        #expect(ApiError(statusCode: 401, message: nil).isUnauthorized)
        #expect(!ApiError(statusCode: 403, message: nil).isUnauthorized)
    }
}

/// 서버의 공통 에러 봉투. `{"error":{...},"meta":{...}}`다.
struct ApiErrorEnvelopeTests {
    private func error(_ json: String, statusCode: Int = 409) -> ApiError {
        ApiClient.error(statusCode: statusCode, body: Data(json.utf8), decoder: JSONDecoder())
    }

    @Test func 봉투_안의_말이_화면까지_온다() {
        // **전에는 맨 위의 `message`를 찾았다.** 그 자리에는 없어서 서버가 준 말이 한 번도
        // 닿지 않았고 모든 화면이 제 기본 문구로 받치고 있었다.
        let parsed = error(#"{"error":{"code":"INVALID_REQUEST","message":"날짜를 확인해주세요"}}"#)
        #expect(parsed.message == "날짜를 확인해주세요")
        #expect(parsed.code == "INVALID_REQUEST")
        #expect(parsed.isRetryable == false)
    }

    @Test func 다시_해_볼_여지가_있는지는_서버가_말한다() {
        #expect(error(#"{"error":{"code":"UPSTREAM","retryable":true}}"#).isRetryable)
    }

    @Test func 봉투가_아니면_말을_지어내지_않는다() {
        #expect(error("not json").message == nil)
        #expect(error(#"{"message":"맨 위에 있는 말"}"#).message == nil)
    }

    @Test func 이미_고친_카드는_갈아탈_카드를_알려준다() {
        let parsed = error(#"{"error":{"code":"CARD_ALREADY_EDITED","details":{"latestCardId":20}}}"#)
        #expect(CardRepository.latestCardId(parsed) == 20)
    }

    @Test func 다른_이유로_거절되면_갈아타지_않는다() {
        #expect(CardRepository.latestCardId(error(#"{"error":{"code":"NOT_FOUND"}}"#)) == nil)
        // 코드는 맞는데 갈아탈 카드를 안 알려주면 다시 보내지 않는다.
        #expect(CardRepository.latestCardId(error(#"{"error":{"code":"CARD_ALREADY_EDITED"}}"#)) == nil)
    }
}

/// 로그인이 어디서 막혔는지에 따라 다른 말을 한다.
struct LoginFailureTests {
    private func error(_ code: String?) -> ApiError {
        ApiError(statusCode: 500, message: nil, code: code)
    }

    @Test func 서버가_상위_서비스에_닿지_못한_것은_연결_갈래다() {
        // 앱 잘못이 아니고 할 일이 "잠시 뒤 다시"라 서버 거절과 다른 말을 해야 한다.
        #expect(LoginFailure.of(error("UPSTREAM_ERROR")) == .network)
        #expect(LoginFailure.of(error("UPSTREAM_TIMEOUT")) == .network)
    }

    @Test func 그_밖의_거절은_서버_갈래다() {
        #expect(LoginFailure.of(error("UNAUTHORIZED")) == .server)
        #expect(LoginFailure.of(error(nil)) == .server)
    }

    @Test func 갈래마다_다른_안내를_적는다() {
        #expect(LoginFailure.kakao.message == "카카오 로그인에 실패했어요. 다시 시도해주세요")
        #expect(LoginFailure.network.message == "인터넷 연결을 확인해주세요")
        #expect(LoginFailure.server.message == "로그인에 실패했어요. 잠시 후 다시 시도해주세요")
    }
}
