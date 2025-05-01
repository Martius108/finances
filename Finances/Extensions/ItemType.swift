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
    case startingBalance
    case yearlyExpense
    case calculatedHousehold

    var localizedName: String {
        switch self {
        case .income: return "Income"
        case .fixedExpense: return "Fixed Expense"
        case .variableExpense: return "Variable Expense"
        case .startingBalance: return "Balance"
        case .yearlyExpense: return "Jearly Expense"
        case .calculatedHousehold: return "Household"
        }
    }
}
