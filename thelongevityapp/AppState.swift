//
//  AppState.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import Foundation
import SwiftUI

enum Tab: String, CaseIterable {
    case chat = "chat"
    case score = "score"
    case profile = "profile"
}

@MainActor
class AppState: ObservableObject {
    @Published var userId: String
    @Published var hasCompletedOnboarding: Bool = false
    @Published var lastDailyDateSubmitted: String?
    @Published var summary: StatsSummaryResponse?
    @Published var activeTab: Tab = .chat
    
    private let userDefaults = UserDefaults.standard
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let lastDailyDateSubmittedKey = "lastDailyDateSubmitted"
    private let cachedSummaryKey = "cachedSummary"
    
    init(userId: String) {
        self.userId = userId
    }
    
    func bootstrap() async {
        // Load flags from UserDefaults
        hasCompletedOnboarding = userDefaults.bool(forKey: hasCompletedOnboardingKey)
        lastDailyDateSubmitted = userDefaults.string(forKey: lastDailyDateSubmittedKey)
        
        // Load cached summary if available
        if let summaryData = userDefaults.data(forKey: cachedSummaryKey),
           let decoded = try? JSONDecoder().decode(StatsSummaryResponse.self, from: summaryData) {
            summary = decoded
        }
        
        // Fetch fresh summary from backend (requires auth token)
        do {
            let freshSummary = try await APIClient.shared.getSummary()
            userId = freshSummary.userId
            summary = freshSummary
            saveCachedSummary(freshSummary)
        } catch {
            print("[AppState] Failed to fetch summary: \(error)")
            // Keep cached summary if fetch fails (e.g., not signed in yet)
        }
        
        // Set default tab based on onboarding status
        if !hasCompletedOnboarding {
            activeTab = .chat
        }
    }
    
    func markOnboardingComplete() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: hasCompletedOnboardingKey)
    }
    
    func updateLastDailyDate(_ date: String) {
        lastDailyDateSubmitted = date
        userDefaults.set(date, forKey: lastDailyDateSubmittedKey)
    }
    
    func updateSummary(_ newSummary: StatsSummaryResponse) {
        summary = newSummary
        saveCachedSummary(newSummary)
    }
    
    private func saveCachedSummary(_ summary: StatsSummaryResponse) {
        if let encoded = try? JSONEncoder().encode(summary) {
            userDefaults.set(encoded, forKey: cachedSummaryKey)
        }
    }
    
    var isTodaySubmitted: Bool {
        guard let lastDate = lastDailyDateSubmitted else { return false }
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        return lastDate == today
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
