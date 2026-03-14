//
//  ExpenseFilter.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import Foundation

struct ExpenseFilter {
    var searchText: String = ""
    var selectedCategory: String? = nil
    var startDate: Date? = nil
    var endDate: Date? = nil
    var minPrice: Double? = nil
    var maxPrice: Double? = nil
}
