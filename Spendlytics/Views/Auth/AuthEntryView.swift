import SwiftUI
import UIKit

struct AuthEntryView: View {
    @State private var showingRegistration = false
    @StateObject private var viewModel: AuthViewModel

    init(authService: AuthService, authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService, authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpendlyticsStyle.canvas.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        brandHeader
                        modePicker
                        if showingRegistration { registerForm } else { signInForm }
                    }
                    .padding(.horizontal, 24).padding(.top, 30).padding(.bottom, 32)
                    .frame(maxWidth: 520).frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 9) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 38, height: 38).background(SpendlyticsStyle.accent, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                Text("spendlytics").font(PoppinsFont.bold(20)).foregroundStyle(SpendlyticsStyle.ink)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(showingRegistration ? "A clearer view\nstarts here." : "Make every\nrupee count.")
                    .font(PoppinsFont.bold(34)).lineSpacing(-3).foregroundStyle(SpendlyticsStyle.ink)
                Text(showingRegistration ? "Create your account and build better money habits." : "Your spending, thoughtfully organized.")
                    .font(PoppinsFont.regular(13)).foregroundStyle(SpendlyticsStyle.muted)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingRegistration)
    }

    private var modePicker: some View {
        HStack(spacing: 5) {
            modeButton("Sign in", selected: !showingRegistration) { showingRegistration = false }
            modeButton("Create account", selected: showingRegistration) { showingRegistration = true }
        }
        .padding(5).background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
    }

    private func modeButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(PoppinsFont.medium(12))
                .foregroundStyle(selected ? .white : SpendlyticsStyle.muted)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(selected ? SpendlyticsStyle.ink : .clear, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain).disabled(viewModel.isLoading)
    }

    private var signInForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 11) {
                if showingRegistration { inputField("Name", icon: "person", text: $viewModel.name, contentType: .name, capitalization: .words) }
                inputField("Email address", icon: "envelope", text: $viewModel.email, contentType: .emailAddress, capitalization: .never, keyboard: .emailAddress)
                passwordField("Password", icon: "lock", text: $viewModel.password, contentType: showingRegistration ? .newPassword : .password)
            }

            if let error = viewModel.errorMessage { messageBanner(error, color: .red) }
            if let notice = viewModel.noticeMessage { messageBanner(notice, color: SpendlyticsStyle.muted) }

            if !showingRegistration {
                Button("Forgot password?") {
                    viewModel.noticeMessage = "Password reset is not available yet."
                }
                .font(PoppinsFont.medium(11)).foregroundStyle(SpendlyticsStyle.accent)
                .frame(maxWidth: .infinity, alignment: .trailing).disabled(viewModel.isLoading)
            }

            Button {
                Task {
                    if showingRegistration {
                        if await viewModel.register() {
                            withAnimation(.easeInOut(duration: 0.2)) { showingRegistration = false }
                            viewModel.noticeMessage = "Your account is ready. Sign in to continue."
                        }
                    } else { await viewModel.signIn() }
                }
            } label: {
                HStack(spacing: 9) {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(showingRegistration ? "Create account" : "Sign in")
                    Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(PrimaryActionStyle())
            .disabled(viewModel.isLoading)

            HStack(spacing: 5) {
                Text(showingRegistration ? "Already have an account?" : "New to Spendlytics?")
                    .foregroundStyle(SpendlyticsStyle.muted)
                Button(showingRegistration ? "Sign in" : "Create one") {
                    viewModel.errorMessage = nil
                    viewModel.noticeMessage = nil
                    withAnimation(.easeInOut(duration: 0.2)) { showingRegistration.toggle() }
                }
                .foregroundStyle(SpendlyticsStyle.accent)
            }
            .font(PoppinsFont.medium(11)).frame(maxWidth: .infinity).padding(.top, 2)
            .disabled(viewModel.isLoading)
        }
    }

    private var registerForm: some View { signInForm }

    private func inputField(_ title: String, icon: String, text: Binding<String>, contentType: UITextContentType?, capitalization: TextInputAutocapitalization, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon).font(.system(size: 15)).foregroundStyle(SpendlyticsStyle.muted).frame(width: 20)
            TextField(title, text: text).font(PoppinsFont.regular(13))
                .textContentType(contentType).textInputAutocapitalization(capitalization)
                .keyboardType(keyboard).autocorrectionDisabled()
        }
        .padding(.horizontal, 15).frame(height: 54)
        .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
    }

    private func passwordField(_ title: String, icon: String, text: Binding<String>, contentType: UITextContentType?) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon).font(.system(size: 15)).foregroundStyle(SpendlyticsStyle.muted).frame(width: 20)
            SecureField(title, text: text).font(PoppinsFont.regular(13)).textContentType(contentType)
        }
        .padding(.horizontal, 15).frame(height: 54)
        .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
    }

    private func messageBanner(_ message: String, color: Color) -> some View {
        Text(message).font(PoppinsFont.regular(11)).foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
