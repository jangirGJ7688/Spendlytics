import Foundation
import Security

@MainActor
protocol TokenStoring {
    func readAccessToken() throws -> String?
    func readRefreshToken() throws -> String?
    func saveTokens(accessToken: String, refreshToken: String) throws
    func deleteTokens() throws
}

@MainActor
final class KeychainTokenStore: TokenStoring {
    private let service = Bundle.main.bundleIdentifier ?? "Spendlytics"
    private let accessAccount = "accessToken"
    private let refreshAccount = "refreshToken"

    func readAccessToken() throws -> String? { try read(account: accessAccount) }
    func readRefreshToken() throws -> String? { try read(account: refreshAccount) }

    func saveTokens(accessToken: String, refreshToken: String) throws {
        try save(accessToken, account: accessAccount)
        try save(refreshToken, account: refreshAccount)
    }

    func deleteTokens() throws {
        try delete(account: accessAccount)
        try delete(account: refreshAccount)
        try delete(account: "jwt")
    }

    private func read(account: String) throws -> String? {
        var query = baseQuery
        query[kSecAttrAccount as String] = account
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw APIError.storage
        }
        return token
    }

    private func save(_ token: String, account: String) throws {
        let data = Data(token.utf8)
        var query = baseQuery
        query[kSecAttrAccount as String] = account
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { throw APIError.storage }
        } else if status != errSecSuccess {
            throw APIError.storage
        }
    }

    private func delete(account: String) throws {
        var query = baseQuery
        query[kSecAttrAccount as String] = account
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw APIError.storage }
    }

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
        ]
    }
}
