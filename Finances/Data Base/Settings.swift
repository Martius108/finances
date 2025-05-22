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
    
    var themeMode: String
    var backgroundColor: String

    init(themeMode: String = "system", backgroundColor: String = "#FFFFFF") {
        self.themeMode = themeMode
        self.backgroundColor = backgroundColor
    }
}
