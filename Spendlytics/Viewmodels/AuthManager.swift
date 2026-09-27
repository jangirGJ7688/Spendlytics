import Combine
import CryptoKit
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isCheckingSession = true
    private(set) var cacheScope: String?

    private let tokenStore: TokenStoring

    init(tokenStore: TokenStoring) { self.tokenStore = tokenStore }

    func restoreSession() {
        if let token = try? tokenStore.readToken(), !token.isEmpty {
            cacheScope = Self.scope(for: token)
            isAuthenticated = true
        } else {
            cacheScope = nil
            isAuthenticated = false
        }
        isCheckingSession = false
    }

    func storeSession(token: String) throws {
        try tokenStore.saveToken(token)
        cacheScope = Self.scope(for: token)
        isAuthenticated = true
    }

    func signOut() {
        try? tokenStore.deleteToken()
        cacheScope = nil
        isAuthenticated = false
    }

    private static func scope(for token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
