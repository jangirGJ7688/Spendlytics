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
        let tokenStore = KeychainTokenStore()
        let authManager = AuthManager(tokenStore: tokenStore)
        let client = APIClient(tokenStore: tokenStore)
        client.onUnauthorized = { [weak authManager] in
            authManager?.signOut()
        }
        self.authService = AuthService(client: client)
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
            .task {
                authManager.restoreSession()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
