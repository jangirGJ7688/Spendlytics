//
//  ExpenseRow.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI

struct ExpenseRow: View {
    
    let expense: Expense
    var isDeleting = false
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(expense.name)
                    .font(.headline)
                
                Text(ExpenseCategory.displayName(for: expense.category))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                
                Text("₹\(expense.amount, specifier: "%.2f")")
                    .font(.headline)
                
                Text(expense.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                if isDeleting { ProgressView() }
            }
            .frame(width: 20, height: 20)
            .padding(.leading, 4)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}
