//
//  ScoreViewModel.swift
//  thelongevityapp
//
//  Created on 24.12.2025.
//

import Foundation
import SwiftUI

@MainActor
final class ScoreViewModel: ObservableObject {
    @Published var chronologicalAgeYears: Double = 0
    @Published var biologicalAgeYears: Double = 0
    @Published var agingDebtYears: Double = 0
    
    // Streak values from backend - date-based and consecutive
    // Frontend does NOT calculate these - they come from backend API responses
    // Backend calculates streaks based on consecutive days, not check-in count
    @Published var rejuvenationStreakDays: Int = 0  // From backend: consecutive days with biological age decrease
    @Published var accelerationStreakDays: Int = 0  // From backend: consecutive days with biological age increase
    @Published var totalRejuvenationDays: Int = 0
    @Published var totalAccelerationDays: Int = 0
    
    @Published var todayScore: Double?
    @Published var todayDeltaYears: Double?
    
    @Published var weeklyHistory: [HistoryPoint] = []
    @Published var monthlyHistory: [HistoryPoint] = []
    @Published var yearlyHistory: [HistoryPoint] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {}
    
    func fetchSummary() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let summary = try await APIClient.shared.getSummary()
            apply(summary)
        } catch {
            errorMessage = error.localizedDescription
            print("[ScoreViewModel] Failed to fetch summary: \(error)")
        }
        
        isLoading = false
    }
    
    func apply(_ summary: StatsSummaryResponse) {
        print("[ScoreViewModel] Applying summary - userId: \(summary.userId), biologicalAge: \(summary.state.currentBiologicalAgeYears ?? summary.state.chronologicalAgeYears), agingDebt: \(summary.state.agingDebtYears)")
        // Chronological age is fixed, sourced from backend only.
        chronologicalAgeYears = summary.state.chronologicalAgeYears
        biologicalAgeYears = summary.state.currentBiologicalAgeYears ?? summary.state.chronologicalAgeYears
        agingDebtYears = summary.state.agingDebtYears
        
        // Streak values from backend - date-based and consecutive (not calculated locally)
        rejuvenationStreakDays = summary.state.rejuvenationStreakDays
        accelerationStreakDays = summary.state.accelerationStreakDays
        totalRejuvenationDays = summary.state.totalRejuvenationDays
        totalAccelerationDays = summary.state.totalAccelerationDays
        
        todayScore = summary.today?.score
        todayDeltaYears = summary.today?.deltaYears
        
        weeklyHistory = summary.weeklyHistory
        monthlyHistory = summary.monthlyHistory
        yearlyHistory = summary.yearlyHistory
    }
}

