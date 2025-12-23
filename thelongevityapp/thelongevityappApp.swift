//
//  thelongevityappApp.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI
import UIKit
import FirebaseCore

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
    @State private var isBootstrapComplete = false
    @State private var authError: String?
    @State private var isAuthenticating = false
    
    init() {
        let userId = AuthManager.shared.uid ?? ""
        _appState = StateObject(wrappedValue: AppState(userId: userId))
    }
    
    var body: some View {
        let isSignedIn = authManager.currentUser != nil
        
        return Group {
            if !isSignedIn {
                AuthLandingView { mode, email, password in
                    Task {
                        await handleAuth(mode: mode, email: email, password: password)
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
                .alert("Login failed", isPresented: .constant(authError != nil)) {
                    Button("OK") { authError = nil }
                } message: {
                    Text(authError ?? "Unknown error")
                }
            } else if !isBootstrapComplete {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .tint(.green)
                }
                .onAppear {
                    Task {
                        await appState.bootstrap()
                        isBootstrapComplete = true
                    }
                }
            } else if !appState.hasCompletedOnboarding {
                OnboardingFlowView()
                    .environmentObject(appState)
            } else {
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func handleAuth(mode: AuthMode, email: String, password: String) async {
        await MainActor.run {
            isAuthenticating = true
            authError = nil
        }
        do {
            if mode == .signup {
                try await authManager.signUp(email: email, password: password)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
            let token = try await authManager.getIDToken()
            let profile = try await APIClient.shared.postAuthMe(idToken: token)
            
            await MainActor.run {
                appState.userId = profile.uid
            }
            
            await appState.bootstrap()
            await MainActor.run {
                isBootstrapComplete = true
            }
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
            }
        }
        await MainActor.run {
            isAuthenticating = false
        }
    }
}
