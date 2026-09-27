//
//  AddExpenseView.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//


import SwiftUI

struct AddExpenseView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddExpenseViewModel
    let onSave: (ExpenseDTO) -> Void
    private let isEditing: Bool

    init(expenseService: ExpenseService, expense: Expense? = nil, onSave: @escaping (ExpenseDTO) -> Void) {
        self.onSave = onSave
        self.isEditing = expense != nil
        _viewModel = StateObject(wrappedValue: AddExpenseViewModel(expenseService: expenseService, expense: expense))
    }
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                titleSection
                
                amountSection
                
                categorySection
                
                dateSection
            }
            .navigationTitle(isEditing ? "Edit Expense" : "Add Expense")
            .alert("Unable to Save Expense", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            if let expense = await viewModel.saveExpense() {
                                onSave(expense)
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text(isEditing ? "Update" : "Save")
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
    }
}

extension AddExpenseView {
    
    private var titleSection: some View {
        
        Section("Title") {
            
            TextField("Expense title", text: $viewModel.title)
        }
    }
}

extension AddExpenseView {
    
    private var amountSection: some View {
        
        Section("Amount") {
            
            TextField("Amount", text: $viewModel.amount)
                .keyboardType(.decimalPad)
        }
    }
}

extension AddExpenseView {
    
    private var categorySection: some View {
        
        Section("Category") {
            
            Picker("Category", selection: $viewModel.category) {
                
                ForEach(ExpenseCategory.allCases) { category in
                    Text(category.displayName).tag(category.rawValue)
                }
            }
        }
    }
}

extension AddExpenseView {
    
    private var dateSection: some View {
        
        Section("Date") {
            
            DatePicker(
                "Expense Date",
                selection: $viewModel.date,
                displayedComponents: .date
            )
        }
    }
}
