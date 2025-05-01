//
//  FinancesApp.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import SwiftUI
import SwiftData

@main
struct FinancesApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            MonthlyBalance.self,
            Settings.self,
            YearlyExpense.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var settings = Settings(themeMode: "system", backgroundColor: "#FFFFFF")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)  // Hier wird settings übergeben
        }
        .modelContainer(sharedModelContainer)
    }
}
