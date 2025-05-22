//
//  Transaction.swift
//  Finances
//
//  Created by Martin Lanius on 30.04.25.
//

import Foundation

enum ItemType: String, CaseIterable {
    case income
    case fixedExpense
    case variableExpense
    case calculatedHousehold

    var localizedName: String {
        switch self {
        case .income: return NSLocalizedString("Income", comment: "")
        case .fixedExpense: return NSLocalizedString("Fixed Expense", comment: "")
        case .variableExpense: return NSLocalizedString("Variable Expense", comment: "")
        case .calculatedHousehold: return NSLocalizedString("Household", comment: "")
        }
    }
}
