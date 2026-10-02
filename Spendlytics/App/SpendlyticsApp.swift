//
//  SpendlyticsApp.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI
import SwiftData

@main
struct SpendlyticsApp: App {
    private let authService: AuthService
    private let expenseService: ExpenseService
    @StateObject private var authManager: AuthManager

    init() {
        PoppinsRegistration.registerBundledFonts()
        let tokenStore = KeychainTokenStore()
        let client = APIClient(tokenStore: tokenStore)
        let authService = AuthService(client: client)
        let authManager = AuthManager(tokenStore: tokenStore, client: client, authService: authService)
        client.onUnauthorized = { [weak authManager] in
            authManager?.signOut()
        }
        self.authService = authService
        self.expenseService = ExpenseService(client: client)
        _authManager = StateObject(wrappedValue: authManager)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isCheckingSession {
                    ProgressView()
                } else if authManager.isAuthenticated {
                    HomeView(expenseService: expenseService, authManager: authManager)
                } else {
                    AuthEntryView(authService: authService, authManager: authManager)
                }
            }
            .font(PoppinsFont.regular(15))
            .tint(SpendlyticsStyle.accent)
            .preferredColorScheme(.light)
            .task {
                await authManager.restoreSession()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
