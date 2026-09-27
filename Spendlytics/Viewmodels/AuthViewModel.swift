import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?

    private let authService: AuthService
    private let authManager: AuthManager

    init(authService: AuthService, authManager: AuthManager) {
        self.authService = authService
        self.authManager = authManager
    }

    func register() async -> Bool {
        guard !isLoading else { return false }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Enter your name."
            return false
        }
        guard isValidEmail else {
            errorMessage = "Enter a valid email address."
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Enter your password."
            return false
        }

        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.register(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            password = ""
            noticeMessage = "Your account is ready. Sign in to continue."
            return true
        } catch {
            errorMessage = APIError.map(error).userMessage
            return false
        }
    }

    func signIn() async {
        guard !isLoading else { return }
        guard isValidEmail else {
            errorMessage = "Enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Enter your password."
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await authService.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            try authManager.storeSession(token: token)
            password = ""
        } catch {
            errorMessage = APIError.map(error).userMessage
        }
    }

    private var isValidEmail: Bool {
        let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.range(of: #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }
}
