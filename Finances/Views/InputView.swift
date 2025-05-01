//
//  InputView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import SwiftUI
import SwiftData

struct InputView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: Settings
    
    @State var category: Category = .expense
    @State var amountString: String = ""
    @State var itemType: ItemType = .variableExpense
    
    @State private var selectedMonthInternal: Int
    let selectedMonth: Int
    let selectedYear: Int
    
    @State private var startBalanceString: String = ""
    @State private var endBalanceString: String = ""
    @State private var yearlyExpenseAmount: String = ""
    
    init(selectedMonth: Int, selectedYear: Int) {
        self.selectedMonth = selectedMonth
        self.selectedYear = selectedYear
        _selectedMonthInternal = State(initialValue: selectedMonth)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Transaktion hinzufügen")) {
                HStack {
                    Text("Amount:")
                    TextField("Enter amount", text: $amountString)
                        .keyboardType(.decimalPad)
                }

                Picker("Category", selection: $category) {
                    ForEach(Category.allCases, id: \.self) { priority in
                        Text(priority.localizedString).tag(priority)
                    }
                }

                Picker("Type", selection: $itemType) {
                    ForEach(ItemType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type)
                    }
                }

                Picker("Monat", selection: $selectedMonthInternal) {
                    ForEach(1...12, id: \.self) { month in
                        Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                    }
                }

                Button("Add transaction") {
                    addTransaction()
                }
            }

            Section(header: Text("Saldo erfassen")) {
                HStack {
                    Text("Anfangssaldo:")
                    TextField("z. B. 2000", text: $startBalanceString)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Endsaldo:")
                    TextField("z. B. 2600", text: $endBalanceString)
                        .keyboardType(.decimalPad)
                }
                Button("Saldo speichern") {
                    saveBalances()
                }
                if !startBalanceString.isEmpty || !endBalanceString.isEmpty {
                    let startValid = Double(startBalanceString.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) != nil
                    let endValid = Double(endBalanceString.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) != nil
                    if !startValid || !endValid {
                        Text("Bitte gültige Werte für Anfangs- und Endsaldo eingeben.")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section(header: Text("Jährliche Ausgaben")) {
                HStack {
                    Text("Betrag:")
                    TextField("z. B. 1200", text: $yearlyExpenseAmount)
                        .keyboardType(.decimalPad)
                }
                Button("Jährliche Ausgabe speichern") {
                    saveYearlyExpense()
                }
            }
        }
    }
    
    private func addTransaction() {
        withAnimation {
            let cleanAmount = amountString.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
            guard let amount = Double(cleanAmount) else { return }

            let categoryValue: String
            if itemType == .income || itemType == .startingBalance {
                categoryValue = ""
            } else {
                categoryValue = category.rawValue
            }

            let calendar = Calendar.current
            let selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonthInternal, day: 1)) ?? Date()

            let newTransaction = Transaction(
                date: selectedDate,
                category: categoryValue,
                amount: amount,
                type: Transaction.TransactionType(rawValue: itemType.rawValue) ?? .variableExpense
            )

            modelContext.insert(newTransaction)
            amountString = ""
        }
    }
    
    private func saveBalances() {
        let startClean = startBalanceString.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        let endClean = endBalanceString.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        print("DEBUG → Rohwerte: start = \(startClean), end = \(endClean)")

        guard let start = Double(startClean), let end = Double(endClean) else {
            print("Ungültige Eingabe: start = \(startClean), end = \(endClean)")
            return
        }
        
        print("DEBUG → Konvertiert: Start: \(start), End: \(end)")

        let calendar = Calendar.current
        let selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonthInternal, day: 1)) ?? Date()

        // Überprüfen, ob bereits ein Eintrag für diesen Monat existiert
        let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBalance>())
        if let match = existing?.first(where: { Calendar.current.isDate($0.month, equalTo: selectedDate, toGranularity: .month) }) {
            print("Eintrag für diesen Monat existiert bereits: \(match.month)")
            return
        }

        let newBalance = MonthlyBalance(
            month: selectedDate,
            totalIncome: 0.0,
            totalExpenses: 0.0,
            netBalance: end - start,
            householdValue: 0.0,
            startBalance: start,
            endBalance: end
        )
        modelContext.insert(newBalance)
        try? modelContext.save()
        startBalanceString = ""
        endBalanceString = ""
    }
    
    private func saveYearlyExpense() {
        let cleanAmount = yearlyExpenseAmount.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let amount = Double(cleanAmount) else { return }

        let newExpense = YearlyExpense(category: "Allgemein", amount: amount, appliesToMonthlyBalance: false)
        modelContext.insert(newExpense)

        yearlyExpenseAmount = ""
    }
}

#Preview {
    InputView(selectedMonth: 1, selectedYear: 2024)
        .modelContainer(for: [Transaction.self, MonthlyBalance.self, Settings.self, YearlyExpense.self], inMemory: true)
}
