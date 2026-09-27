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

struct LoginResponse: Decodable {
    let token: String

    private enum CodingKeys: String, CodingKey { case token, accessToken, jwt }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        token = try values.decodeIfPresent(String.self, forKey: .token)
            ?? values.decodeIfPresent(String.self, forKey: .accessToken)
            ?? values.decode(String.self, forKey: .jwt)
    }
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

    func login(email: String, password: String) async throws -> String {
        let body = try encoder.encode(LoginRequest(email: email, password: password))
        let response: LoginResponse = try await client.send("/auth/login", method: "POST", body: body, authenticated: false)
        guard !response.token.isEmpty else { throw APIError.invalidResponse }
        return response.token
    }
}
