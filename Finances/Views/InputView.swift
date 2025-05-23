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
    @Bindable var settings: Settings
    
    private let helper = FinanceHelper()
    
    @State var category: Category = .income
    @State var amountString: String = ""
    @State var itemType: ItemType = .income
    
    @Binding var selectedMonthBinding: Int
    let selectedYear: Int
    
    @State private var startBalanceString: String = ""
    @State private var endBalanceString: String = ""
    @State private var yearlyExpenseAmount: String = ""
    
    init(selectedMonth: Binding<Int>, selectedYear: Int, settings: Settings) {
        self._selectedMonthBinding = selectedMonth
        self.selectedYear = selectedYear
        self._settings = Bindable(wrappedValue: settings)
    }
    
    private var isBalanceAlreadySaved: Bool {
        guard let selectedDate = Date.from(year: selectedYear, month: selectedMonthBinding) else {
            return false
        }
        let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBalance>())
        return existing?.contains(where: {
            $0.month.isSameMonth(as: selectedDate)
        }) ?? false
    }
    
    var body: some View {
        Form {
            Section(header: Text("Add transaction")) {
                HStack {
                    Text("Amount:")
                    TextField("Enter amount", text: $amountString)
                        .keyboardType(.decimalPad)
                }

                Picker("Category:", selection: $category) {
                    ForEach(Category.allCases.filter { $0 != .household }, id: \.self) { category in
                        Text(category.localizedString).tag(category)
                    }
                }

                Text("Type:")
                Picker("Type", selection: $itemType) {
                    ForEach(ItemType.allCases.filter { $0 != .calculatedHousehold }, id: \.self) { type in
                        Text(type.localizedName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Picker("Month:", selection: $selectedMonthBinding) {
                    ForEach(1...12, id: \.self) { month in
                        Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                    }
                }
                .onChange(of: selectedMonthBinding) {
                    preloadStartBalanceIfAvailable()
                }

                Button("Add transaction") {
                    addTransaction()
                }
            }

            Section(header: Text("Monthly Balance")) {
                HStack {
                    Text("Start Balance:")
                    TextField("End previous month", text: $startBalanceString)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("End Balance:")
                    TextField("End this month", text: $endBalanceString)
                        .keyboardType(.decimalPad)
                }
                Button("Save Balance") {
                    saveBalances()
                }
                .disabled(isBalanceAlreadySaved)
            }
        }
        .background(Color(hex: settings.backgroundColor))  // Set background color based on settings
        // Dynamically update theme mode based on the system mode or user choice
        .preferredColorScheme(settings.themeMode == "system" ? colorScheme : (settings.themeMode == "dark" ? .dark : .light))
        .onAppear {
            preloadStartBalanceIfAvailable()
        }
    }
    
    private func addTransaction() {
        withAnimation {
            guard let amount = helper.parseAmount(amountString) else { return }

            let categoryValue = category.rawValue

            guard let selectedDate = Date.from(year: selectedYear, month: selectedMonthBinding) else { return }

            let newTransaction = Transaction(
                date: selectedDate,
                category: categoryValue,
                amount: amount,
                type: Transaction.TransactionType(rawValue: itemType.rawValue) ?? .variableExpense
            )

            modelContext.insert(newTransaction)
            amountString = ""
            hideKeyboard()
        }
    }
    
    private func saveBalances() {
        guard let start = helper.parseAmount(startBalanceString), let end = helper.parseAmount(endBalanceString) else {
            print("Invalid value: start = \(startBalanceString), end = \(endBalanceString)")
            return
        }

        guard let selectedDate = Date.from(year: selectedYear, month: selectedMonthBinding) else { return }

        // Überprüfen, ob bereits ein Eintrag für diesen Monat existiert
        let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBalance>())
        if let match = existing?.first(where: { $0.month.isSameMonth(as: selectedDate) }) {
            print("Data already available for this month: \(match.month)")
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
        hideKeyboard()
    }
    
    private func preloadStartBalanceIfAvailable() {
        guard let currentMonthDate = Date.from(year: selectedYear, month: selectedMonthBinding),
              let previousMonthDate = Date.from(year: selectedYear, month: selectedMonthBinding - 1) ??
                                       Date.from(year: selectedYear - 1, month: 12) else {
            startBalanceString = ""
            endBalanceString = ""
            return
        }

        let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBalance>())

        // Check if current month already has a saved balance
        let isCurrentMonthSaved = existing?.contains(where: { $0.month.isSameMonth(as: currentMonthDate) }) ?? false

        if isCurrentMonthSaved {
            // Clear both fields if current month already has data
            startBalanceString = ""
            endBalanceString = ""
            return
        }

        // Preload start balance from previous month if available
        if let previousBalance = existing?.first(where: {
            $0.month.isSameMonth(as: previousMonthDate)
        }) {
            startBalanceString = String(format: "%.2f", previousBalance.endBalance)
        } else {
            startBalanceString = ""
        }
        endBalanceString = ""
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
