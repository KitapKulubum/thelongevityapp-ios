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
    
    // Summary update trigger - increments on every summary update to ensure onChange fires
    @Published var summaryUpdateTrigger: Int = 0
    
    // Subscription status
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    
    enum SubscriptionStatus {
        case active
        case expired
        case inactive
        case unknown
        
        var isActive: Bool {
            return self == .active
        }
    }
    
    // User profile info
    @Published var userFirstName: String?
    @Published var userLastName: String?
    @Published var userChronologicalAge: Double?
    @Published var userTimezone: String?  // IANA timezone identifier
    
    private let userDefaults = UserDefaults.standard
    private var hasCompletedOnboardingKey: String {
        "hasCompletedOnboarding_\(userId)"
    }
    private var lastDailyDateSubmittedKey: String {
        "lastDailyDateSubmitted_\(userId)"
    }
    private var cachedSummaryKey: String {
        "cachedSummary_\(userId)"
    }
    private let userFirstNameKey = "userFirstName"
    private let userLastNameKey = "userLastName"
    private let userChronologicalAgeKey = "userChronologicalAge"
    private let userTimezoneKey = "userTimezone"
    
    init(userId: String) {
        self.userId = userId
        // Load user profile from UserDefaults
        self.userFirstName = userDefaults.string(forKey: userFirstNameKey)
        self.userLastName = userDefaults.string(forKey: userLastNameKey)
        if userDefaults.object(forKey: userChronologicalAgeKey) != nil {
            self.userChronologicalAge = userDefaults.double(forKey: userChronologicalAgeKey)
        }
        self.userTimezone = userDefaults.string(forKey: userTimezoneKey)
    }
    
    func updateUserProfile(firstName: String?, lastName: String?, chronologicalAge: Double?, timezone: String? = nil) {
        userFirstName = firstName
        userLastName = lastName
        userChronologicalAge = chronologicalAge
        if let timezone = timezone {
            userTimezone = timezone
        }
        
        if let firstName = firstName {
            userDefaults.set(firstName, forKey: userFirstNameKey)
        } else {
            userDefaults.removeObject(forKey: userFirstNameKey)
        }
        
        if let lastName = lastName {
            userDefaults.set(lastName, forKey: userLastNameKey)
        } else {
            userDefaults.removeObject(forKey: userLastNameKey)
        }
        
        if let age = chronologicalAge {
            userDefaults.set(age, forKey: userChronologicalAgeKey)
        } else {
            userDefaults.removeObject(forKey: userChronologicalAgeKey)
        }
        
        if let timezone = timezone {
            userDefaults.set(timezone, forKey: userTimezoneKey)
        }
    }
    
    /// Detects current device timezone and updates backend if different
    /// This function never throws - timezone sync failures should not block login or app usage
    func syncTimezoneIfNeeded() async {
        let deviceTimezone = TimeZone.current.identifier
        
        // If timezone hasn't changed, no need to update
        if let storedTimezone = userTimezone, storedTimezone == deviceTimezone {
            return
        }
        
        // Update backend - but don't block if it fails (timeout, network error, etc.)
        do {
            _ = try await APIClient.shared.patchProfile(timezone: deviceTimezone)
            await MainActor.run {
                updateUserProfile(
                    firstName: userFirstName,
                    lastName: userLastName,
                    chronologicalAge: userChronologicalAge,
                    timezone: deviceTimezone
                )
                print("[AppState] Timezone updated to: \(deviceTimezone)")
            }
        } catch let error as APIError {
            // Check if it's a network/timeout error - these are non-critical
            if case .networkError = error {
                print("[AppState] Timezone update failed (network/timeout): \(error.localizedDescription). Continuing without timezone update.")
                // Store timezone locally anyway so we don't retry immediately
                await MainActor.run {
                    updateUserProfile(
                        firstName: userFirstName,
                        lastName: userLastName,
                        chronologicalAge: userChronologicalAge,
                        timezone: deviceTimezone
                    )
                }
            } else {
                print("[AppState] Failed to update timezone: \(error). Continuing without timezone update.")
            }
            // Never throw - timezone update failure shouldn't block app usage
        } catch {
            print("[AppState] Failed to update timezone: \(error). Continuing without timezone update.")
            // Never throw - timezone update failure shouldn't block app usage
        }
    }
    
    func bootstrap(requireBackend: Bool = false) async throws {
        // Load flags from UserDefaults (user-specific keys)
        // Note: This is a fallback - backend response should override this
        hasCompletedOnboarding = userDefaults.bool(forKey: hasCompletedOnboardingKey)
        lastDailyDateSubmitted = userDefaults.string(forKey: lastDailyDateSubmittedKey)
        
        // Load cached summary if available
        if let summaryData = userDefaults.data(forKey: cachedSummaryKey),
           let decoded = try? JSONDecoder().decode(StatsSummaryResponse.self, from: summaryData) {
            summary = decoded
            
            // Update chronological age from cached summary if not already set from profile
            if userChronologicalAge == nil || userChronologicalAge == 0 {
                updateUserProfile(
                    firstName: userFirstName,
                    lastName: userLastName,
                    chronologicalAge: decoded.state.chronologicalAgeYears
                )
            }
        }
        
        // Sync timezone with backend if needed (before fetching summary)
        // This never throws - timeout/network errors are handled gracefully
        await syncTimezoneIfNeeded()
        
        // Load subscription status from /api/auth/me
        // For now, set all users to active by default (will be fixed before prod)
        subscriptionStatus = .active
        
        // Fetch fresh summary from backend (requires auth token)
        // Ensure token is available before making the request
        do {
            // Pre-check token availability with retry (increased retries and delay)
            var token: String?
            var retryCount = 0
            while token == nil && retryCount < 5 {
                do {
                    token = try await AuthManager.shared.getIDToken()
                    print("[AppState] Token obtained successfully on attempt \(retryCount + 1)")
                } catch {
                    retryCount += 1
                    if retryCount < 5 {
                        // Wait a bit before retry (increasing delay)
                        let delay = UInt64(200_000_000 * retryCount) // 0.2s, 0.4s, 0.6s, 0.8s
                        try await Task.sleep(nanoseconds: delay)
                        print("[AppState] Token fetch failed, retrying (\(retryCount)/5)... Error: \(error)")
                    } else {
                        print("[AppState] Token fetch failed after 5 retries: \(error)")
                        throw error
                    }
                }
            }
            
            let freshSummary = try await APIClient.shared.getSummary()
            userId = freshSummary.userId
            summary = freshSummary
            saveCachedSummary(freshSummary)
            
            // Backend is the source of truth - use hasCompletedOnboarding from summary response
            // Use computed property that handles both explicit field and inferred status
            setOnboardingStatus(freshSummary.onboardingStatus)
            print("[AppState] Onboarding status from summary: \(freshSummary.onboardingStatus) (hasCompletedOnboarding field: \(freshSummary.hasCompletedOnboarding?.description ?? "nil"))")
            
            // Update chronological age from summary if not already set from profile
            if userChronologicalAge == nil || userChronologicalAge == 0 {
                updateUserProfile(
                    firstName: userFirstName,
                    lastName: userLastName,
                    chronologicalAge: freshSummary.state.chronologicalAgeYears
                )
            }
        } catch let error as APIError {
            print("[AppState] Failed to fetch summary: \(error)")
            
            // If it's a subscription required error (403 with subscription_required), use cached data and allow onboarding
            if case .httpError(_, let statusCode, let responseBody) = error {
                if statusCode == 403 {
                    let lowercased = responseBody.lowercased()
                    if lowercased.contains("subscription_required") || 
                       lowercased.contains("subscription required") ||
                       lowercased.contains("\"code\":\"subscription_required\"") {
                        print("[AppState] Subscription required during bootstrap, using cached data and allowing onboarding")
                        // Keep existing cached summary if available, allow onboarding
                        return
                    }
                }
            }
            
            // If it's a missingAuthToken error and backend is not required, use cached data
            if case .missingAuthToken = error {
                if !requireBackend {
                    print("[AppState] Missing auth token during bootstrap, using cached data")
                    // Keep existing cached summary if available
                    return
                }
            }
            
            // If it's a network/timeout error and backend is not required, use cached data
            if case .networkError = error {
                if !requireBackend {
                    print("[AppState] Network error during bootstrap, using cached data")
                    // Keep existing cached summary if available
                    return
                }
            }
            
            // If backend is required (e.g., during login), throw the error
            if requireBackend {
                throw error
            }
            // Otherwise, keep cached summary if fetch fails (e.g., app restart)
        } catch {
            print("[AppState] Failed to fetch summary: \(error)")
            // If backend is required (e.g., during login), throw the error
            if requireBackend {
                throw error
            }
            // Otherwise, keep cached summary if fetch fails (e.g., app restart)
        }
        
        // Set default tab based on onboarding status
        if !hasCompletedOnboarding {
            activeTab = .chat
        }
    }
    
    func setOnboardingStatus(_ completed: Bool) {
        hasCompletedOnboarding = completed
        userDefaults.set(completed, forKey: hasCompletedOnboardingKey)
        print("[AppState] Onboarding status set to: \(completed)")
    }
    
    func markOnboardingComplete() {
        setOnboardingStatus(true)
    }
    
    func updateLastDailyDate(_ date: String) {
        lastDailyDateSubmitted = date
        userDefaults.set(date, forKey: lastDailyDateSubmittedKey)
    }
    
    func updateSummary(_ newSummary: StatsSummaryResponse) {
        let oldTodayDelta = summary?.today?.deltaYears
        let newTodayDelta = newSummary.today?.deltaYears
        
        summary = newSummary
        saveCachedSummary(newSummary)
        userId = newSummary.userId
        
        // Update onboarding status from summary (backend is source of truth)
        setOnboardingStatus(newSummary.onboardingStatus)
        
        // Increment trigger to ensure onChange fires even if summary object reference doesn't change
        summaryUpdateTrigger += 1
        
        print("[AppState] Summary updated - userId: \(newSummary.userId), biologicalAge: \(newSummary.state.currentBiologicalAgeYears ?? newSummary.state.chronologicalAgeYears), agingDebt: \(newSummary.state.agingDebtYears), todayScore: \(newSummary.today?.score ?? 0)")
        print("[AppState] Today's delta: \(oldTodayDelta?.description ?? "nil") -> \(newTodayDelta?.description ?? "nil")")
        print("[AppState] Summary update trigger: \(summaryUpdateTrigger)")
        print("[AppState] Summary has \(newSummary.weeklyHistory.count) weekly, \(newSummary.monthlyHistory.count) monthly, \(newSummary.yearlyHistory.count) yearly history points")
        print("[AppState] Onboarding status updated from summary: \(newSummary.onboardingStatus)")
    }
    
    private func saveCachedSummary(_ summary: StatsSummaryResponse) {
        if let encoded = try? JSONEncoder().encode(summary) {
            userDefaults.set(encoded, forKey: cachedSummaryKey)
        }
    }
    
    /// Checks if daily check-in is already completed today based on backend data
    /// Backend is the source of truth - uses summary.today field
    var isTodaySubmitted: Bool {
        // Backend is source of truth - if summary.today exists, check-in is completed
        return summary?.today != nil
    }
    
    func updateSubscriptionStatus(from response: AuthProfileResponse) {
        // TODO: Subscription status will be updated when backend adds subscription field to AuthProfileResponse
        // For now, keep current status or set to inactive
        self.subscriptionStatus = .inactive
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
