//
//  Balances.swift
//  Finances
//
//  Created by Martin Lanius on 30.04.25.
//

import Foundation
import SwiftData

@Model
final class MonthlyBalance {
    var month: Date = Date()
    var totalIncome: Double = 0.0
    var totalExpenses: Double = 0.0
    var netBalance: Double = 0.0
    var householdValue: Double = 0.0
    var startBalance: Double = 0.0
    var endBalance: Double = 0.0

    init(
        month: Date = Date(),
        totalIncome: Double = 0.0,
        totalExpenses: Double = 0.0,
        netBalance: Double = 0.0,
        householdValue: Double = 0.0,
        startBalance: Double = 0.0,
        endBalance: Double = 0.0
    ) {
        self.month = month
        self.totalIncome = totalIncome
        self.totalExpenses = totalExpenses
        self.netBalance = netBalance
        self.householdValue = householdValue
        self.startBalance = startBalance
        self.endBalance = endBalance
    }
}
