//
//  thelongevityappApp.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth

// Stub AppDelegate to satisfy Firebase AppDelegate swizzler warnings in SwiftUI apps.
final class AppDelegate: NSObject, UIApplicationDelegate {}

@main
struct thelongevityappApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root View (Onboarding Gating)
struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appState: AppState
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isBootstrapComplete = false
    @State private var authError: String?
    @State private var authErrorTitle: String = "Login Failed"
    @State private var isAuthenticating = false
    @State private var showSplash = true
    @State private var showPaywall = false
    @State private var isCheckingSubscription = false
    
    init() {
        let userId = AuthManager.shared.uid ?? ""
        _appState = StateObject(wrappedValue: AppState(userId: userId))
    }
    
    var body: some View {
        let isSignedIn = authManager.currentUser != nil
        
        return Group {
            if showSplash {
                // Splash screen (shows on app launch)
                SplashView(shouldDismiss: Binding(
                    get: { !showSplash },
                    set: { newValue in
                        if newValue {
                            // When animation completes, hide splash after fade transition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showSplash = false
                            }
                        }
                    }
                ))
            } else if !isSignedIn {
                AuthLandingView { mode, email, password, firstName, lastName, dateOfBirth in
                    Task {
                        await handleAuth(mode: mode, email: email, password: password, firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth)
                    }
                }
                .overlay(
                    Group {
                        if isAuthenticating {
                            ZStack {
                                Color.black.opacity(0.45).ignoresSafeArea()
                                ProgressView("Connecting...")
                                    .tint(.green)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                )
                .alert(authErrorTitle, isPresented: .constant(authError != nil)) {
                    Button("OK") { 
                        authError = nil
                        authErrorTitle = "Login Failed"
                    }
                } message: {
                    Text(authError ?? "An unknown error occurred")
                }
                } else if !isBootstrapComplete {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .tint(.green)
                }
                .onAppear {
                    Task {
                        do {
                            try await appState.bootstrap(requireBackend: true)
                            await MainActor.run {
                                isBootstrapComplete = true
                            }
                        } catch {
                            print("[RootView] Bootstrap failed: \(error)")
                            // Check if it's an onboarding required error - this is normal for new users
                            if isOnboardingRequiredError(error) {
                                print("[RootView] User needs to complete onboarding (app startup)")
                                await MainActor.run {
                                    // Set onboarding flag to false FIRST, then complete bootstrap
                                    // This ensures view renders onboarding screen immediately
                                    appState.hasCompletedOnboarding = false
                                    // Complete bootstrap in the same update cycle
                                    isBootstrapComplete = true
                                }
                                return
                            }
                            
                            // Check if it's an invalid response error (decoding) - this can happen for new users
                            // But only redirect to onboarding if user hasn't completed it before
                            if isInvalidResponseError(error) {
                                // Check if user has completed onboarding before from UserDefaults (user-specific key)
                                // (This was set from postAuthMe response during login)
                                let userSpecificKey = "hasCompletedOnboarding_\(appState.userId)"
                                let hasCompletedBefore = UserDefaults.standard.bool(forKey: userSpecificKey)
                                if !hasCompletedBefore {
                                    print("[RootView] Invalid response error during app startup, allowing onboarding (new user)")
                                    await MainActor.run {
                                        // Set onboarding flag to false FIRST, then complete bootstrap
                                        // This ensures view renders onboarding screen immediately
                                        appState.setOnboardingStatus(false)
                                        // Complete bootstrap in the same update cycle
                                        isBootstrapComplete = true
                                    }
                                    return
                                } else {
                                    // User has completed onboarding before, but decoding failed
                                    // Try to continue with cached data or show error
                                    print("[RootView] Invalid response error during app startup, but user has completed onboarding - continuing with cached data")
                                    await MainActor.run {
                                        // Keep existing onboarding status from UserDefaults
                                        appState.setOnboardingStatus(true)
                                        // Complete bootstrap in the same update cycle
                                        isBootstrapComplete = true
                                    }
                                    return
                                }
                            }
                            
                            // If backend connection fails, sign out and show login screen
                            await MainActor.run {
                                // Sign out first to update auth state
                                do {
                                    try authManager.signOut()
                                } catch {
                                    print("[RootView] Failed to sign out after bootstrap error: \(error)")
                                }
                                // Set error message to show on login screen
                                authError = getErrorMessage(for: error)
                                // Reset bootstrap state
                                isBootstrapComplete = false
                            }
                        }
                    }
                }
            } else if showPaywall {
                // Show paywall if subscription is required
                PaywallView()
                    .environmentObject(appState)
            } else {
                // Always show MainTabView - onboarding will be handled within AI screen
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionActivated"))) { _ in
            // When subscription is activated, check status and hide paywall
            Task {
                await checkSubscriptionStatus()
            }
        }
        .onChange(of: authManager.currentUser) { oldValue, newValue in
            // When user logs out (currentUser becomes nil), reset bootstrap state
            if newValue == nil && oldValue != nil {
                print("[RootView] User logged out, resetting state")
                isBootstrapComplete = false
                authError = nil
                isAuthenticating = false
            }
        }
    }
    
    private func handleAuth(mode: AuthMode, email: String, password: String, firstName: String? = nil, lastName: String? = nil, dateOfBirth: Date? = nil) async {
        await MainActor.run {
            isAuthenticating = true
            authError = nil
        }
        
        var firebaseAuthSucceeded = false
        
        do {
            // Step 1: Firebase Authentication
            if mode == .signup {
                try await authManager.signUp(email: email, password: password)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
            firebaseAuthSucceeded = true
            
            // Step 2: Get ID Token
            let token = try await authManager.getIDToken()
            
            // Step 3: Verify with backend API (optional - if it fails, use Firebase uid)
            var backendUserId: String? = nil
            var userProfile: AuthProfileResponse.ProfileInfo? = nil
            var hasCompletedOnboarding: Bool? = nil
            do {
                // For signup, include consent versions (backend tracks consent automatically)
                let privacyVersion = mode == .signup ? "1.0" : nil
                let termsVersion = mode == .signup ? "1.0" : nil
                
                let profile = try await APIClient.shared.postAuthMe(
                    idToken: token,
                    firstName: mode == .signup ? firstName : nil,
                    lastName: mode == .signup ? lastName : nil,
                    dateOfBirth: mode == .signup ? dateOfBirth : nil,
                    acceptedPrivacyPolicyVersion: privacyVersion,
                    acceptedTermsVersion: termsVersion
                )
                backendUserId = profile.uid
                userProfile = profile.profile
                hasCompletedOnboarding = profile.hasCompletedOnboarding ?? false
                
                // Handle language preference from backend
                let languageCode = profile.locale ?? profile.profile?.preferredLanguage ?? LanguageManager.shared.getDeviceLanguageCode()
                await MainActor.run {
                    LanguageManager.shared.setLanguageCode(languageCode)
                }
                
                print("[RootView] postAuthMe success - hasCompletedOnboarding: \(profile.hasCompletedOnboarding ?? false), locale: \(profile.locale ?? "nil"), preferredLanguage: \(profile.profile?.preferredLanguage ?? "nil")")
            } catch {
                // If postAuthMe fails (decoding error, etc.), use Firebase uid instead
                print("[RootView] postAuthMe failed, using Firebase uid: \(error)")
                // Continue with Firebase uid - this is OK for new users
            }
            
            // Step 4: Update app state
            await MainActor.run {
                // Use backend uid if available, otherwise use Firebase uid
                if let backendUid = backendUserId {
                    appState.userId = backendUid
                } else if let firebaseUid = authManager.uid {
                    appState.userId = firebaseUid
                }
                
                // Store user profile info in AppState if available
                if let profile = userProfile {
                    appState.updateUserProfile(
                        firstName: profile.firstName,
                        lastName: profile.lastName,
                        chronologicalAge: profile.chronologicalAgeYears,
                        timezone: profile.timezone,
                        preferredLanguage: profile.preferredLanguage
                    )
                }
                
                // Set onboarding status from backend response
                // For new signups, backend should return false, but we set it explicitly to be safe
                if let onboardingStatus = hasCompletedOnboarding {
                    appState.setOnboardingStatus(onboardingStatus)
                    print("[RootView] Set onboarding status from backend: \(onboardingStatus)")
                } else if mode == .signup {
                    // For new signups, explicitly set onboarding to false if backend didn't respond
                    appState.setOnboardingStatus(false)
                    print("[RootView] New signup - setting hasCompletedOnboarding to false")
                }
            }
            
            // Step 5: Bootstrap app state (require backend during login)
            // But allow 404 "Complete onboarding first" and missingAuthToken to pass through
            // Ensure token is ready before bootstrap
            do {
                // Pre-fetch token to ensure it's ready (with retry)
                // Note: We already have a token from postAuthMe, but we need to ensure it's still valid
                var tokenReady = false
                var retryCount = 0
                while !tokenReady && retryCount < 5 {
                    do {
                        // Check if user is still authenticated
                        guard authManager.currentUser != nil else {
                            throw APIError.missingAuthToken
                        }
                        _ = try await authManager.getIDToken()
                        tokenReady = true
                    } catch {
                        retryCount += 1
                        if retryCount < 5 {
                            // Wait a bit before retry (increasing delay)
                            try await Task.sleep(nanoseconds: UInt64(200_000_000 * retryCount)) // 0.2s, 0.4s, 0.6s, 0.8s
                            print("[RootView] Token not ready, retrying (\(retryCount)/5)... Error: \(error)")
                        } else {
                            print("[RootView] Token fetch failed after 5 retries: \(error)")
                            // If token fetch fails but user is authenticated, allow onboarding anyway
                            if authManager.currentUser != nil {
                                print("[RootView] User is authenticated but token fetch failed, allowing onboarding")
                                await MainActor.run {
                                    if let onboardingStatus = hasCompletedOnboarding {
                                        appState.setOnboardingStatus(onboardingStatus)
                                    } else {
                                        appState.setOnboardingStatus(false)
                                    }
                                    isBootstrapComplete = true
                                }
                                return
                            }
                            throw error
                        }
                    }
                }
                try await appState.bootstrap(requireBackend: true)
                
                // Bootstrap successful - check subscription status
                await checkSubscriptionStatus()
                
                // Bootstrap successful - onboarding status already set from postAuthMe response
                // No need to override it here
                await MainActor.run {
                    isBootstrapComplete = true
                }
            } catch {
                print("[RootView] Bootstrap error during login: \(error)")
                // Check if it's a 404 "Complete onboarding first" - this is normal for new users
                if isOnboardingRequiredError(error) {
                    // This is normal - user needs to complete onboarding
                    // Use onboarding status from postAuthMe if available, otherwise set to false
                    print("[RootView] User needs to complete onboarding (login)")
                    await MainActor.run {
                        // Set onboarding flag to false FIRST, then complete bootstrap
                        // This ensures view renders onboarding screen immediately
                        if let onboardingStatus = hasCompletedOnboarding {
                            appState.setOnboardingStatus(onboardingStatus)
                        } else {
                            appState.setOnboardingStatus(false)
                        }
                        // Complete bootstrap in the same update cycle
                        isBootstrapComplete = true
                    }
                    return
                } else if isMissingAuthTokenError(error) {
                    // Missing auth token - this can happen for new users, allow onboarding
                    // Use onboarding status from postAuthMe if available, otherwise set to false
                    print("[RootView] Missing auth token, allowing onboarding (login)")
                    await MainActor.run {
                        // Set onboarding flag to false FIRST, then complete bootstrap
                        // This ensures view renders onboarding screen immediately
                        if let onboardingStatus = hasCompletedOnboarding {
                            appState.setOnboardingStatus(onboardingStatus)
                        } else {
                            appState.setOnboardingStatus(false)
                        }
                        // Complete bootstrap in the same update cycle
                        isBootstrapComplete = true
                    }
                    return
                } else if isSubscriptionRequiredError(error) {
                    // Subscription required - show paywall
                    // Use onboarding status from postAuthMe if available, otherwise set to false
                    print("[RootView] Subscription required, showing paywall (login)")
                    await MainActor.run {
                        // Set onboarding flag to false FIRST, then complete bootstrap
                        // This ensures view renders onboarding screen immediately
                        if let onboardingStatus = hasCompletedOnboarding {
                            appState.setOnboardingStatus(onboardingStatus)
                        } else {
                            appState.setOnboardingStatus(false)
                        }
                        // Complete bootstrap in the same update cycle
                        isBootstrapComplete = true
                        // Show paywall
                        showPaywall = true
                        appState.subscriptionStatus = .inactive
                    }
                    return
                } else if isInvalidResponseError(error) {
                    // Decoding/invalid response error - this happens when backend returns incomplete data
                    // Use onboarding status from postAuthMe response if available, otherwise check cached data
                    if let onboardingStatus = hasCompletedOnboarding {
                        // We already have onboarding status from postAuthMe
                        print("[RootView] Invalid response error during login, but onboarding status from postAuthMe: \(onboardingStatus)")
                        await MainActor.run {
                            // Keep onboarding status from postAuthMe
                            appState.setOnboardingStatus(onboardingStatus)
                            // Complete bootstrap in the same update cycle
                            isBootstrapComplete = true
                        }
                        return
                    } else {
                        // postAuthMe failed, check cached summary
                        let hasCompletedBefore = appState.summary?.state.baselineBiologicalAgeYears != nil
                        if !hasCompletedBefore {
                            // New user or user hasn't completed onboarding
                            print("[RootView] Invalid response error during login, allowing onboarding (new user or incomplete onboarding)")
                            await MainActor.run {
                                // Set onboarding flag to false FIRST, then complete bootstrap
                                // This ensures view renders onboarding screen immediately
                                appState.setOnboardingStatus(false)
                                // Complete bootstrap in the same update cycle
                                isBootstrapComplete = true
                            }
                            return
                        } else {
                            // User has completed onboarding before, but decoding failed
                            // Continue with cached data
                            print("[RootView] Invalid response error during login, but user has completed onboarding - continuing with cached data")
                            await MainActor.run {
                                // Keep existing onboarding status from cached summary
                                appState.setOnboardingStatus(true)
                                // Complete bootstrap in the same update cycle
                                isBootstrapComplete = true
                            }
                            return
                        }
                    }
                } else {
                    // For other errors during login, throw to be handled by outer catch
                    throw error
                }
            }
            
            // Bootstrap succeeded and it's not a new signup
            await MainActor.run {
                isBootstrapComplete = true
            }
            
            // Check subscription status after successful bootstrap
            await checkSubscriptionStatus()
        } catch {
            // If Firebase auth succeeded but backend failed, check error type
            if firebaseAuthSucceeded {
                // First check if it's an onboarding required error (404 with onboarding message)
                if isOnboardingRequiredError(error) {
                    // This is normal - user needs to complete onboarding
                    print("[RootView] User needs to complete onboarding")
                    await MainActor.run {
                        isBootstrapComplete = true
                        isAuthenticating = false
                    }
                    return
                }
                
                // Check if it's a missing auth token error
                if isMissingAuthTokenError(error) {
                    // Missing auth token - this can happen for new users, allow onboarding
                    print("[RootView] Missing auth token, allowing onboarding")
                    await MainActor.run {
                        isBootstrapComplete = true
                        isAuthenticating = false
                    }
                    return
                }
                
                // Check if it's a subscription required error (403 with subscription_required)
                if isSubscriptionRequiredError(error) {
                    // Subscription required - allow onboarding/continue, don't logout
                    print("[RootView] Subscription required, allowing onboarding")
                    await MainActor.run {
                        isBootstrapComplete = true
                        isAuthenticating = false
                    }
                    return
                }
                
                // Check if it's an authentication error (401, 403) - these should logout
                // Note: 403 subscription errors are handled above
                let isAuthError = isAuthenticationError(error)
                
                if isAuthError {
                    // Authentication failed (invalid credentials, unauthorized, etc.), sign out
                    print("[RootView] Authentication failed, signing out")
                    do {
                        try authManager.signOut()
                    } catch {
                        print("[RootView] Failed to sign out after auth error: \(error)")
                    }
                    await MainActor.run {
                        authError = getErrorMessage(for: error)
                        isAuthenticating = false
                    }
                } else {
                    // Check if it's a network/backend connection error
                    let isBackendError = isBackendConnectionError(error)
                    
                    if isBackendError {
                        // Backend is down, try to continue with cached data
                        print("[RootView] Backend unavailable, attempting to continue with cached data")
                        let errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .login)
                        await MainActor.run {
                            // Use Firebase user ID if available
                            if let firebaseUserId = authManager.uid {
                                appState.userId = firebaseUserId
                            }
                            // Show error alert to user
                            authErrorTitle = "Connection Issue"
                            authError = errorMessage
                            // Try to bootstrap with cached data
                            Task {
                                do {
                                    try await appState.bootstrap(requireBackend: false)
                                    await MainActor.run {
                                        isBootstrapComplete = true
                                        isAuthenticating = false
                                    }
                                } catch {
                                    // Even cached data failed, show error but don't logout
                                    await MainActor.run {
                                        isBootstrapComplete = true // Allow user to continue anyway
                                        isAuthenticating = false
                                    }
                                }
                            }
                        }
                        // Don't set isAuthenticating = false here, wait for Task to complete
                        return
                    } else {
                        // Other errors, sign out
                        do {
                            try authManager.signOut()
                        } catch {
                            print("[RootView] Failed to sign out after error: \(error)")
                        }
                        await MainActor.run {
                            authError = getErrorMessage(for: error)
                            isAuthenticating = false
                        }
                    }
                }
            } else {
                // Firebase auth failed, show error
                await MainActor.run {
                    authError = getErrorMessage(for: error)
                    isAuthenticating = false
                }
            }
        }
        
        await MainActor.run {
            isAuthenticating = false
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        return ErrorMessageHelper.getMessage(for: error)
    }
    
    private func isAuthenticationError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .httpError(_, let statusCode, let responseBody):
                // Authentication errors: 401 (Unauthorized), 403 (Forbidden) but NOT subscription errors
                if statusCode == 401 {
                    return true
                }
                if statusCode == 403 {
                    // Only treat as auth error if it's NOT a subscription error
                    let lowercased = responseBody.lowercased()
                    let isSubscriptionError = lowercased.contains("subscription_required") || 
                                             lowercased.contains("subscription required") ||
                                             lowercased.contains("\"code\":\"subscription_required\"")
                    return !isSubscriptionError
                }
                return false
            default:
                return false
            }
        }
        return false
    }
    
    private func isOnboardingRequiredError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .httpError(_, let statusCode, let responseBody):
                // 404 with "Complete onboarding first" or "User not found" message means user needs onboarding
                if statusCode == 404 {
                    let lowercased = responseBody.lowercased()
                    print("[RootView] Checking onboarding error - statusCode: \(statusCode), responseBody: \(responseBody)")
                    if lowercased.contains("complete onboarding") || 
                       lowercased.contains("user not found") ||
                       lowercased.contains("onboarding first") {
                        print("[RootView] Onboarding required error detected")
                        return true
                    }
                }
                return false
            default:
                return false
            }
        }
        return false
    }
    
    private func isMissingAuthTokenError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .missingAuthToken:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    private func isSubscriptionRequiredError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .httpError(_, let statusCode, let responseBody):
                // Subscription required: 403 with subscription_required message
                if statusCode == 403 {
                    let lowercased = responseBody.lowercased()
                    return lowercased.contains("subscription_required") || 
                           lowercased.contains("subscription required") ||
                           lowercased.contains("\"code\":\"subscription_required\"")
                }
                return false
            default:
                return false
            }
        }
        return false
    }
    
    private func isInvalidResponseError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidResponse:
                return true
            default:
                return false
            }
        }
        // Also check for DecodingError
        if error is DecodingError {
            return true
        }
        return false
    }
    
    private func isBackendConnectionError(_ error: Error) -> Bool {
        // Decoding errors are NOT connection errors - they indicate backend data format issues
        if error is DecodingError {
            return false
        }
        
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError(_, let underlyingError):
                // Check if underlying error is a real network error (not decoding)
                if underlyingError is DecodingError {
                    return false
                }
                return true
            case .httpError(_, let statusCode, _):
                // Server errors (5xx) or connection refused (could be 502, 503, etc.)
                return statusCode >= 500
            case .invalidResponse:
                // Invalid response (including decoding errors) is not a connection error
                return false
            default:
                return false
            }
        }
        // Check for network-related NSError codes
        if let nsError = error as NSError? {
            let networkErrorCodes: [Int] = [
                NSURLErrorTimedOut,           // -1001
                NSURLErrorCannotConnectToHost, // -1004
                NSURLErrorNetworkConnectionLost, // -1005
                NSURLErrorNotConnectedToInternet, // -1009
                NSURLErrorCannotFindHost,      // -1003
                NSURLErrorDNSLookupFailed      // -1006
            ]
            return networkErrorCodes.contains(nsError.code)
        }
        return false
    }
    
    private func checkSubscriptionStatus() async {
        await MainActor.run {
            isCheckingSubscription = true
        }
        
        // Load subscription status from backend
        await subscriptionManager.loadSubscriptionStatus()
        
        // Check if subscription is active
        let hasActiveSubscription = subscriptionManager.subscriptionStatus == .active || subscriptionManager.subscriptionStatus == .trial
        
        await MainActor.run {
            if hasActiveSubscription {
                // Subscription is active, update AppState and proceed
                appState.subscriptionStatus = .active
                showPaywall = false
                print("[RootView] Subscription is active, proceeding to app")
            } else {
                // No active subscription, show paywall
                appState.subscriptionStatus = .inactive
                showPaywall = true
                print("[RootView] No active subscription, showing paywall")
            }
            isCheckingSubscription = false
        }
    }
}
