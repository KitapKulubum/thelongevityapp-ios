//
//  TrendsViewModel.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import Foundation
import SwiftUI

@MainActor
class TrendsViewModel: ObservableObject {
    @Published var selectedPeriod: Period = .weekly
    @Published var trendsResponse: TrendsResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // Computed property for current bucket based on selected period
    var currentBucket: TrendBucket? {
        guard let response = trendsResponse else { return nil }
        
        switch selectedPeriod {
        case .weekly:
            return response.weekly
        case .monthly:
            return response.monthly
        case .yearly:
            return response.yearly
        }
    }
    
    // Fetch trends once on appear, store it, do not refetch on tab switch
    func loadTrends() async {
        guard trendsResponse == nil else { return } // Already loaded
        
        isLoading = true
        errorMessage = nil
        
        do {
            trendsResponse = try await apiClient.fetchTrends()
        } catch {
            errorMessage = "Failed to load trends. Please try again."
            print("[TrendsViewModel] Trends fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    // Manual retry
    func retry() async {
        trendsResponse = nil
        await loadTrends()
    }
    
    // Helper to get not enough data message
    func getNotEnoughDataMessage(for bucket: TrendBucket, period: Period) -> String {
        switch period {
        case .weekly:
            return "Not enough data for a weekly trend yet. Keep logging your daily check-ins."
        case .monthly:
            return "Not enough data for a monthly trend yet. Keep logging your daily check-ins."
        case .yearly:
            if bucket.projection == true && bucket.value != nil {
                return "Not enough data for a yearly trend yet. Showing a projected yearly trend based on recent check-ins."
            } else if bucket.projection == true {
                return "Not enough data for a yearly trend yet. Keep logging your daily check-ins."
            } else {
                return "Not enough data for a yearly trend yet. Keep logging your daily check-ins."
            }
        }
    }
    
    // Format trend value
    func formatTrendValue(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        return String(format: "%.2fy", value)
    }
    
    // Get trend label
    func getTrendLabel(for bucket: TrendBucket) -> String {
        guard let value = bucket.value else { return "No data" }
        
        if bucket.projection == true {
            return "Projected"
        } else if value < 0 {
            return "Rejuvenation"
        } else if value > 0 {
            return "Aging"
        } else {
            return "Stable"
        }
    }
}

