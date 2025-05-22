//
//  TransactionEditView.swift
//  Finances
//
//  Created by Martin Lanius on 05.05.25.
//

import SwiftUI

// Additional view for editing values
struct TransactionEditView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding private var transaction: Transaction

    init(transaction: Binding<Transaction>) {
        self._transaction = transaction
    }

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            
            Picker("Category", selection: Binding(
                get: {
                    Category(rawValue: transaction.category) ?? .expense
                },
                set: {
                    transaction.category = $0.rawValue
                }
            )) {
                ForEach(Category.allCases.filter { $0 != .household }, id: \.self) { category in
                    Text(category.localizedString).tag(category)
                }
            }
            
            TextField("Amount", value: $transaction.amount, formatter: NumberFormatter.decimalInput)
                .keyboardType(.decimalPad)

            Section {
                HStack {
                    Spacer()
                    Button("Save") {
                        do {
                            try modelContext.save()
                            hideKeyboard()
                            print("Changes saved successfully.")
                            dismiss()
                        } catch {
                            print("Error while saving changes: \(error.localizedDescription)")
                        }
                    }
                    Spacer()
                    Button("Delete") {
                        do {
                            modelContext.delete(transaction)
                            try modelContext.save()
                            hideKeyboard()
                            print("Transaction deleted successfully.")
                            dismiss()
                        } catch {
                            print("Error while deleting item: \(error.localizedDescription)")
                        }
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
        }
        .navigationTitle("Edit Expense")
    }
}

extension NumberFormatter {
    static var decimalInput: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
