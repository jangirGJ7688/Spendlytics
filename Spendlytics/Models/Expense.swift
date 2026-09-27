//
//  Expense.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftData
import Foundation

@Model
final class Expense {
    var id: UUID
    var remoteID: Int64?
    var ownerScope: String?
    var name: String
    var category: String
    var date: Date
    var amount: Double
    
    init(id: UUID = UUID(), remoteID: Int64? = nil, ownerScope: String? = nil, name: String, category: String, date: Date, value: Double) {
        self.id = id
        self.remoteID = remoteID
        self.ownerScope = ownerScope
        self.name = name
        self.category = category
        self.date = date
        self.amount = value
    }
}
