//
//  LanguageManager.swift
//  thelongevityapp
//
//  Manages app language and locale settings
//

import Foundation
import SwiftUI

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String = "English"
    @AppStorage("appLanguage") private var storedLanguage: String = "English"
    
    private let languageToLocale: [String: String] = [
        "English": "en_US",
        "Türkçe": "tr_TR",
        "Español": "es_ES",
        "Français": "fr_FR",
        "Deutsch": "de_DE"
    ]
    
    private init() {
        currentLanguage = storedLanguage
    }
    
    var currentLocale: Locale {
        guard let localeIdentifier = languageToLocale[currentLanguage] else {
            return Locale(identifier: "en_US")
        }
        return Locale(identifier: localeIdentifier)
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        storedLanguage = language
    }
    
    func dateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = currentLocale
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    func monthFormatter(style: DateFormatter.Style = .short) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = "MMM" // Abbreviated month
        return formatter
    }
}

