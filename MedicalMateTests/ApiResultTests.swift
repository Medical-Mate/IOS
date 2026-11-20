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
