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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
