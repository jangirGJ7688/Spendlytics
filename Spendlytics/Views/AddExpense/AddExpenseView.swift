//
//  AddExpenseView.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//


import SwiftUI
import SwiftData

struct AddExpenseView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @StateObject private var viewModel = AddExpenseViewModel()
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                titleSection
                
                amountSection
                
                categorySection
                
                dateSection
            }
            .navigationTitle("Add Expense")
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.saveExpense(context: context)
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
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
                
                ForEach(viewModel.categories, id: \.self) { category in
                    Text(category)
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
