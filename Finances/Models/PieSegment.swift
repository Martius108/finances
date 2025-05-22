//
//  PieSegment.swift
//  Finances
//
//  Created by Martin Lanius on 07.05.25.
//

import Foundation
import SwiftUI

struct PieSegment: Identifiable {

    var id = UUID()
    var segmentType: SegmentType
    var name: String
    var value: Double
    var color: Color
}

func color(for category: Category) -> Color {
    switch category {
    case .income: return .green
    case .vacation: return .blue
    case .fixExpense: return .red
    case .expense: return .red
    case .rent: return .cyan
    case .clothing: return .orange
    case .insurance: return .purple
    case .electricity: return .green
    case .internet: return .yellow
    case .restaurant: return .purple
    case .household: return .yellow
    @unknown default: return .gray
    }
}

enum SegmentType: String {
    case fixed
    case variable
    case household
    case balance
    case other
}
