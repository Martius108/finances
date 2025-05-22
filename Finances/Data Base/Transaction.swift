//
//  Item.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var date: Date = Date()
    var category: String = ""
    var amount: Double = 0.0
    var type: TransactionType

    enum TransactionType: String, Codable, CaseIterable {
        case income
        case fixedExpense
        case variableExpense

        var localizedName: String {
            switch self {
            case .income: return NSLocalizedString("Income", comment: "")
            case .fixedExpense: return NSLocalizedString("Fixed Expense", comment: "")
            case .variableExpense: return NSLocalizedString("Variable Expense", comment: "")
            }
        }
    }

    init(date: Date, category: String, amount: Double, type: TransactionType) {
        self.date = date
        self.category = category
        self.amount = amount
        self.type = type
    }
}
