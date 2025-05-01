//
//  SettingsView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import Foundation
import SwiftUI
import SwiftData

// View for adjusting app settings like theme, background, and opacity
struct SettingsView: View {
    var selectedDate: Date
    
    // Access the model context to save changes
    @Environment(\.modelContext) private var modelContext
    // Access the current color scheme (light/dark mode)
    @Environment(\.colorScheme) var colorScheme
    // Bind the settings instance to this view
    @Bindable var settings: Settings
    
    @Query var monthlyBalances: [MonthlyBalance]
    @Bindable var monthlyBalance: MonthlyBalance
    
    @Query var allTransactions: [Transaction]
    
    @State private var isEditingStart = false
    @State private var isEditingEnd = false
    
    init(settings: Settings, monthlyBalance: MonthlyBalance, selectedDate: Date) {
        self._settings = Bindable(wrappedValue: settings)
        self._monthlyBalance = Bindable(wrappedValue: monthlyBalance)
        self.selectedDate = selectedDate
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
                            Text("\(monthlyBalance.startBalance, format: .currency(code: "EUR"))")
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
                            Text("\(monthlyBalance.endBalance, format: .currency(code: "EUR"))")
                            Button {
                                isEditingEnd = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                        }
                    }
                }
                
                Section(header: Text("Fixed Expenses")) {
                    let calendar = Calendar.current
                    let fixedExpensesForMonth = allTransactions.filter {
                        $0.type == .fixedExpense &&
                        calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
                    }

                    ForEach(fixedExpensesForMonth) { tx in
                        NavigationLink(destination: FixedExpenseEditView(transaction: tx)) {
                            HStack {
                                Text(tx.category)
                                Spacer()
                                Text("\(tx.amount, format: .currency(code: "EUR"))")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                saveSettings()
            }
        }
    }
            
    private func saveSettings() {
        do {
            try modelContext.save()  // Speichern der Änderungen im modelContext
            print("Settings successfully saved.")
        } catch {
            print("Error saving settings: \(error.localizedDescription)")
        }
    }
}

struct FixedExpenseEditView: View {
    @Bindable var transaction: Transaction

    var body: some View {
        Form {
            TextField("Category", text: $transaction.category)
            TextField("Amount", value: $transaction.amount, format: .number)
                .keyboardType(.decimalPad)
        }
        .navigationTitle("Edit Expense")
    }
}
