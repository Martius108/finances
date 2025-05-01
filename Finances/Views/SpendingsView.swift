//
//  SpendingsView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import SwiftUI
import SwiftData

struct SpendingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date) var transactions: [Transaction]

    var body: some View {
        
        Text("All spendings here")
    }
}

#Preview {
    SpendingsView()
        .modelContainer(for: [Transaction.self, MonthlyBalance.self, Settings.self, YearlyExpense.self], inMemory: true)
}
