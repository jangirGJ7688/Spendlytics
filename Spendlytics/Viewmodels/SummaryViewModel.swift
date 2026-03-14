//
//  SummaryViewModel.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//


import SwiftUI
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {
    
    private let insigntService = InsightService()
    
    @Published var insights: [String] = []
    
    func categoryExpenses(from expenses: [Expense]) -> [CategoryExpense] {
        
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        return grouped.map { category, expenses in
            
            let total = expenses.reduce(0) { $0 + $1.amount }
            
            return CategoryExpense(
                category: category,
                amount: total
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    
    func totalExpense(from expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func lastThreeMonthsExpenses(from expenses: [Expense]) -> [MonthExpense] {
        
        let calendar = Calendar.current
        let now = Date()
        
        let months = (0..<3).map {
            calendar.date(byAdding: .month, value: -$0, to: now)!
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return months.map { date in
            
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            
            let filtered = expenses.filter {
                calendar.component(.month, from: $0.date) == month &&
                calendar.component(.year, from: $0.date) == year
            }
            
            let total = filtered.reduce(0) { $0 + $1.amount }
            
            return MonthExpense(
                month: formatter.string(from: date),
                amount: total
            )
        }
    }
    
    func lastFourWeeksExpenses(from expenses: [Expense]) -> [WeekExpense] {
        
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<4).map { weekOffset in
            
            let start = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
            
            let weekNumber = calendar.component(.weekOfYear, from: start)
            
            let filtered = expenses.filter {
                calendar.component(.weekOfYear, from: $0.date) == weekNumber
            }
            
            let total = filtered.reduce(0) { $0 + $1.amount }
            
            return WeekExpense(
                week: "W\(weekNumber)",
                amount: total
            )
        }
    }
    
    func createPrompt(expenses: [Expense]) -> String {
        
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        let summary = grouped.map { category, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            return "\(category): ₹\(Int(total))"
        }
            .joined(separator: "\n")
        
        return """
        Based on the expense summary below, generate exactly 2 short financial insights.
        
        Rules:
        - Each insight must be one sentence.
        - No numbering.
        - No markdown formatting.
        - No introduction text.
        - Return each insight on a new line.
        
        Expense Summary:
        \(summary)
        """
    }
    
    func fetchAIInsights(expenses: [Expense]) async {
        
        let prompt = createPrompt(expenses: expenses)
        
        do {
            let result = try await insigntService.generateInsights(prompt: prompt)
            
            await MainActor.run {
                self.insights = result
            }
            
        } catch {
            print(error)
        }
    }
}
