//
//  FinanceManager.swift
//  Finances
//
//  Created by Martin Lanius on 30.04.25.
//

import Foundation
import SwiftData

struct FinanceManager {
    
    func income(items: [Transaction], month: Int, year: Int) -> Double {
        let incomeTotal = items.filter {
            $0.type == .income &&
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year, from: $0.date) == year
        }
            .map(\.amount)
            .reduce(0, +)
        
        print("Income for \(month)/\(year): \(incomeTotal)")
        return incomeTotal
    }
    
    func expenses(items: [Transaction], month: Int, year: Int) -> Double {
        let expensesTotal = items.filter {
            ($0.type == .fixedExpense || $0.type == .variableExpense) &&
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year, from: $0.date) == year
        }
            .map(\.amount)
            .reduce(0, +)
        
        print("Expenses for \(month)/\(year): \(expensesTotal)")
        return expensesTotal
    }
    
    func calculatedHouseholdExpense(
        items: [Transaction],
        month: Int,
        year: Int,
        balances: [MonthlyBalance]
    ) -> (Double, Double) {
        // Get the start balance value for chosen month
        let startBalance = balances.first(where: {
            let comps = Calendar.current.dateComponents([.year, .month], from: $0.month)
            return comps.year == year && comps.month == month
        })?.startBalance ?? 0.0

        // Get the end balance value for the chosen month
        let endBalance = balances.first(where: {
            let comps = Calendar.current.dateComponents([.year, .month], from: $0.month)
            return comps.year == year && comps.month == month
        })?.endBalance ?? 0.0

        // Debug: Show month and year
        print("Month / Year: \(month)/\(year)")
        print("Start Balance: \(startBalance), End Balance: \(endBalance)")

        // Calculate monthly balance
        let incomeTotal = income(items: items, month: month, year: year)
        let expensesTotal = expenses(items: items, month: month, year: year)
        let saldo = endBalance - startBalance

        // Household spendings
        let householdSpending = incomeTotal - expensesTotal - saldo
        print("Income: \(incomeTotal), Expenses: \(expensesTotal), Balance: \(saldo)")
        print("Household Spendings: \(householdSpending)")

        return (max(householdSpending, 0), saldo)
    }
    
    func calculateMonthlyExpenseFromYearly(yearlyExpense: Double) -> Double {
        return yearlyExpense / 12
    }
    
    func averageMonthlyExpense(items: [Transaction]) -> Double {
        let totalExpenses = items.filter {
            $0.type == .fixedExpense || $0.type == .variableExpense
        }
            .map(\.amount)
            .reduce(0, +)
        
        let months = Set(items.map {
            let components = Calendar.current.dateComponents([.year, .month], from: $0.date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }).count
        
        return months > 0 ? totalExpenses / Double(months) : 0
    }
    
    func yearlyBalance(items: [Transaction], year: Int) -> Double {
        let incomeTotal = items.filter {
            $0.type == .income && Calendar.current.component(.year, from: $0.date) == year
        }
            .map(\.amount)
            .reduce(0, +)
        
        let expensesTotal = fixedAndVariableExpenses(from: items, year: year)
        
        return incomeTotal - expensesTotal
    }
    
    func expenseRatio(income: Double, expenses: Double) -> Double {
        return income == 0 ? 0 : expenses / income
    }
    
    func calculateYearlyExpenseAverage(
        items: [Transaction],
        balances: [MonthlyBalance],
        forYear year: Int
    ) -> Double {
        let yearMonths = (1...12)

        let yearlyHousehold = yearMonths.reduce(0.0) { total, month in
            let (household, _) = self.calculatedHouseholdExpense(
                items: items,
                month: month,
                year: year,
                balances: balances
            )
            print("Household for \(month)/\(year): \(household)")
            return total + household
        }

        let yearlyFixedAndVariable = fixedAndVariableExpenses(from: items, year: year)
        print("Fixed and variable expenses for \(year): \(yearlyFixedAndVariable)")

        let yearlyTotal = yearlyHousehold + yearlyFixedAndVariable
        print("Yearly total expenses before averaging: \(yearlyTotal)")

        return yearlyTotal / 12
    }
    
    func fixedAndVariableExpenses(from items: [Transaction], year: Int) -> Double {
        items.filter {
            ($0.type == .fixedExpense || $0.type == .variableExpense) &&
            Calendar.current.component(.year, from: $0.date) == year
        }
        .map { abs($0.amount) }
        .reduce(0, +)
    }
    
    func averageMonthlyIncome(items: [Transaction]) -> Double {
        let incomeItems = items.filter { $0.type == .income }

        let totalIncome = incomeItems
            .map(\.amount)
            .reduce(0, +)

        let months = Set(incomeItems.map {
            let components = Calendar.current.dateComponents([.year, .month], from: $0.date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }).count

        return months > 0 ? totalIncome / Double(months) : 0
    }
}
