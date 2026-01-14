//
//  SubscriptionManager.swift
//  thelongevityapp
//
//  Manages subscription status and iOS subscription settings access
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var isLoading: Bool = false
    
    enum SubscriptionStatus {
        case active
        case trial
        case inactive
        case unknown
        
        var displayText: String {
            switch self {
            case .active:
                return "Active · Managed by Apple"
            case .trial:
                return "Trial active · Managed by Apple"
            case .inactive:
                return "Not active · Managed by Apple"
            case .unknown:
                return "Not active · Managed by Apple"
            }
        }
    }
    
    private init() {}
    
    // Load subscription status from backend
    func loadSubscriptionStatus() async {
        isLoading = true
        
        do {
            let response = try await APIClient.shared.getSubscriptionStatus()
            
            if let subscription = response.subscription,
               let status = subscription.status {
                switch status.lowercased() {
                case "active":
                    self.subscriptionStatus = .active
                case "trial":
                    self.subscriptionStatus = .trial
                default:
                    self.subscriptionStatus = .inactive
                }
            } else {
                self.subscriptionStatus = .inactive
            }
        } catch {
            print("[SubscriptionManager] Failed to load subscription status: \(error)")
            self.subscriptionStatus = .inactive
        }
        
        isLoading = false
    }
    
    // Open iOS subscription management screen
    func openSubscriptionManagement() {
        Task { @MainActor in
            do {
                // Use StoreKit 2 to open subscription management
                if #available(iOS 15.0, *) {
                    // Get the window scene
                    guard let windowScene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                        // Fallback: open Settings app
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            await UIApplication.shared.open(url)
                        }
                        return
                    }
                    
                    try await AppStore.showManageSubscriptions(in: windowScene)
                } else {
                    // Fallback for iOS 14: open Settings app
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        await UIApplication.shared.open(url)
                    }
                }
            } catch {
                print("[SubscriptionManager] Failed to open subscription management: \(error)")
                // Fallback: open Settings app
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
}

