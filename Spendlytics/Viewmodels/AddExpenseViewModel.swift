//
//  AddExpenseViewModel.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class AddExpenseViewModel: ObservableObject {
    
    @Published var title: String = ""
    @Published var amount: String = ""
    @Published var category: String = ExpenseCategory.food.rawValue
    @Published var date: Date = .now
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let expenseService: ExpenseService
    private let existingExpense: Expense?

    init(expenseService: ExpenseService, expense: Expense? = nil) {
        self.expenseService = expenseService
        self.existingExpense = expense
        if let expense {
            title = expense.name
            amount = String(expense.amount)
            category = expense.category
            date = expense.date
        }
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (Double(amount) ?? 0) > 0
    }

    func saveExpense() async -> ExpenseDTO? {
        guard isValid, !isSaving, let amountValue = Double(amount) else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let expense: ExpenseDTO
            if let remoteID = existingExpense?.remoteID {
                expense = try await expenseService.updateExpense(id: remoteID, name: cleanedTitle, category: category, amount: amountValue, date: date)
            } else {
                expense = try await expenseService.createExpense(name: cleanedTitle, category: category, amount: amountValue, date: date)
            }
            errorMessage = nil
            return expense
        } catch {
            errorMessage = APIError.map(error).userMessage
            return nil
        }
    }
}
