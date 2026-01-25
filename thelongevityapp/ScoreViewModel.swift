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
    @Published var totalRejuvenationDays: Int = 0
    
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
            errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .general)
            print("[ScoreViewModel] Failed to fetch summary: \(error)")
        }
        
        isLoading = false
    }
    
    func apply(_ summary: StatsSummaryResponse) {
        let oldDelta = todayDeltaYears
        print("[ScoreViewModel] Applying summary - userId: \(summary.userId), chronologicalAge: \(summary.state.chronologicalAgeYears), biologicalAge: \(summary.state.currentBiologicalAgeYears ?? summary.state.baselineBiologicalAgeYears ?? summary.state.chronologicalAgeYears), agingDebt: \(summary.state.agingDebtYears)")
        
        // Chronological age is fixed, sourced from backend only.
        // If backend returns 0, it means data hasn't been set yet - keep existing value if it's valid
        if summary.state.chronologicalAgeYears > 0 {
        chronologicalAgeYears = summary.state.chronologicalAgeYears
        } else if chronologicalAgeYears == 0 {
            // If both are 0, this is likely initial state - log warning
            print("[ScoreViewModel] Warning: chronologicalAgeYears is 0 from backend, keeping 0")
        }
        
        // Use currentBiologicalAgeYears if available, otherwise fallback to baselineBiologicalAgeYears, then chronologicalAgeYears
        if let currentBio = summary.state.currentBiologicalAgeYears {
            biologicalAgeYears = currentBio
        } else if let baselineBio = summary.state.baselineBiologicalAgeYears {
            biologicalAgeYears = baselineBio
        } else if chronologicalAgeYears > 0 {
            biologicalAgeYears = chronologicalAgeYears
        } else {
            // If all are 0 or nil, keep existing value or set to 0
            if biologicalAgeYears == 0 {
                print("[ScoreViewModel] Warning: All age values are 0 or nil")
            }
        }
        
        agingDebtYears = summary.state.agingDebtYears
        
        // Streak values from backend - date-based and consecutive (not calculated locally)
        rejuvenationStreakDays = summary.state.rejuvenationStreakDays
        totalRejuvenationDays = summary.state.totalRejuvenationDays
        
        todayScore = summary.today?.score
        todayDeltaYears = summary.today?.deltaYears
        
        if let newDelta = todayDeltaYears, newDelta != oldDelta {
            print("[ScoreViewModel] Today's delta updated: \(oldDelta?.description ?? "nil") -> \(newDelta)")
        }
        
        weeklyHistory = summary.weeklyHistory
        monthlyHistory = summary.monthlyHistory
        yearlyHistory = summary.yearlyHistory
    }
}

