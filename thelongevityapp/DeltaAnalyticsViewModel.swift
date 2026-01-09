//
//  DeltaAnalyticsViewModel.swift
//  thelongevityapp
//
//  Created on 20.01.2026.
//

import Foundation
import SwiftUI

@MainActor
class DeltaAnalyticsViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Weekly/Monthly state
    @Published var dailyPoints: [DeltaDailyPoint] = []
    @Published var dailySummary: DeltaSummary?
    
    // Yearly state
    @Published var monthlyPoints: [DeltaMonthlyPoint] = []
    @Published var yearlySummary: DeltaSummary?
    
    // Current range
    @Published var currentRange: String = "weekly" {
        didSet {
            loadData(range: currentRange)
        }
    }
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func loadData(range: String) {
        guard ["weekly", "monthly", "yearly"].contains(range) else { return }
        
        Task {
            await fetchDeltaAnalytics(range: range)
        }
    }
    
    private func fetchDeltaAnalytics(range: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getDeltaAnalytics(range: range)
            
            switch response {
            case .weekly(let data):
                self.dailyPoints = data.series
                self.dailySummary = data.summary
                self.monthlyPoints = []
                self.yearlySummary = nil
                
            case .monthly(let data):
                self.dailyPoints = data.series
                self.dailySummary = data.summary
                self.monthlyPoints = []
                self.yearlySummary = nil
                
            case .yearly(let data):
                self.monthlyPoints = data.series
                self.yearlySummary = data.summary
                self.dailyPoints = []
                self.dailySummary = nil
            }
            
            isLoading = false
        } catch let error as APIError {
            isLoading = false
            
            // Provide specific error messages based on error type
            switch error {
            case .httpError(_, let statusCode, _):
                if statusCode == 404 {
                    errorMessage = "Delta analytics endpoint not available yet. Please check backend configuration."
                } else if statusCode >= 500 {
                    errorMessage = "Server error. Please try again later."
                } else {
                    errorMessage = "Couldn't load delta chart"
                }
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            case .invalidResponse:
                errorMessage = "Invalid response from server."
            default:
                errorMessage = "Couldn't load delta chart"
            }
            
            print("[DeltaAnalyticsViewModel] Error fetching delta analytics: \(error)")
        } catch {
            errorMessage = "Couldn't load delta chart"
            isLoading = false
            print("[DeltaAnalyticsViewModel] Error fetching delta analytics: \(error)")
        }
    }
}

