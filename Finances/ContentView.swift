//
//  ContentView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import SwiftUI
import SwiftData

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
            
            BalanceView(selectedMonth: $selectedMonth, selectedYear: $selectedYear)
                .tabItem {
                    Image(systemName: "plus.forwardslash.minus")
                    Text("Balance")
                }
            
            InputView(selectedMonth: 3, selectedYear: 2025)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Spendings")
                }
            
            if let storedSettings = settingsList.first,
               let storedBalance = monthlyBalances.first {
                SettingsView(
                    settings: storedSettings,
                    monthlyBalance: storedBalance,
                    selectedDate: Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth))!
                )
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
            } else {
                Text("Lade Einstellungen...")
            }
        }
        .onAppear {
            if settingsList.isEmpty {
                let new = Settings(themeMode: "system", backgroundColor: "#FFFFFF")
                modelContext.insert(new)
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, MonthlyBalance.self, Settings.self, YearlyExpense.self], inMemory: true)
}

    
