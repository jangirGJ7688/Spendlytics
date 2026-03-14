//
//  PieChartView.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI
import Charts

struct PieChartView<T: Identifiable>: View {
    
    let data: [T]
    let value: (T) -> Double
    let label: (T) -> String
    
    var body: some View {
        
        Chart(data) { item in
            
            SectorMark(
                angle: .value("Amount", value(item)),
                innerRadius: .ratio(0.5)
            )
            .foregroundStyle(by: .value("Label", label(item)))
        }
        .frame(height: 250)
    }
}
