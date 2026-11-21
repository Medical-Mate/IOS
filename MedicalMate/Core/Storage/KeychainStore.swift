import Foundation
import Security

/// Keychain에 문자열 하나를 넣고 빼는 자리.
///
/// **서버 JWT는 여기에만 둔다.** `UserDefaults`는 평문 plist라 기기에 접근할 수 있으면
/// 그대로 읽힌다. Android는 DataStore 평문 저장이 미해결 과제로 남아 있는데, iOS는
/// 처음부터 Keychain으로 간다.
///
/// 접근 등급은 `AfterFirstUnlockThisDeviceOnly`다.
/// - `AfterFirstUnlock` — 기기를 한 번 풀면 백그라운드에서도 읽는다. 알림 예약처럼
///   화면이 꺼진 동안 도는 일이 있어서 `WhenUnlocked`로는 모자란다.
/// - `ThisDeviceOnly` — **iCloud 키체인과 기기 간 전송에서 뺀다.** Android의
///   `allowBackup="false"`와 같은 자리다. refresh 토큰 TTL이 30일이라 백업으로 새어
///   나가면 그동안 남의 기기에서 쓸 수 있다.
struct KeychainStore: Sendable {
    let service: String

    init(service: String = "com.mist.medicalmate.tokens") {
        self.service = service
    }

    func string(for key: String) -> String? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 값을 넣는다. 같은 키가 있으면 덮어쓴다. `nil`이면 지운다.
    @discardableResult
    func set(_ value: String?, for key: String) -> Bool {
        guard let value else { return remove(key) }
        guard let data = value.data(using: .utf8) else { return false }

        let query = baseQuery(key)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }

        var insert = query
        insert.merge(attributes) { current, _ in current }
        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    func remove(_ key: String) -> Bool {
        let status = SecItemDelete(baseQuery(key) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
