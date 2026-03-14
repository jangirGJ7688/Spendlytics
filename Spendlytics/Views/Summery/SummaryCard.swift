//
//  SummaryCard.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI

struct SummaryCard: View {
    
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("₹\(amount, specifier: "%.2f")")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
