//
//  AgeStore.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation
import SwiftUI

// Type aliases for cleaner API
typealias AgeState = BiologicalAgeState
typealias DailyResult = DailyAgeEntry

@MainActor
final class AgeStore: ObservableObject {
    // Legacy properties (kept for backward compatibility)
    @Published var state: AgeState?
    @Published var today: DailyResult?
    
    // New properties for Insights
    @Published var profileChronologicalAgeYears: Double?
    @Published var currentBiologicalAgeYears: Double?
    @Published var agingDebtYears: Double?
    @Published var rejuvenationStreakDays: Int = 0
    @Published var accelerationStreakDays: Int = 0
    @Published var totalRejuvenationDays: Int = 0
    @Published var totalAccelerationDays: Int = 0
    @Published var todayDeltaYears: Double?
    @Published var todayReasons: [String] = []
    @Published var trendPoints: [TrendPoint] = []
    @Published var selectedRange: TrendRange = .monthly
    
    @Published var isLoading: Bool = false
    @Published var lastError: Error?
    
    // Updated to use new summary endpoint
    func loadSummary(userId: String) async {
        isLoading = true
        lastError = nil
        
        do {
            let summary = try await APIClient.shared.getSummary(userId: userId)
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
        await loadSummary(userId: userId)
    }
    
    @available(*, deprecated, message: "Trend data now comes from summary")
    func loadTrend(userId: String, range: TrendRange) async {
        // No-op: trend data is now part of summary
        print("[AgeStore] loadTrend is deprecated. Trend data comes from summary.")
    }
    
    @available(*, deprecated, message: "Use loadSummary instead")
    func refreshAll(userId: String) async {
        await loadSummary(userId: userId)
    }
    
    @available(*, deprecated, message: "Use loadSummary instead")
    func refresh(userId: String, chronologicalAgeYears: Int) async {
        await loadSummary(userId: userId)
    }
    
    private func updateFromSummary(_ summary: SummaryDTO) {
        print("[AgeStore] Updating from summary:")
        if let bioAge = summary.biologicalAge {
            print("  - Biological age: \(bioAge)")
            currentBiologicalAgeYears = bioAge
        }
        if let bao = summary.BAOYears {
            print("  - BAO years: \(bao)")
        }
        if let ema7 = summary.ema7 {
            print("  - EMA7: \(ema7)")
        }
        if let ema30 = summary.ema30 {
            print("  - EMA30: \(ema30)")
        }
        if let trend = summary.trendLabel {
            print("  - Trend: \(trend)")
        }
        if let risks = summary.topRiskSystems {
            print("  - Top risk systems: \(risks)")
        }
        
        // Update legacy state for backward compatibility
        if let bioAge = summary.biologicalAge {
            state = BiologicalAgeState(
                chronologicalAgeYears: bioAge, // Approximate - summary doesn't have CA
                baselineBiologicalAgeYears: bioAge,
                currentBiologicalAgeYears: bioAge,
                agingDebtYears: 0, // Summary doesn't provide this
                rejuvenationStreakDays: 0,
                accelerationStreakDays: 0,
                totalRejuvenationDays: 0,
                totalAccelerationDays: 0
            )
        }
        
        print("[AgeStore] Summary updated successfully.")
    }
    
    func submitDailyUpdate(_ requestBody: DailyUpdateRequest) async {
        isLoading = true
        lastError = nil
        
        print("[AgeStore] Submitting daily update...")
        
        let result: Result<AgeStateResponse, Error> = await withCheckedContinuation { continuation in
            LongevityAPI.shared.submitDailyUpdate(requestBody) { response in
                continuation.resume(returning: response)
            }
        }
        
        switch result {
        case .success(let response):
            print("[AgeStore] Daily update succeeded!")
            updateFromResponse(response)
            
            // Refresh trend after update (don't fail the whole operation if trend fails)
            if let userId = AuthManager.shared.userId {
                // Load trend without affecting isLoading or lastError
                let trendResult: Result<TrendResponse, Error> = await withCheckedContinuation { continuation in
                    LongevityAPI.shared.fetchTrend(userId: userId, range: selectedRange) { response in
                        continuation.resume(returning: response)
                    }
                }
                
                switch trendResult {
                case .success(let trendResponse):
                    trendPoints = trendResponse.points
                case .failure(let error):
                    print("[AgeStore] Warning: Failed to load trend after daily update: \(error)")
                    // Don't set lastError - daily update was successful
                }
            }
            
            isLoading = false
            print("[AgeStore] Daily update completed successfully")
            
        case .failure(let error):
            print("[AgeStore] Daily update failed: \(error)")
            lastError = error
            isLoading = false
        }
    }
    
    // Helper method to update all properties from response
    private func updateFromResponse(_ response: AgeStateResponse) {
        print("[AgeStore] Updating from response:")
        print("  - Profile chronological: \(response.profile.chronologicalAgeYears)")
        print("  - Profile baseline: \(response.profile.baselineBiologicalAgeYears)")
        print("  - State biological: \(response.state.currentBiologicalAgeYears)")
        print("  - State aging debt: \(response.state.agingDebtYears)")
        print("  - State rejuvenation streak: \(response.state.rejuvenationStreakDays)")
        
        // Ensure UI updates on main thread (though @MainActor handles this, being explicit doesn't hurt)
            profileChronologicalAgeYears = response.profile.chronologicalAgeYears
            currentBiologicalAgeYears = response.state.currentBiologicalAgeYears
            agingDebtYears = response.state.agingDebtYears
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
            state = BiologicalAgeState(
                chronologicalAgeYears: response.profile.chronologicalAgeYears,
                baselineBiologicalAgeYears: response.profile.baselineBiologicalAgeYears,
                currentBiologicalAgeYears: response.state.currentBiologicalAgeYears,
                agingDebtYears: response.state.agingDebtYears,
                rejuvenationStreakDays: response.state.rejuvenationStreakDays,
                accelerationStreakDays: response.state.accelerationStreakDays,
                totalRejuvenationDays: response.state.totalRejuvenationDays,
                totalAccelerationDays: response.state.totalAccelerationDays
            )
            
        print("[AgeStore] Properties updated successfully. UI should refresh.")
    }
}
