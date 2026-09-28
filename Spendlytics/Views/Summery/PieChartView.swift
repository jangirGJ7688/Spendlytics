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
        let labels = data.map(label)
        let colors = data.indices.map { index in
            index < SpendlyticsStyle.categoryColors.count
                ? SpendlyticsStyle.categoryColors[index]
                : SpendlyticsStyle.accent
        }

        Chart(data) { item in
            
            SectorMark(
                angle: .value("Amount", value(item)),
                innerRadius: .ratio(0.5)
            )
            .foregroundStyle(by: .value("Label", label(item)))
        }
        .chartForegroundStyleScale(domain: labels, range: colors)
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
        .font(PoppinsFont.regular(10))
        .frame(height: 250)
    }
}
