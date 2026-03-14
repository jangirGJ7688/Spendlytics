//
//  SummaryView.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//


import SwiftUI
import Charts

struct SummaryView: View {
    
    let expenses: [Expense]
    
    @StateObject private var viewModel = SummaryViewModel()
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 24) {
                
                totalSection
                
                if viewModel.insights.count > 0 {
                    insightsSection
                }
                
                pieChartSection
                
                lastThreeMonthsSection
                
                lastFourWeeksSection
            }
            .padding()
        }
        .navigationTitle("Summary")
        .task {
            await viewModel.fetchAIInsights(expenses: expenses)
        }
    }
}

extension SummaryView {
    
    var totalSection: some View {
        
        VStack(alignment: .leading) {
            
            Text("Total Spending")
                .font(.headline)
            
            Text("₹\(viewModel.totalExpense(from: expenses), specifier: "%.0f")")
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.blue.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension SummaryView {
    
    var pieChartSection: some View {
        
        let data = viewModel.categoryExpenses(from: expenses)
        
        return VStack(alignment: .leading) {
            
            Text("Spending by Category")
                .font(.headline)
            
            PieChartView(data: data, value: {$0.amount}, label: {$0.category})
            
//            Chart(data) { item in
//                
//                SectorMark(
//                    angle: .value("Amount", item.amount),
//                    innerRadius: .ratio(0.5)
//                )
//                .foregroundStyle(by: .value("Category", item.category))
//                .annotation(position: .overlay) {
//                    
//                    Text(item.category)
//                        .font(.caption2)
//                }
//            }
//            .frame(height: 280)
        }
    }
}

extension SummaryView {
    var lastThreeMonthsSection: some View {
        
        VStack(alignment: .leading) {
            
            Text("Last 3 Months Spending")
                .font(.headline)
            
            PieChartView(
                data: viewModel.lastThreeMonthsExpenses(from: expenses),
                value: { $0.amount },
                label: { $0.month }
            )
        }
    }
    
    var lastFourWeeksSection: some View {
        
        VStack(alignment: .leading) {
            
            Text("Last 4 Weeks Spending")
                .font(.headline)
            
            PieChartView(
                data: viewModel.lastFourWeeksExpenses(from: expenses),
                value: { $0.amount },
                label: { $0.week }
            )
        }
    }
}

extension SummaryView {
    var insightsSection: some View {

        VStack(alignment: .leading) {

            Text("AI Insights")
                .font(.headline)

            ForEach(viewModel.insights, id: \.self) { insight in
                    
                    HStack(alignment: .top, spacing: 10) {
                        
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
        }
    }
}
