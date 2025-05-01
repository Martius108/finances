//
//  YearlyExpense.swift
//  Finances
//
//  Created by Martin Lanius on 30.04.25.
//

import Foundation
import SwiftData

@Model
final class YearlyExpense {
    var category: String = ""
    var amount: Double = 0.0
    var appliesToMonthlyBalance: Bool = false

    init(category: String, amount: Double, appliesToMonthlyBalance: Bool) {
        self.category = category
        self.amount = amount
        self.appliesToMonthlyBalance = appliesToMonthlyBalance
    }
}
