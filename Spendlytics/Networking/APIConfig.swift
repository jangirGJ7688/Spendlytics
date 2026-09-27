import Foundation

enum APIConfig {
    static let developmentBaseURL = makeURL("http://localhost:8080")
    static let productionBaseURL = makeURL("https://spendlytics-backend.onrender.com")
    static let baseURL = ProcessInfo.processInfo.environment["SPENDLYTICS_API_BASE_URL"]
        .flatMap { URL(string: $0) } ?? productionBaseURL

    private static func makeURL(_ value: String) -> URL {
        guard let url = URL(string: value) else { preconditionFailure("Invalid API base URL") }
        return url
    }
}
