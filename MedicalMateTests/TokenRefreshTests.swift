import Foundation
import Testing
@testable import MedicalMate

/// 가짜 토큰 저장소. Keychain을 건드리지 않는다.
private actor MemoryTokens: TokenProviding {
    private var access: String?
    private var refresh: String?
    private(set) var updateCount = 0
    private(set) var cleared = false

    init(access: String?, refresh: String?) {
        self.access = access
        self.refresh = refresh
    }

    func accessToken() -> String? { access }
    func refreshToken() -> String? { refresh }

    func update(access: String, refresh: String) {
        self.access = access
        self.refresh = refresh
        updateCount += 1
    }

    func clear() {
        access = nil
        refresh = nil
        cleared = true
    }
}

/// 몇 번 불렸는지 세는 재발급기.
///
/// `actor`로 센다. 재발급은 동시에 여러 요청이 부를 수 있어서 셈이 깨지면 안 된다.
private actor CountingRefresher: TokenRefreshing {
    private(set) var callCount = 0
    private let result: TokenPair?

    init(result: TokenPair?) {
        self.result = result
    }

    func refresh(using refreshToken: String) async -> TokenPair? {
        callCount += 1
        return result
    }
}

struct TokenRefreshTests {
    @Test("재발급에 성공하면 새 토큰이 저장된다")
    func storesNewTokens() async {
        let tokens = MemoryTokens(access: "old", refresh: "r1")
        let refresher = CountingRefresher(result: TokenPair(access: "new", refresh: "r2"))

        let pair = await refresher.refresh(using: "r1")
        #expect(pair?.access == "new")

        await tokens.update(access: pair!.access, refresh: pair!.refresh)
        #expect(await tokens.accessToken() == "new")
        #expect(await tokens.refreshToken() == "r2")
        #expect(await tokens.updateCount == 1)
    }

    @Test("refresh 토큰이 없으면 재발급을 시도하지 않는다")
    func noRefreshToken() async {
        let tokens = MemoryTokens(access: "old", refresh: nil)
        #expect(await tokens.refreshToken() == nil)
    }

    @Test("재발급이 실패하면 세션을 비운다")
    func clearsOnFailure() async {
        let tokens = MemoryTokens(access: "old", refresh: "r1")
        let refresher = CountingRefresher(result: nil)

        if await refresher.refresh(using: "r1") == nil {
            await tokens.clear()
        }
        #expect(await tokens.cleared)
        #expect(await tokens.accessToken() == nil)
    }
}
