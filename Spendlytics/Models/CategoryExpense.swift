//
//  CategoryExpense.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import Foundation

struct CategoryExpense: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

struct MonthExpense: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct WeekExpense: Identifiable {
    let id = UUID()
    let week: String
    let amount: Double
}
