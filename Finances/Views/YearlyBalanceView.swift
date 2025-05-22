//
//  YearlyBalanceView.swift
//  Finances
//
//  Created by Martin Lanius on 05.05.25.
//

import SwiftUI
import SwiftData
import Charts

struct YearlyBalanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Bindable var settings: Settings
    
    @Query var fetchedItems: [Transaction]
    @Query var balances: [MonthlyBalance]
    
    // State für den Monat und das Jahr
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int

    @State private var showFixedDetail = false
    @State private var showVariableDetail = false
    @State private var selectedFixedItems: [Transaction] = []
    @State private var selectedVariableItems: [Transaction] = []
    
    var householdSpending: Double {
        let financeManager = FinanceManager()
        let (value, _) = financeManager.calculatedHouseholdExpense(
            items: fetchedItems,
            month: selectedMonth,
            year: selectedYear,
            balances: balances
        )
        debugPrint("Household Spending calculation for \(selectedMonth)/\(selectedYear): \(value)")
        return value
    }
    
    // Funktion zum Filtern der Items nach Monat und Jahr
    func filteredItems(for month: Int, year: Int) -> [Transaction] {
        let filtered = fetchedItems.filter { item in
            let itemDate = item.date
            let itemMonth = Calendar.current.component(.month, from: itemDate)
            let itemYear = Calendar.current.component(.year, from: itemDate)
            return itemMonth == month && itemYear == year
        }
        // Debugging der gefilterten Transaktionen
        debugPrint("Filtered Items for \(month)/\(year): \(filtered.count) items found.")
        filtered.forEach { item in
            debugPrint("→ Item: \(item.type.rawValue), \(item.category), \(item.amount), \(item.date)")
        }
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            // Hintergrundfarbe über den gesamten Bildschirm, ignoriert Safe Area
            //Color(hex: settings.backgroundColor)
                //.ignoresSafeArea()
            VStack {
                Spacer()
                Text("Yearly Balance")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 8)
                
                Spacer(minLength: 40)  // Abstand zwischen Picker und Bilanz
                
                let yearMonths = (1...12)
                let calculator = FinanceManager()

                let yearlyHousehold = yearMonths.reduce(0.0) { total, month in
                    let (household, _) = calculator.calculatedHouseholdExpense(
                        items: fetchedItems,
                        month: month,
                        year: selectedYear,
                        balances: balances
                    )
                    return total + household
                }

                let yearlyTransactions = fetchedItems.filter {
                    Calendar.current.component(.year, from: $0.date) == selectedYear
                }

                let yearlyFixed = yearlyTransactions.filter { $0.type == .fixedExpense }
                    .map { abs($0.amount) }
                    .reduce(0, +)

                let yearlyVariable = yearlyTransactions.filter { $0.type == .variableExpense }
                    .map { abs($0.amount) }
                    .reduce(0, +)

                let yearlyNetBalance = balances
                    .filter { Calendar.current.component(.year, from: $0.month) == selectedYear }
                    .map { $0.endBalance - $0.startBalance }
                    .reduce(0, +)

                let variableAmount = yearlyVariable
                let fixedAmount = yearlyFixed
                let householdSpending = yearlyHousehold
                
                Text("Balance: \(yearlyNetBalance, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.headline)
                    .padding(.bottom, 10)
                
                Spacer(minLength: 30)  // Abstand zwischen Bilanz und Tortendiagramm
                
                let fixSegment = PieSegment(
                    segmentType: .fixed,
                    name: NSLocalizedString("Fixed", comment: ""),
                    value: fixedAmount,
                    color: .red
                )

                let variableSegment = PieSegment(
                    segmentType: .variable,
                    name: NSLocalizedString("Variable", comment: ""),
                    value: variableAmount,
                    color: .orange
                )

                let householdSegment = PieSegment(
                    segmentType: .household,
                    name: NSLocalizedString("Household", comment: ""),
                    value: householdSpending,
                    color: .blue
                )
                
                let saldoSegment = PieSegment(
                    segmentType: .balance,
                    name: NSLocalizedString("Balance", comment: ""),
                    value: yearlyNetBalance,
                    color: .green
                )

                let allSegments: [PieSegment] = {
                    var segments = [householdSegment, fixSegment, variableSegment]
                    if yearlyNetBalance > 0 {
                        segments.append(saldoSegment)
                    }
                    return segments
                }()
                let visibleSegments = allSegments.filter { $0.value > 0 }
                
                VStack { // Create the chart from all segments
                    if !visibleSegments.isEmpty {
                        Chart {
                            ForEach(visibleSegments) { segment in
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
                        .overlay(
                            GeometryReader { geometry in
                                let size = geometry.size
                                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                                Color.clear
                                    .contentShape(Circle())
                                    .onTapGesture { location in
                                        let dx = location.x - center.x
                                        let dy = location.y - center.y
                                        let angle = atan2(dy, dx) * 180 / .pi
                                        let correctedAngle = (angle < 0 ? angle + 360 : angle)

                                        let total = visibleSegments.map(\.value).reduce(0, +)
                                        var angleMap: [(segment: PieSegment, startAngle: Double, endAngle: Double)] = []
                                        var currentAngle: Double = 0

                                        visibleSegments.forEach { segment in
                                            let segmentAngle = segment.value / total * 360.0
                                            let rawStart = currentAngle
                                            let rawEnd = currentAngle + segmentAngle
                                            let start = (rawStart - 90).truncatingRemainder(dividingBy: 360)
                                            let end = (rawEnd - 90).truncatingRemainder(dividingBy: 360)
                                            angleMap.append((segment, start, end))
                                            currentAngle += segmentAngle
                                        }

                                        for (segment, start, end) in angleMap {
                                            let inSegment: Bool
                                            if start < end {
                                                inSegment = correctedAngle >= start && correctedAngle < end
                                            } else {
                                                inSegment = correctedAngle >= start || correctedAngle < end
                                            }

                                            if inSegment {
                                                switch segment.segmentType {
                                                case .fixed:
                                                    selectedFixedItems = fetchedItems.filter {
                                                        Calendar.current.component(.year, from: $0.date) == selectedYear && $0.type == .fixedExpense
                                                    }
                                                    showFixedDetail = true
                                                case .variable:
                                                    selectedVariableItems = fetchedItems.filter {
                                                        Calendar.current.component(.year, from: $0.date) == selectedYear && $0.type == .variableExpense
                                                    }
                                                    showVariableDetail = true
                                                default:
                                                    break
                                                }
                                                break
                                            }
                                        }
                                    }
                            }
                        )
                        Spacer()
                        // Footer with details
                        HStack {
                            ForEach(visibleSegments) { segment in
                                HStack {
                                    Circle()
                                        .fill(segment.color)
                                        .frame(width: 15, height: 15)
                                    Text("\(segment.name): \(segment.value, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))")
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        Spacer()
                    } else {
                        GeometryReader { geometry in
                            VStack {
                                HStack {
                                    Text("No data available")
                                    Spacer()
                                }
                            }
                        }
                        Spacer()
                    }
                }
                
                Spacer(minLength: 50)
                // Deprecated, but required for correct back-navigation from DetailedExpensesView to YearlyBalanceView
                NavigationLink(
                    destination: DetailedExpensesView(settings: settings, title: NSLocalizedString("Fixed Expenses", comment: ""), transactions: selectedFixedItems),
                    isActive: $showFixedDetail,
                    label: { EmptyView() }
                )

                NavigationLink(
                    destination: DetailedExpensesView(settings: settings, title: NSLocalizedString("Variable Expenses", comment: ""), transactions: selectedVariableItems),
                    isActive: $showVariableDetail,
                    label: { EmptyView() }
                )
            }
            .onChange(of: selectedMonth) {
 
            }

            .onChange(of: selectedYear) {

            }
            
            .onAppear {
                debugFilteredItems()
                debugPrint("Initial fetch for items and balances...")
                debugPrint("Fetched items count: \(fetchedItems.count)")
                debugPrint("Fetched balances count: \(balances.count)")

                let selectedDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!

                // Prüfung der Balance-Einträge
                balances.forEach { balance in
                    let comps = Calendar.current.dateComponents([.year, .month], from: balance.month)
                    let selectedComps = Calendar.current.dateComponents([.year, .month], from: selectedDate)
                    if comps.year == selectedComps.year && comps.month == selectedComps.month {
                        // Match gefunden
                    }
                }
            }
            .background(
                colorScheme == .dark
                ? (settings.backgroundColor.isEmpty ? Color(UIColor.systemBackground) : Color(hex: settings.backgroundColor))
                : (settings.backgroundColor.isEmpty ? Color(UIColor.systemBackground) : Color(hex: settings.backgroundColor))
            )
            .preferredColorScheme(settings.themeMode == "system" ? colorScheme : (settings.themeMode == "dark" ? .dark : .light))
        }
    }
    
    func debugFilteredItems() {
        let filtered = filteredItems(for: selectedMonth, year: selectedYear)
        print("Filtered Items for \(selectedMonth)/\(selectedYear): \(filtered.count) Items found")
        filtered.forEach { item in
            print("→ \(item.type.rawValue), \(item.category), \(item.amount), \(item.date)")
        }
    }
}
