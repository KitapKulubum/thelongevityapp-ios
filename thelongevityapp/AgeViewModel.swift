//
//  AgeViewModel.swift
//  thelongevityapp
//
//  Created by ChatGPT on 12.15.2025.
//

import Foundation
import SwiftUI

@MainActor
final class AgeViewModel: ObservableObject {
    @Published var state: BiologicalAgeState?
    @Published var today: DailyAgeEntry?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func refresh() async {
        isLoading = true
        errorMessage = nil
        
        guard let userId = AuthManager.shared.userId else {
            errorMessage = "User ID is missing. Please sign in."
            isLoading = false
            return
        }
        
        let result: Result<AgeStateResponse, Error> = await withCheckedContinuation { continuation in
            LongevityAPI.shared.fetchAgeState(userId: userId) { response in
                continuation.resume(returning: response)
            }
        }
        
        switch result {
        case .success(let response):
            // Update legacy state for backward compatibility
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
            // Note: today is no longer in the new response structure
            today = nil
        case .failure(let error):
            errorMessage = "Network error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

