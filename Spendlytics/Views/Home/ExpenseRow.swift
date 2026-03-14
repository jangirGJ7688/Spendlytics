//
//  ExpenseRow.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI

struct ExpenseRow: View {
    
    let expense: Expense
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(expense.name)
                    .font(.headline)
                
                Text(expense.category)
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
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}
