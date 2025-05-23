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
    @Bindable var settings: Settings
    
    @Query var fetchedItems: [Transaction]
    @Query var balances: [MonthlyBalance]
    
    @AppStorage("copyFixedExpenses") private var copyFixedExpenses: Bool = false
    
    // State for month and year
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    // Prepare for detailed view of variable and fixed expenses
    @State private var showVariableDetail = false
    @State private var selectedVariableItems: [Transaction] = []
    @State private var showFixedDetail = false
    @State private var selectedFixedItems: [Transaction] = []
    
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
    
    // Flter by month and year
    func filteredItems(for month: Int, year: Int) -> [Transaction] {
        let filtered = fetchedItems.filter { item in
            let itemDate = item.date
            let itemMonth = Calendar.current.component(.month, from: itemDate)
            let itemYear = Calendar.current.component(.year, from: itemDate)
            return itemMonth == month && itemYear == year
        }
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Monthly Balance")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 8)
                
                Spacer(minLength: 20)
                
                // Select month and yer
                HStack {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1..<13) { month in
                            Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150, height: 50)
                    
                    Picker("Year", selection: $selectedYear) {
                        ForEach(2023...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                            Text(String(year))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100, height: 50)
                }
                
                Spacer(minLength: 20)
                
                let calculator = FinanceManager()
                let (_, saldo) = calculator.calculatedHouseholdExpense(
                    items: fetchedItems,
                    month: selectedMonth,
                    year: selectedYear,
                    balances: balances
                )
                let net = saldo
                Text("Balance: \(net, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.headline)
                    .padding(.bottom, 10)
                
                Spacer(minLength: 20)
                
                // Optimized filter logic
                let filteredItems = fetchedItems.filter {
                    Calendar.current.component(.month, from: $0.date) == selectedMonth &&
                    Calendar.current.component(.year, from: $0.date) == selectedYear
                }
                let variableAmount = filteredItems
                    .filter { $0.type == .variableExpense }
                    .map { abs($0.amount) }
                    .reduce(0, +)

                let fixedAmount = filteredItems
                    .filter { $0.type == .fixedExpense }
                    .map { abs($0.amount) }
                    .reduce(0, +)

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
                    value: net,
                    color: .green
                )

                let allSegments: [PieSegment] = {
                    var segments = [householdSegment, fixSegment, variableSegment]
                    if net > 0 {
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
                                .accessibilityLabel(segment.name) // Set for detailed view
                                .accessibilityValue("\(segment.value)") // Set for detailed view
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        // Overlay to make this part clickable for details
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
                                            // Wende Korrektur nur auf Start/Ende an (nun -90 Grad)
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
                                                debugPrint("Segment matched: \(segment.name)")
                                                switch segment.segmentType {
                                                case .fixed:
                                                    selectedFixedItems = filteredItems.filter { $0.type == .fixedExpense }
                                                    showFixedDetail = true
                                                case .variable:
                                                    selectedVariableItems = filteredItems.filter { $0.type == .variableExpense }
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
                                    Spacer()
                                    Text("""
                                    No data available yet. 
                                    Please add some expenses.
                                    If you start with January all fixed Expenses can be used for for the rest of the year. If you'd like to use this feature, please enable it below. 
                                    These values can be edited for each month later on in the Settings.
                                    Use this icon below \(Image(systemName: "pencil.and.list.clipboard"))
                                    """)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(maxWidth: geometry.size.width * 0.75)
                                    .multilineTextAlignment(.center)
                                    Spacer()
                                }
                                Spacer()
                                HStack {
                                    Toggle(isOn: $copyFixedExpenses) {
                                        Text("Copy Fixed Expenses")
                                    }
                                    .frame(maxWidth: 300)
                                    .padding()
                                }
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                }
                
                // NavigationLink separat nach Legende
                NavigationLink(destination: YearlyBalanceView(settings: settings, selectedMonth: $selectedMonth, selectedYear: $selectedYear)) {
                    Text("Show Yearly Balance")
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color(.blue))
                        .cornerRadius(20)
                }
                // Use navigationDestination for detailed expenses chart
                .navigationDestination(isPresented: $showVariableDetail) {
                    DetailedExpensesView(settings: settings, title: NSLocalizedString("Variable Expenses", comment: ""), transactions: selectedVariableItems)
                }
                .navigationDestination(isPresented: $showFixedDetail) {
                    DetailedExpensesView(settings: settings, title: NSLocalizedString("Fixed Expenses", comment: ""), transactions: selectedFixedItems)
                }
                Spacer(minLength: 50)
            }

            .onChange(of: selectedMonth) {
                if copyFixedExpenses {
                    let date = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
                    Task {
                        await copyFixedExpensesIfNeededAsync(for: date)
                    }
                } else {
                    // No prints here
                }
            }

            .onChange(of: selectedYear) {
                if copyFixedExpenses {
                    let date = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
                    Task {
                        await copyFixedExpensesIfNeededAsync(for: date)
                    }
                } else {
                    // No prints here
                }
            }
            
            .onAppear {
                let selectedDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!

                if copyFixedExpenses {
                    Task {
                        await copyFixedExpensesIfNeededAsync(for: selectedDate)
                    }
                } else {
                    // No prints here
                }

                // Check balance values
                balances.forEach { balance in
                    let comps = Calendar.current.dateComponents([.year, .month], from: balance.month)
                    let selectedComps = Calendar.current.dateComponents([.year, .month], from: selectedDate)
                    if comps.year == selectedComps.year && comps.month == selectedComps.month {
                        // Match found
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

    }
    
    func copyFixedExpensesIfNeeded(for selectedDate: Date) {

        Task {
            await copyFixedExpensesIfNeededAsync(for: selectedDate)
        }
    }

    // Async operation for copying fixed expenses
    func copyFixedExpensesIfNeededAsync(for selectedDate: Date) async {
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)

        let currentMonthTransactions = fetchedItems.filter {
            calendar.component(.month, from: $0.date) == selectedMonth &&
            calendar.component(.year, from: $0.date) == selectedYear &&
            $0.type == .fixedExpense
        }

        if !currentMonthTransactions.isEmpty {
            return
        }

        let previousFixed = fetchedItems
            .filter { $0.type == .fixedExpense && $0.date < selectedDate }
            .sorted { $0.date > $1.date }

        guard let lastMonthDate = previousFixed.first?.date else {
            return
        }

        let lastMonthFixed = previousFixed.filter {
            calendar.isDate($0.date, equalTo: lastMonthDate, toGranularity: .month)
        }

        if lastMonthFixed.count < 5 {
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

        do {
            try modelContext.save()
        } catch {
            // No prints here
        }
    }
}

