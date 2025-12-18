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
    
    func loadState(userId: String) async {
        isLoading = true
        lastError = nil
        
        let result: Result<AgeStateResponse, Error> = await withCheckedContinuation { continuation in
            LongevityAPI.shared.fetchAgeState(userId: userId) { response in
                continuation.resume(returning: response)
            }
        }
        
        switch result {
        case .success(let response):
            updateFromResponse(response)
        case .failure(let error):
            print("[AgeStore] Failed to load state: \(error)")
            lastError = error
        }
        
        isLoading = false
    }
    
    func loadTrend(userId: String, range: TrendRange) async {
        // Don't set isLoading here to avoid conflicts with other operations
        let previousError = lastError
        
        let result: Result<TrendResponse, Error> = await withCheckedContinuation { continuation in
            LongevityAPI.shared.fetchTrend(userId: userId, range: range) { response in
                continuation.resume(returning: response)
            }
        }
        
        switch result {
        case .success(let response):
            trendPoints = response.points
            // Clear error only if it was set by a previous trend load
            if previousError != nil && lastError != nil {
                lastError = nil
            }
        case .failure(let error):
            print("[AgeStore] Failed to load trend: \(error)")
            // Only set error if no other operation is in progress
            if !isLoading {
            lastError = error
            }
        }
    }
    
    func refreshAll(userId: String) async {
        await loadState(userId: userId)
        await loadTrend(userId: userId, range: selectedRange)
    }
    
    // Legacy method for backward compatibility
    func refresh(userId: String, chronologicalAgeYears: Int) async {
        await loadState(userId: userId)
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
