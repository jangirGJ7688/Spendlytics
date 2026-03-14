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
    @Published var category: String = "Food"
    @Published var date: Date = .now
    
    let categories = [
        "Food",
        "Transport",
        "Shopping",
        "Bills",
        "Entertainment",
        "Other"
    ]
    
    var isValid: Bool {
        !title.isEmpty && Double(amount) != nil
    }
    
    func saveExpense(context: ModelContext) {
        guard let amountValue = Double(amount) else { return }
        
        let expense = Expense(name: title, category: category, date: date, value: amountValue)
        
        context.insert(expense)
    }
}
