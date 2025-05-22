//
//  Date.swift
//  Finances
//
//  Created by Martin Lanius on 02.05.25.
//

import Foundation

extension Date {
    static func from(year: Int, month: Int, day: Int = 1) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }

    func previousMonth() -> Date? {
        Calendar.current.date(byAdding: .month, value: -1, to: self)
    }
}
