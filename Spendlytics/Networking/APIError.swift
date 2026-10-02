import Foundation

enum APIError: Error {
    case httpStatus(Int)
    case invalidCredentials
    case network
    case serviceUnavailable
    case timeout
    case invalidResponse
    case decoding
    case storage

    var isUnauthorized: Bool {
        if case .httpStatus(401) = self { return true }
        return false
    }

    var userMessage: String {
        switch self {
        case .invalidCredentials: return "Email or password is incorrect."
        case .httpStatus(400): return "Please check the information and try again."
        case .httpStatus(401): return "Your session has expired. Please sign in again."
        case .httpStatus(403): return "You don't have permission to do that."
        case .httpStatus(404): return "We couldn't find that information."
        case .httpStatus(409): return "An account with these details already exists."
        case .httpStatus(500...599): return "Something went wrong. Please try again later."
        case .httpStatus: return "The request couldn't be completed. Please try again."
        case .network: return "Unable to connect. Please check your internet connection."
        case .serviceUnavailable: return "Couldn't reach the Spendlytics service. Please try again shortly."
        case .timeout: return "The request took too long. Please try again."
        case .invalidResponse, .decoding: return "We couldn't process the server response. Please try again."
        case .storage: return "Secure sign-in storage is unavailable. Please try again."
        }
    }

    static func map(_ error: Error) -> APIError {
        if let error = error as? APIError { return error }
        if let error = error as? URLError {
            switch error.code {
            case .timedOut:
                return .timeout
            case .cannotFindHost, .dnsLookupFailed, .cannotConnectToHost, .networkConnectionLost,
                 .secureConnectionFailed, .cannotLoadFromNetwork, .serverCertificateHasBadDate,
                 .serverCertificateUntrusted, .serverCertificateHasUnknownRoot,
                 .serverCertificateNotYetValid, .clientCertificateRejected, .clientCertificateRequired:
                return .serviceUnavailable
            case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff, .callIsActive:
                return .network
            default:
                return .serviceUnavailable
            }
        }
        if error is DecodingError { return .decoding }
        return .network
    }
}
