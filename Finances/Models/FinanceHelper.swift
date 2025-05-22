//
//  FinanceHelper.swift
//  Finances
//
//  Created by Martin Lanius on 02.05.25.
//

import Foundation
import SwiftData

struct FinanceHelper {
    
    func parseAmount(_ string: String) -> Double? {
        Double(string.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }

    func preloadStartBalanceForMonth(year: Int, month: Int, modelContext: ModelContext) -> String {
        guard let currentMonthDate = Date.from(year: year, month: month),
              let previousMonthDate = currentMonthDate.previousMonth() else {
            return ""
        }
        
        let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBalance>())
        if let previousBalance = existing?.first(where: { $0.month.isSameMonth(as: previousMonthDate) }) {
            return String(format: "%.2f", previousBalance.endBalance)
        }
        return ""
    }
    
}
