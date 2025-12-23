//
//  thelongevityappApp.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI
import FirebaseCore

@main
struct thelongevityappApp: App {
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
    @StateObject private var appState: AppState
    @State private var isBootstrapComplete = false
    
    init() {
        let userId = AuthManager.shared.userId ?? "gizem-demo"
        _appState = StateObject(wrappedValue: AppState(userId: userId))
    }
    
    var body: some View {
        Group {
            if !isBootstrapComplete {
                // Show loading state while bootstrapping
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
                // Show onboarding flow (no tabs)
                OnboardingFlowView()
                    .environmentObject(appState)
            } else {
                // Show main app with tabs
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .preferredColorScheme(.dark)
    }
}
