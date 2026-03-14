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
    
    @Published var filter = ExpenseFilter()
    
    let categories = [
        "Food",
        "Transport",
        "Shopping",
        "Bills",
        "Entertainment",
        "Other"
    ]
    
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
    
    func deleteExpense(_ expense: Expense, context: ModelContext) {
        context.delete(expense)
    }
}
