//
//  ContentView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import SwiftUI
import SwiftData

// Main View as TabView holding all data
struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    // Query to retrieve the view settings stored in iCloud
    @Query var settingsList: [Settings]
    @Query var monthlyBalances: [MonthlyBalance]
    
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        
        TabView {
            BalanceView(settings: settingsList.first ?? Settings(), selectedMonth: $selectedMonth, selectedYear: $selectedYear)
                .tabItem {
                    Image(systemName: "plus.forwardslash.minus")
                    Text("Balance")
                }
            
            InputView(selectedMonth: $selectedMonth, selectedYear: selectedYear, settings: settingsList.first ?? Settings())
                .tabItem {
                    Image(systemName: "pencil.and.list.clipboard")
                    Text("Spendings")
                }
            
            TransactionView(settings: settingsList.first ?? Settings(), selectedMonth: $selectedMonth, selectedYear: $selectedYear)
                .tabItem {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
            
            let storedBalance = monthlyBalances.first(where: {
                Calendar.current.component(.month, from: $0.month) == selectedMonth &&
                Calendar.current.component(.year, from: $0.month) == selectedYear
            }) ?? MonthlyBalance(month: Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth)) ?? Date())

            SettingsView(
                settings: settingsList.first ?? Settings(),
                monthlyBalance: storedBalance,
                selectedMonth: $selectedMonth,
                selectedYear: $selectedYear
            )
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
        .onAppear {
            if settingsList.isEmpty {
                let newSettings = Settings()
                modelContext.insert(newSettings)
            }
            saveSettings() // Speichern nach dem Laden der View
        }
        .onChange(of: settingsList) { oldValue, newValue in
            if let first = newValue.first {
                print("Settings loaded: \(first)")
            } else {
                print("No settings available")
            }
        }
        .preferredColorScheme(settingsList.first?.themeMode == "system" ? colorScheme : (settingsList.first?.themeMode == "dark" ? .dark : .light))
    }
    
    func saveSettings() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, MonthlyBalance.self, Settings.self], inMemory: true)
}

    
