//
//  SettingsView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import Foundation
import SwiftUI
import SwiftData

// View for adjusting app settings and editing other App values
struct SettingsView: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    
    // Access the model context to save changes
    @Environment(\.modelContext) private var modelContext
    // Access the current color scheme (light/dark mode)
    @Environment(\.colorScheme) var colorScheme
    // Bind the settings instance to this view
    @Bindable var settings: Settings

    @Bindable var monthlyBalance: MonthlyBalance
    
    @Query var allTransactions: [Transaction]
    
    @State private var isEditingStart = false
    @State private var isEditingEnd = false
    
    private let helper = FinanceHelper()
    
    init(settings: Settings, monthlyBalance: MonthlyBalance, selectedMonth: Binding<Int>, selectedYear: Binding<Int>) {
        self._settings = Bindable(wrappedValue: settings)
        self._monthlyBalance = Bindable(wrappedValue: monthlyBalance)
        self._selectedMonth = selectedMonth
        self._selectedYear = selectedYear
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Theme Mode Picker Section
                Section(header: Text("Theme Mode")) {
                    Picker("Select Theme", selection: $settings.themeMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: settings.themeMode) { oldValue, newValue in
                        settings.themeMode = newValue
                        do {
                            try modelContext.save()
                            print("Theme mode changed from \(oldValue) to \(newValue)")
                        } catch {
                            print("Saving theme mode failed: \(error.localizedDescription)")
                        }
                    }
                }
                
                // Background Color Picker Section
                Section(header: Text("Background Color")) {
                    ColorPicker("Select Background Color", selection: Binding(
                        get: { Color(hex: settings.backgroundColor) },
                        set: { newColor in
                            // Reset background image when a new color is chosen
                            settings.backgroundColor = newColor.toHex()
                            do {
                                try modelContext.save()
                                print("Background color changed to: \(settings.backgroundColor)")
                            } catch {
                                print("Saving background color failed: \(error.localizedDescription)")
                            }
                        }
                    ))
                }
                // Monthly Balance Section
                Section(header: Text("Monthly Balance")) {
                    HStack {
                        Text("Start Balance:")
                        Spacer()
                        if isEditingStart {
                            TextField("", value: $monthlyBalance.startBalance, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onSubmit {
                                    saveSettings()
                                    isEditingStart = false
                                }
                        } else {
                            Text("\(monthlyBalance.startBalance, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))")
                            Button {
                                isEditingStart = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                        }
                    }
                    HStack {
                        Text("End Balance:")
                        Spacer()
                        if isEditingEnd {
                            TextField("", value: $monthlyBalance.endBalance, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onSubmit {
                                    saveSettings()
                                    isEditingEnd = false
                                }
                        } else {
                            Text("\(monthlyBalance.endBalance, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))")
                            Button {
                                isEditingEnd = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                        }
                    }
                }
                // Get all fixed expense values here to edit them
                Section(header: Text("Fixed Expenses")) {
                    let calendar = Calendar.current
                    let selectedDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth))!
                    let fixedExpensesForMonth = allTransactions.filter {
                        $0.type == .fixedExpense &&
                        calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
                    }

                    ForEach(fixedExpensesForMonth) { tx in
                        NavigationLink(destination: TransactionEditView(transaction: .constant(tx))) {
                            HStack {
                                Text(Category(rawValue: tx.category)?.localizedString ?? tx.category)
                                Spacer()
                                Text("\(tx.amount, format: .currency(code: "EUR"))")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadMonthlyBalance()
            }
        }
    }
            
    private func saveSettings() {
        do {
            try modelContext.save()  // Save changes in modelContext
            print("Settings successfully saved.")
        } catch {
            print("Error saving settings: \(error.localizedDescription)")
        }
    }

    private func loadMonthlyBalance() {
        let calendar = Calendar.current
        guard let selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth)) else { return }
        let allBalances = try? modelContext.fetch(FetchDescriptor<MonthlyBalance>())

        if let foundBalance = allBalances?.first(where: {
            calendar.isDate($0.month, equalTo: selectedDate, toGranularity: .month)
        }) {
            monthlyBalance.startBalance = foundBalance.startBalance
            monthlyBalance.endBalance = foundBalance.endBalance
            monthlyBalance.netBalance = foundBalance.netBalance
            monthlyBalance.householdValue = foundBalance.householdValue
            monthlyBalance.totalIncome = foundBalance.totalIncome
            monthlyBalance.totalExpenses = foundBalance.totalExpenses
        } else {
            // Nur initialisieren, wenn *wirklich* keine Werte gesetzt sind
            if monthlyBalance.startBalance == 0.0 {
                let result = helper.preloadStartBalanceForMonth(year: selectedYear, month: selectedMonth, modelContext: modelContext)
                monthlyBalance.startBalance = Double(result) ?? 0.0
            }
            // endBalance NICHT antasten
        }
    }
}

