import Foundation

/// 서버 JWT를 들고 있는 자리.
///
/// **카카오 토큰은 저장하지 않는다.** 카카오 SDK가 자체 보관하고 서버도 들고 있지 않다.
/// 같은 자격증명을 여러 곳에 두면 로그아웃할 때 지워야 할 곳이 늘어난다.
///
/// `actor`인 이유는 ``ApiClient``(actor)와 여러 화면이 동시에 읽고 쓰기 때문이다.
actor TokenStore: TokenProviding {
    private enum Key {
        static let access = "accessToken"
        static let refresh = "refreshToken"
    }

    private let keychain: KeychainStore
    private var cachedAccess: String?
    private var cachedRefresh: String?

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        self.cachedAccess = keychain.string(for: Key.access)
        self.cachedRefresh = keychain.string(for: Key.refresh)
    }

    func accessToken() -> String? { cachedAccess }
    func refreshToken() -> String? { cachedRefresh }

    var hasSession: Bool { cachedRefresh != nil }

    func update(access: String, refresh: String) {
        cachedAccess = access
        cachedRefresh = refresh
        keychain.set(access, for: Key.access)
        keychain.set(refresh, for: Key.refresh)
    }

    func clear() {
        cachedAccess = nil
        cachedRefresh = nil
        keychain.remove(Key.access)
        keychain.remove(Key.refresh)
    }
}
