//
//  Settings.swift
//  Finances
//
//  Created by Martin Lanius on 01.05.25.
//

import Foundation
import SwiftData

@Model
final class Settings: ObservableObject {
    var themeMode: String = "system"
    var backgroundColor: String = "#FFFFFF"

    init(themeMode: String, backgroundColor: String) {
        self.themeMode = themeMode
        self.backgroundColor = backgroundColor
    }
}
