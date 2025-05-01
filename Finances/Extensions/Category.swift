//
//  Category.swift
//  Finances
//
//  Created by Martin Lanius on 28.04.25.
//

import Foundation

enum Category: String, CaseIterable {
    case vacation
    case expense
    case fixExpense
    case restaurant
    case household
}

extension Category {
    var localizationKey: String {
        "category.\(self.rawValue)"
    }
    var localizedString: String {
        NSLocalizedString(self.localizationKey, comment: "")
    }
}
