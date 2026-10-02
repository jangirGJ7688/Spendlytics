import Foundation
import OSLog

@MainActor
final class APIClient {
    private let tokenStore: TokenStoring
    private let session: URLSession
    private let logger: Logger
    var onUnauthorized: (() -> Void)?
    private var refreshTask: Task<LoginResponse, Error>?

    init(tokenStore: TokenStoring, session: URLSession = .shared) {
        self.tokenStore = tokenStore
        self.session = session
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Spendlytics", category: "Networking")
        logger.info("API client configured for host \(APIConfig.baseURL.host ?? "unknown", privacy: .public)")
    }

    func send<Response: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Data? = nil,
        authenticated: Bool = true
    ) async throws -> Response {
        let data = try await perform(path, method: method, body: body, authenticated: authenticated)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            logDecodingFailure(error, endpoint: path)
            throw APIError.decoding
        }
    }

    func sendWithoutResponse(
        _ path: String,
        method: String,
        body: Data? = nil,
        authenticated: Bool = true
    ) async throws {
        _ = try await perform(path, method: method, body: body, authenticated: authenticated)
    }

    private func perform(_ path: String, method: String, body: Data?, authenticated: Bool) async throws -> Data {
        try await perform(path, method: method, body: body, authenticated: authenticated, mayRetryAfterRefresh: true)
    }

    private func perform(_ path: String, method: String, body: Data?, authenticated: Bool, mayRetryAfterRefresh: Bool) async throws -> Data {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL)?.absoluteURL else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        var accessTokenUsed: String?
        if authenticated {
            do {
                if let token = try tokenStore.readAccessToken() {
                    accessTokenUsed = token
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
            } catch {
                logger.error("Secure token lookup failed; request aborted for \(path, privacy: .public)")
                throw APIError.map(error)
            }
        }

        let startedAt = Date()
        logger.debug("API request started: \(method, privacy: .public) \(path, privacy: .public)")
        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                logger.error("API returned a non-HTTP response for \(path, privacy: .public)")
                throw APIError.invalidResponse
            }
            let durationMilliseconds = Int(Date().timeIntervalSince(startedAt) * 1_000)
            guard (200..<300).contains(response.statusCode) else {
                logger.error("API request failed: \(method, privacy: .public) \(path, privacy: .public), HTTP \(response.statusCode, privacy: .public), \(durationMilliseconds, privacy: .public) ms")
                if response.statusCode == 401, path == "/auth/login" { throw APIError.invalidCredentials }
                if response.statusCode == 401, authenticated, mayRetryAfterRefresh {
                    do {
                        let currentToken = try tokenStore.readAccessToken()
                        if currentToken == accessTokenUsed {
                            _ = try await refreshAccessToken()
                        }
                    } catch {
                        try? tokenStore.deleteTokens()
                        onUnauthorized?()
                        throw APIError.httpStatus(401)
                    }
                    do {
                        return try await perform(path, method: method, body: body, authenticated: true, mayRetryAfterRefresh: false)
                    } catch {
                        if let apiError = error as? APIError, apiError.isUnauthorized {
                            try? tokenStore.deleteTokens()
                            onUnauthorized?()
                        }
                        throw error
                    }
                }
                throw APIError.httpStatus(response.statusCode)
            }
            logger.info("API request succeeded: \(method, privacy: .public) \(path, privacy: .public), HTTP \(response.statusCode, privacy: .public), \(durationMilliseconds, privacy: .public) ms")
            return data
        } catch let error as URLError {
            logger.error("API transport failure: \(method, privacy: .public) \(path, privacy: .public), \(String(describing: error.code), privacy: .public), code \(error.code.rawValue, privacy: .public)")
            throw APIError.map(error)
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("API request failed unexpectedly: \(method, privacy: .public) \(path, privacy: .public), error type \(String(reflecting: type(of: error)), privacy: .public)")
            throw APIError.map(error)
        }
    }

    func refreshAccessToken() async throws -> LoginResponse {
        if let refreshTask { return try await refreshTask.value }
        let task = Task { try await self.performRefresh() }
        refreshTask = task
        defer { refreshTask = nil }
        do {
            return try await task.value
        } catch {
            try? tokenStore.deleteTokens()
            onUnauthorized?()
            throw error
        }
    }

    private func performRefresh() async throws -> LoginResponse {
        guard let refreshToken = try tokenStore.readRefreshToken(), !refreshToken.isEmpty else {
            throw APIError.httpStatus(401)
        }
        guard let url = URL(string: "/auth/refresh", relativeTo: APIConfig.baseURL)?.absoluteURL else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RefreshTokenRequest(refreshToken: refreshToken))
        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(response.statusCode) else { throw APIError.httpStatus(response.statusCode) }
            let tokens = try JSONDecoder().decode(LoginResponse.self, from: data)
            guard !tokens.accessToken.isEmpty, !tokens.refreshToken.isEmpty else { throw APIError.invalidResponse }
            try tokenStore.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
            return tokens
        } catch {
            throw APIError.map(error)
        }
    }

    private func logDecodingFailure(_ error: Error, endpoint: String) {
        let detail: String
        switch error {
        case let DecodingError.keyNotFound(key, context):
            detail = "missing key \(key.stringValue) at \(codingPath(context.codingPath))"
        case let DecodingError.typeMismatch(type, context):
            detail = "type mismatch at \(codingPath(context.codingPath)); expected \(String(reflecting: type))"
        case let DecodingError.valueNotFound(type, context):
            detail = "missing value at \(codingPath(context.codingPath)); expected \(String(reflecting: type))"
        case let DecodingError.dataCorrupted(context):
            detail = "invalid value at \(codingPath(context.codingPath)): \(context.debugDescription)"
        default:
            detail = String(reflecting: type(of: error))
        }
        logger.error("Response decoding failed for \(endpoint, privacy: .public): \(detail, privacy: .public)")
    }

    private func codingPath(_ keys: [any CodingKey]) -> String {
        let path = keys.reduce(into: "") { result, key in
            if let index = key.intValue {
                result += "[\(index)]"
            } else {
                result += result.isEmpty ? key.stringValue : ".\(key.stringValue)"
            }
        }
        return path.isEmpty ? "<root>" : path
    }
}
