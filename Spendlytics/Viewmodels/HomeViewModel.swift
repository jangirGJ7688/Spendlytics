//
//  HomeViewModel.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currentPage = 0
    @Published private(set) var hasMorePages = false
    @Published private(set) var lastLoadedRemoteID: Int64?
    @Published private(set) var deletingExpenseID: UUID?

    private let expenseService: ExpenseService

    init(expenseService: ExpenseService) {
        self.expenseService = expenseService
    }

    @Published var filter = ExpenseFilter()
    
    var categories: [String] { ExpenseCategory.allCases.map(\.rawValue) }
    
    var hasActiveFilters: Bool {
        
        !filter.searchText.isEmpty ||
        filter.selectedCategory != nil ||
        filter.startDate != nil ||
        filter.endDate != nil ||
        filter.minPrice != nil ||
        filter.maxPrice != nil
    }
    
    func filteredExpenses(from expenses: [Expense]) -> [Expense] {
        
        expenses.filter { expense in
            
            // Search
            if !filter.searchText.isEmpty {
                if !expense.name.localizedCaseInsensitiveContains(filter.searchText) {
                    return false
                }
            }
            
            // Category
            if let category = filter.selectedCategory {
                if expense.category != category {
                    return false
                }
            }
            
            // Date range
            if let start = filter.startDate {
                if expense.date < start { return false }
            }
            
            if let end = filter.endDate {
                if expense.date > end { return false }
            }
            
            // Price range
            if let min = filter.minPrice {
                if expense.amount < min { return false }
            }
            
            if let max = filter.maxPrice {
                if expense.amount > max { return false }
            }
            
            return true
        }
    }
    
    func clearFilters() {
        filter = ExpenseFilter()
    }
    
    func totalExpense(from expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func todayExpense(from expenses: [Expense]) -> Double {
        let today = Calendar.current.startOfDay(for: .now)
        
        return expenses
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }
    }
    
    func loadExpenses(context: ModelContext, page: Int = 0, ownerScope: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await expenseService.fetchExpenses(page: page, size: 10)
            let stored = try context.fetch(FetchDescriptor<Expense>())
            for item in response.content {
                if let existing = stored.first(where: { $0.remoteID == item.id && $0.ownerScope == ownerScope }) {
                    existing.name = item.name
                    existing.category = item.category
                    existing.amount = item.amount
                    existing.date = item.date
                } else {
                    context.insert(Expense(remoteID: item.id, ownerScope: ownerScope, name: item.name, category: item.category, date: item.date, value: item.amount))
                }
            }
            currentPage = response.page
            hasMorePages = !response.last
            lastLoadedRemoteID = response.content.last?.id
            errorMessage = nil
        } catch {
            errorMessage = APIError.map(error).userMessage
        }
    }

    func loadNextPage(context: ModelContext, ownerScope: String) async {
        guard hasMorePages else { return }
        await loadExpenses(context: context, page: currentPage + 1, ownerScope: ownerScope)
    }

    func shouldLoadNextPage(for expense: Expense) -> Bool {
        guard let remoteID = expense.remoteID else { return false }
        return hasMorePages && remoteID == lastLoadedRemoteID
    }

    func deleteExpense(_ expense: Expense, context: ModelContext) async {
        guard !isLoading else { return }
        isLoading = true
        deletingExpenseID = expense.id
        defer { isLoading = false }
        defer { deletingExpenseID = nil }
        do {
            if let remoteID = expense.remoteID {
                try await expenseService.deleteExpense(id: remoteID)
            }
            context.delete(expense)
            errorMessage = nil
        } catch {
            errorMessage = APIError.map(error).userMessage
        }
    }
}
