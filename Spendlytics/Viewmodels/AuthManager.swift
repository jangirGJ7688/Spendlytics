import Combine
import CryptoKit
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isCheckingSession = true
    private(set) var cacheScope: String?

    private let tokenStore: TokenStoring
    private let client: APIClient
    private let authService: AuthService

    init(tokenStore: TokenStoring, client: APIClient, authService: AuthService) {
        self.tokenStore = tokenStore
        self.client = client
        self.authService = authService
    }

    func restoreSession() async {
        defer { isCheckingSession = false }
        do {
            guard let refreshToken = try tokenStore.readRefreshToken(), !refreshToken.isEmpty else {
                signOut()
                return
            }
            guard let accessToken = try tokenStore.readAccessToken(), !accessToken.isEmpty else {
                let tokens = try await client.refreshAccessToken()
                activateSession(accessToken: tokens.accessToken)
                return
            }
            if Self.isExpired(accessToken) {
                let tokens = try await client.refreshAccessToken()
                activateSession(accessToken: tokens.accessToken)
            } else {
                activateSession(accessToken: accessToken)
            }
        } catch {
            signOut()
        }
    }

    func storeSession(tokens: LoginResponse) throws {
        try tokenStore.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        activateSession(accessToken: tokens.accessToken)
    }

    func logout() async {
        if let refreshToken = try? tokenStore.readRefreshToken(), !refreshToken.isEmpty {
            try? await authService.logout(refreshToken: refreshToken)
        }
        signOut()
    }

    func deleteAccount() async throws {
        try await authService.deleteAccount()
        signOut()
    }

    func signOut() {
        try? tokenStore.deleteTokens()
        cacheScope = nil
        isAuthenticated = false
    }

    private func activateSession(accessToken: String) {
        cacheScope = Self.scope(for: accessToken)
        isAuthenticated = true
    }

    private static func isExpired(_ token: String) -> Bool {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return true }
        var payload = String(segments[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let expiration = claims["exp"] as? TimeInterval else { return true }
        return Date(timeIntervalSince1970: expiration) <= Date()
    }

    private static func scope(for token: String) -> String {
        let tokenValue: String
        let segments = token.split(separator: ".")
        if segments.count == 3 {
            var payload = String(segments[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
            if let data = Data(base64Encoded: payload),
               let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let subject = claims["sub"] as? String {
                tokenValue = subject
            } else {
                tokenValue = token
            }
        } else {
            tokenValue = token
        }
        return SHA256.hash(data: Data(tokenValue.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
