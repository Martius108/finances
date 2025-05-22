//
//  VariableExpensesView.swift
//  Finances
//
//  Created by Martin Lanius on 07.05.25.
//

import SwiftUI
import SwiftData
import Charts

struct DetailedExpensesView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Bindable var settings: Settings
    
    var title: String
    let transactions: [Transaction]
    
    var categorySums: [String: Double] {
        Dictionary(grouping: transactions, by: { $0.category })
            .mapValues { $0.map { abs($0.amount) }.reduce(0, +) }
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.headline)
                .padding(.bottom, 65)
            
            Chart {
                ForEach(categorySums.sorted(by: { $0.key < $1.key }), id: \.key) { categoryRaw, sum in
                    if let category = Category(rawValue: categoryRaw) {
                        SectorMark(
                            angle: .value("Amount", sum),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.0
                        )
                        .foregroundStyle(color(for: category))
                        .annotation(position: .overlay) {
                        }
                    }
                }
            }
            .frame(height: 300)
            .padding()
            Spacer()
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 12) {
                ForEach(categorySums.sorted(by: { $0.key < $1.key }), id: \.key) { categoryRaw, sum in
                    if let category = Category(rawValue: categoryRaw) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(color(for: category))
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("category.\(categoryRaw)", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Text(String(format: "%.2f €", sum))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            colorScheme == .dark
            ? (settings.backgroundColor.isEmpty ? Color(UIColor.systemBackground) : Color(hex: settings.backgroundColor))
            : (settings.backgroundColor.isEmpty ? Color(UIColor.systemBackground) : Color(hex: settings.backgroundColor))
        )
        .preferredColorScheme(settings.themeMode == "system" ? colorScheme : (settings.themeMode == "dark" ? .dark : .light))
    }
}
