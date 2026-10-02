import Foundation

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case token
        case refreshToken
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken)
            ?? values.decode(String.self, forKey: .token)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(accessToken, forKey: .accessToken)
        try values.encode(refreshToken, forKey: .refreshToken)
    }
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct LogoutRequest: Encodable {
    let refreshToken: String
}

@MainActor
final class AuthService {
    private let client: APIClient
    private let encoder = JSONEncoder()

    init(client: APIClient) { self.client = client }

    func register(name: String, email: String, password: String) async throws {
        let body = try encoder.encode(RegisterRequest(name: name, email: email, password: password))
        try await client.sendWithoutResponse("/auth/register", method: "POST", body: body, authenticated: false)
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let body = try encoder.encode(LoginRequest(email: email, password: password))
        let response: LoginResponse = try await client.send("/auth/login", method: "POST", body: body, authenticated: false)
        guard !response.accessToken.isEmpty, !response.refreshToken.isEmpty else { throw APIError.invalidResponse }
        return response
    }

    func logout(refreshToken: String) async throws {
        let body = try encoder.encode(LogoutRequest(refreshToken: refreshToken))
        try await client.sendWithoutResponse("/auth/logout", method: "POST", body: body, authenticated: false)
    }

    func deleteAccount() async throws {
        try await client.sendWithoutResponse("/auth/account", method: "DELETE")
    }
}
