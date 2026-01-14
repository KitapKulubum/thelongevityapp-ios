//
//  AgeStore.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation
import SwiftUI

@MainActor
final class AgeStore: ObservableObject {
    // Legacy properties (kept for backward compatibility)
    @Published var state: BiologicalAgeState?
    @Published var today: TodayEntry?
    
    // New properties for Insights
    @Published var profileChronologicalAgeYears: Double?
    @Published var currentBiologicalAgeYears: Double?
    @Published var agingDebtYears: Double?
    
    // Streak values from backend - date-based and consecutive
    // Frontend does NOT calculate these - they come from backend API responses
    // Backend calculates streaks based on consecutive days, not check-in count
    @Published var rejuvenationStreakDays: Int = 0  // From backend: consecutive days with biological age decrease
    @Published var accelerationStreakDays: Int = 0  // From backend: consecutive days with biological age increase
    @Published var totalRejuvenationDays: Int = 0
    @Published var totalAccelerationDays: Int = 0
    @Published var todayDeltaYears: Double?
    @Published var todayReasons: [String] = []
    @Published var trendPoints: [TrendPoint] = []
    @Published var selectedRange: TrendRange = .monthly
    
    @Published var isLoading: Bool = false
    @Published var lastError: Error?
    
    // Updated to use new summary endpoint (auth token based)
    func loadSummary() async {
        isLoading = true
        lastError = nil
        
        do {
            let summary = try await APIClient.shared.getSummary()
            updateFromSummary(summary)
        } catch {
            print("[AgeStore] Failed to load summary: \(error)")
            lastError = error
        }
        
        isLoading = false
    }
    
    // Legacy methods - deprecated, use loadSummary instead
    @available(*, deprecated, message: "Use loadSummary instead")
    func loadState(userId: String) async {
        await loadSummary()
    }
    
    @available(*, deprecated, message: "Trend data now comes from summary")
    func loadTrend(userId: String, range: TrendRange) async {
        // No-op: trend data is now part of summary
        print("[AgeStore] loadTrend is deprecated. Trend data comes from summary.")
    }
    
    @available(*, deprecated, message: "Use loadSummary instead")
    func refreshAll(userId: String) async {
        await loadSummary()
    }
    
    @available(*, deprecated, message: "Use loadSummary instead")
    func refresh(userId: String, chronologicalAgeYears: Int) async {
        await loadSummary()
    }
    
    private func updateFromSummary(_ summary: StatsSummaryResponse) {
        print("[AgeStore] Updating from summary:")
        print("  - Biological age: \(summary.state.currentBiologicalAgeYears ?? summary.state.chronologicalAgeYears)")
        currentBiologicalAgeYears = summary.state.currentBiologicalAgeYears
        profileChronologicalAgeYears = summary.state.chronologicalAgeYears
        agingDebtYears = summary.state.agingDebtYears
        
        // Streak values from backend - date-based and consecutive (not calculated locally)
        rejuvenationStreakDays = summary.state.rejuvenationStreakDays
        accelerationStreakDays = summary.state.accelerationStreakDays
        totalRejuvenationDays = summary.state.totalRejuvenationDays
        totalAccelerationDays = summary.state.totalAccelerationDays
        
        // Update legacy state for backward compatibility
        // Use chronological age as fallback for optional biological age fields
        let baselineBioAge = summary.state.baselineBiologicalAgeYears ?? summary.state.chronologicalAgeYears
        let currentBioAge = summary.state.currentBiologicalAgeYears ?? summary.state.chronologicalAgeYears
        state = BiologicalAgeState(
            chronologicalAgeYears: summary.state.chronologicalAgeYears,
            baselineBiologicalAgeYears: baselineBioAge,
            currentBiologicalAgeYears: currentBioAge,
            agingDebtYears: summary.state.agingDebtYears,
            rejuvenationStreakDays: summary.state.rejuvenationStreakDays,
            accelerationStreakDays: summary.state.accelerationStreakDays,
            totalRejuvenationDays: summary.state.totalRejuvenationDays,
            totalAccelerationDays: summary.state.totalAccelerationDays
        )
        
        print("[AgeStore] Summary updated successfully.")
    }
    
    func submitDailyUpdate(_ requestBody: DailyUpdateRequest) async {
        isLoading = true
        lastError = nil
        
        print("[AgeStore] Submitting daily update...")
        
        do {
            // Convert DailyUpdateRequest to DailySubmitRequest (remove date field - backend computes it)
            let metrics = DailyMetricsPayload(
                sleepHours: requestBody.metrics.sleepHours,
                steps: requestBody.metrics.steps,
                vigorousMinutes: requestBody.metrics.vigorousMinutes,
                processedFoodScore: requestBody.metrics.processedFoodScore,
                alcoholUnits: requestBody.metrics.alcoholUnits,
                stressLevel: requestBody.metrics.stressLevel,
                lateCaffeine: requestBody.metrics.lateCaffeine,
                screenLate: requestBody.metrics.screenLate,
                bedtimeHour: requestBody.metrics.bedtimeHour
            )
            
            let submitRequest = DailySubmitRequest(metrics: metrics)
            let result = try await APIClient.shared.postDaily(submitRequest)
            
            print("[AgeStore] Daily update succeeded!")
            print("[AgeStore] Streak from backend: \(result.state.rejuvenationStreakDays)")
            
            // Update state from DailyResultDTO
            updateFromDailyResult(result)
            
            // Also refresh summary to ensure all data is in sync
            await loadSummary()
            
            isLoading = false
            print("[AgeStore] Daily update completed successfully")
            
        } catch {
            print("[AgeStore] Daily update failed: \(error)")
            lastError = error
            isLoading = false
        }
    }
    
    // Helper method to update all properties from DailyResultDTO
    // Note: Streak values come from backend - date-based and consecutive
    // Backend calculates: today = lastCheckInDate + 1 day → streak + 1
    //                     today > lastCheckInDate + 1 day → streak = 1 (reset)
    func updateFromDailyResult(_ result: DailyResultDTO) {
        print("[AgeStore] Updating from DailyResultDTO:")
        print("  - State biological: \(result.state.currentBiologicalAgeYears ?? 0)")
        print("  - State aging debt: \(result.state.agingDebtYears)")
        print("  - State rejuvenation streak: \(result.state.rejuvenationStreakDays)")
        print("  - State acceleration streak: \(result.state.accelerationStreakDays)")
        
        // Update state from DailyResultDTO
        state = result.state
        today = result.today
        
        // Update published properties for UI
        currentBiologicalAgeYears = result.state.currentBiologicalAgeYears
        agingDebtYears = result.state.agingDebtYears
        
        // Streak values from backend - date-based and consecutive (not calculated locally)
        rejuvenationStreakDays = result.state.rejuvenationStreakDays
        accelerationStreakDays = result.state.accelerationStreakDays
        totalRejuvenationDays = result.state.totalRejuvenationDays
        totalAccelerationDays = result.state.totalAccelerationDays
        
        // Update today's delta and reasons if available
        if let todayEntry = result.today {
            todayDeltaYears = todayEntry.deltaYears
            todayReasons = todayEntry.reasons
        }
    }
    
    // Legacy method for AgeStateResponse (kept for backward compatibility if needed)
    private func updateFromResponse(_ response: AgeStateResponse) {
        print("[AgeStore] Updating from AgeStateResponse (legacy):")
        print("  - Profile chronological: \(response.profile.chronologicalAgeYears)")
        print("  - Profile baseline: \(response.profile.baselineBiologicalAgeYears)")
        print("  - State biological: \(response.state.currentBiologicalAgeYears)")
        print("  - State aging debt: \(response.state.agingDebtYears)")
        print("  - State rejuvenation streak: \(response.state.rejuvenationStreakDays)")
        print("  - State acceleration streak: \(response.state.accelerationStreakDays)")
        
        profileChronologicalAgeYears = response.profile.chronologicalAgeYears
        currentBiologicalAgeYears = response.state.currentBiologicalAgeYears
        agingDebtYears = response.state.agingDebtYears
        
        // Streak values from backend - date-based and consecutive (not calculated locally)
        rejuvenationStreakDays = response.state.rejuvenationStreakDays
        accelerationStreakDays = response.state.accelerationStreakDays
        totalRejuvenationDays = response.state.totalRejuvenationDays
        totalAccelerationDays = response.state.totalAccelerationDays
        
        // Update today entry if available
        if let today = response.today {
            todayDeltaYears = today.deltaYears
            todayReasons = today.reasons
            print("  - Today delta: \(today.deltaYears)")
            print("  - Today reasons: \(today.reasons)")
        } else {
            // If no today entry, don't clear old one if we want to keep it visible
            // or clear it if it's a fresh state load
            print("  - No 'today' entry in response.")
        }
            
            // Update legacy state
            // Use chronological age as fallback for optional biological age fields
            let baselineBioAge = response.profile.baselineBiologicalAgeYears
            let currentBioAge = response.state.currentBiologicalAgeYears
            state = BiologicalAgeState(
                chronologicalAgeYears: response.profile.chronologicalAgeYears,
                baselineBiologicalAgeYears: baselineBioAge,
                currentBiologicalAgeYears: currentBioAge,
                agingDebtYears: response.state.agingDebtYears,
                rejuvenationStreakDays: response.state.rejuvenationStreakDays,
                accelerationStreakDays: response.state.accelerationStreakDays,
                totalRejuvenationDays: response.state.totalRejuvenationDays,
                totalAccelerationDays: response.state.totalAccelerationDays
            )
            
        print("[AgeStore] Properties updated successfully. UI should refresh.")
    }
}
