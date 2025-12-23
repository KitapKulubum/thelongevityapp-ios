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
    
    @Published var rejuvenationStreakDays: Int = 0
    @Published var accelerationStreakDays: Int = 0
    @Published var totalRejuvenationDays: Int = 0
    @Published var totalAccelerationDays: Int = 0
    
    @Published var todayScore: Int?
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
        // Chronological age is fixed, sourced from backend only.
        chronologicalAgeYears = summary.state.chronologicalAgeYears
        biologicalAgeYears = summary.state.currentBiologicalAgeYears
        agingDebtYears = summary.state.agingDebtYears
        
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

