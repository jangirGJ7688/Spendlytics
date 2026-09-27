import SwiftUI

struct AuthEntryView: View {
    @State private var showingRegistration = false
    @StateObject private var viewModel: AuthViewModel

    init(authService: AuthService, authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService, authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            Group {
                if showingRegistration {
                    registerForm
                } else {
                    signInForm
                }
            }
            .navigationTitle(showingRegistration ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var signInForm: some View {
        Form {
            Section {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
            }

            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            if let notice = viewModel.noticeMessage {
                Text(notice).foregroundStyle(.secondary)
            }

            Section {
                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading { ProgressView() }
                        Text("Sign In").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading)

                Button("Forgot Password?") {
                    viewModel.noticeMessage = "Password reset is not available yet."
                }
                .disabled(viewModel.isLoading)
            }

            Section {
                Button("Create an account") {
                    viewModel.errorMessage = nil
                    viewModel.noticeMessage = nil
                    showingRegistration = true
                }
            }
        }
    }

    private var registerForm: some View {
        Form {
            Section {
                TextField("Name", text: $viewModel.name)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.newPassword)
            }

            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red)
            }

            Section {
                Button {
                    Task {
                        if await viewModel.register() {
                            showingRegistration = false
                            viewModel.noticeMessage = "Your account is ready. Sign in to continue."
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading { ProgressView() }
                        Text("Register").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading)

                Button("Back to Sign In") {
                    viewModel.errorMessage = nil
                    showingRegistration = false
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}
