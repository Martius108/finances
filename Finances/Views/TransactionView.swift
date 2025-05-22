//
//  SpendingsView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import SwiftUI
import SwiftData

struct TransactionView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Bindable var settings: Settings
    
    @State private var fetchedItems: [Transaction] = []
    
    // State für den Monat und das Jahr
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedTransactions.keys.sorted(), id: \.self) { category in
                    Section(header: Text(Category(rawValue: category)?.localizedString ?? category)) {
                        ForEach(groupedTransactions[category] ?? [], id: \.id) { item in
                            NavigationLink(destination: TransactionEditView(transaction: .constant(item))) {
                                VStack(alignment: .leading) {
                                    Text("\(item.amount, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("All Expenses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addExpense) {
                    Label("New Expense value", systemImage: "plus")
                }
            }
        }
        .background(Color(hex: settings.backgroundColor))
        .preferredColorScheme(settings.themeMode == "system" ? colorScheme : (settings.themeMode == "dark" ? .dark : .light))
        .onAppear {
            loadTransactions()
        }
    }
    
    private var groupedTransactions: [String: [Transaction]] {
        Dictionary(grouping: fetchedItems) { $0.category }
    }

    private func addExpense() {
        let newExpense = Transaction(
            date: Date(),
            category: "other",
            amount: 0.0,
            type: .fixedExpense
        )
        modelContext.insert(newExpense)
    }
    
    private func loadTransactions() {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.date >= startOfMonth && transaction.date <= endOfMonth
            },
            sortBy: [.init(\.date, order: .forward)]
        )

        do {
            fetchedItems = try modelContext.fetch(descriptor)
        } catch {
            print("error while loading transactions: \(error.localizedDescription)")
        }
    }
}

