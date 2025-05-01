//
//  BalanceView.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import SwiftUI
import SwiftData
import Charts

struct BalanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: Settings
    
    @Query var fetchedItems: [Transaction]
    @Query var balances: [MonthlyBalance]
    
    // Query to retrieve the view settings
    @Query var settingsList: [Settings]
    
    // State für den Monat und das Jahr
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    
    var householdSpending: Double {
        let financeManager = FinanceManager()
        let (value, _) = financeManager.calculatedHouseholdExpense(
            items: fetchedItems,
            month: selectedMonth,
            year: selectedYear,
            balances: balances
        )
        return value
    }
    
    // Funktion zum Filtern der Items nach Monat und Jahr
    func filteredItems(for month: Int, year: Int) -> [Transaction] {
        return fetchedItems.filter { item in
            let itemDate = item.date
            let itemMonth = Calendar.current.component(.month, from: itemDate)
            let itemYear = Calendar.current.component(.year, from: itemDate)
            return itemMonth == month && itemYear == year
        }
    }
    
    var body: some View {
        ZStack {
            // Hintergrundfarbe über den gesamten Bildschirm, ignoriert Safe Area
            Color(hex: settings.backgroundColor)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Monthly Balance")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 8)
                
                Spacer(minLength: 20)  // Abstand zwischen Überschrift und Picker
                
                // Monat und Jahr Auswahl-Selector
                HStack {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1..<13) { month in
                            Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                    
                    Picker("Year", selection: $selectedYear) {
                        ForEach(2020...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                            Text(String(year))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                }
                
                Spacer(minLength: 20)  // Abstand zwischen Picker und Bilanz
                
                let calculator = FinanceManager()
                let (_, saldo) = calculator.calculatedHouseholdExpense(
                    items: fetchedItems,
                    month: selectedMonth,
                    year: selectedYear,
                    balances: balances
                )
                let net = saldo
                Text("Balance: \(net, format: .currency(code: "EUR"))")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                Spacer(minLength: 30)  // Abstand zwischen Bilanz und Tortendiagramm
                
                let variableAmount = fetchedItems.filter {
                    Calendar.current.component(.month, from: $0.date) == selectedMonth &&
                    Calendar.current.component(.year, from: $0.date) == selectedYear &&
                    $0.type == .variableExpense
                }
                .map { abs($0.amount) }
                .reduce(0, +)

                let fixedAmount = fetchedItems.filter {
                    Calendar.current.component(.month, from: $0.date) == selectedMonth &&
                    Calendar.current.component(.year, from: $0.date) == selectedYear &&
                    $0.type == .fixedExpense
                }
                .map { abs($0.amount) }
                .reduce(0, +)

                let fixSegment = PieSegment(
                    name: "Fixed Expenses",
                    value: fixedAmount,
                    color: .red
                )

                let variableSegment = PieSegment(
                    name: "Variable Expenses",
                    value: variableAmount,
                    color: .orange
                )

                let householdSegment = PieSegment(
                    name: "Household",
                    value: householdSpending,
                    color: .green
                )

                let allSegments = [householdSegment, fixSegment, variableSegment]
                
                VStack {
                    Chart {
                        ForEach(allSegments) { segment in
                            SectorMark(
                                angle: .value("Value", segment.value),
                                innerRadius: .ratio(0.5),
                                angularInset: 1
                            )
                            .foregroundStyle(segment.color)
                        }
                    }
                    .frame(height: 300)
                    .padding()

                    // Legende mit Beträgen
                    HStack {
                        ForEach(allSegments) { segment in
                            HStack {
                                Circle()
                                    .fill(segment.color)
                                    .frame(width: 15, height: 15)
                                Text("\(segment.name): \(segment.value, format: .currency(code: "EUR"))")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer(minLength: 50)  // Platz vor den TabViewItems
            }
            .onChange(of: selectedMonth) {
                let date = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
                copyFixedExpensesIfNeeded(for: date)
            }

            .onChange(of: selectedYear) {
                let date = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
                copyFixedExpensesIfNeeded(for: date)
            }
            .onAppear {
                debugFilteredItems()
                if let stored = settingsList.first {
                    settings.themeMode = stored.themeMode
                    settings.backgroundColor = stored.backgroundColor
                }
                
                let selectedDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
                
                copyFixedExpensesIfNeeded(for: selectedDate)
                
                // Logik zur Prüfung der Balance-Einträge für den ausgewählten Monat und Jahr
                balances.forEach { balance in
                    let comps = Calendar.current.dateComponents([.year, .month], from: balance.month)
                    let selectedComps = Calendar.current.dateComponents([.year, .month], from: selectedDate)

                    // Vergleiche nur Jahr und Monat
                    if comps.year == selectedComps.year && comps.month == selectedComps.month {
                        // Balance für den Monat gefunden - weitere Logik kann hier ergänzt werden
                    } else {
                        // Keine Balance für diesen Monat - weitere Logik kann hier ergänzt werden
                    }
                }
            }
            .background(Color(hex: settings.backgroundColor))
            .preferredColorScheme(settings.themeMode == "system" ? colorScheme : (settings.themeMode == "dark" ? .dark : .light))
        }
    }
    
    func debugFilteredItems() {
        let filtered = filteredItems(for: selectedMonth, year: selectedYear)
        print("Gefilterte Items für \(selectedMonth)/\(selectedYear): \(filtered.count) Items gefunden")
        filtered.forEach { item in
            print("→ \(item.type.rawValue), \(item.category), \(item.amount), \(item.date)")
        }
    }
    
    func copyFixedExpensesIfNeeded(for selectedDate: Date) {
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)

        let currentMonthTransactions = fetchedItems.filter {
            calendar.component(.month, from: $0.date) == selectedMonth &&
            calendar.component(.year, from: $0.date) == selectedYear &&
            $0.type == .fixedExpense
        }

        guard currentMonthTransactions.isEmpty else {
            debugPrint("Fixed expenses already exist for: \(selectedMonth)/\(selectedYear), skipping copy.")
            return
        }

        let previousFixed = fetchedItems
            .filter { $0.type == .fixedExpense && $0.date < selectedDate }
            .sorted { $0.date > $1.date }

        guard let lastMonthDate = previousFixed.first?.date else {
            debugPrint("No previous month with fixed expenses found — skipping.")
            return
        }

        let lastMonthFixed = previousFixed.filter {
            calendar.isDate($0.date, equalTo: lastMonthDate, toGranularity: .month)
        }

        guard lastMonthFixed.count >= 5 else {
            debugPrint("Previous month (\(lastMonthDate)) has only \(lastMonthFixed.count) fixed expenses — skipping copy.")
            return
        }

        var insertedCount = 0
        for tx in lastMonthFixed {
            let copiedTransaction = Transaction(
                date: selectedDate,
                category: tx.category,
                amount: tx.amount,
                type: .fixedExpense
            )
            modelContext.insert(copiedTransaction)
            insertedCount += 1
        }
        debugPrint("Fixed expenses copied to: \(selectedMonth)/\(selectedYear) — \(insertedCount) items inserted.")
        try? modelContext.save()
    }
}

struct PieSegment: Identifiable {
    var id = UUID()
    var name: String
    var value: Double
    var color: Color
}

func color(for category: Category) -> Color {
    switch category {
    case .vacation: return .blue
    case .fixExpense: return .red
    case .expense: return .orange
    case .restaurant: return .purple
    case .household: return .yellow
    @unknown default: return .gray
    }
}

#Preview {
    @Previewable @State var month = Calendar.current.component(.month, from: Date())
    @Previewable @State var year = Calendar.current.component(.year, from: Date())
    BalanceView(selectedMonth: $month, selectedYear: $year)
        .modelContainer(for: [Transaction.self, MonthlyBalance.self, Settings.self, YearlyExpense.self], inMemory: true)
}
