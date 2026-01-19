//
//  MembershipView.swift
//  thelongevityapp
//
//  Redirects to iOS subscription management (no in-app purchases)
//

import SwiftUI
import StoreKit

struct MembershipView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.16, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Membership")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Manage your subscription through Apple's subscription settings.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 24)
                        
                        // Status Display
                        VStack(spacing: 8) {
                            Text("Current Status")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(subscriptionManager.subscriptionStatus.displayText)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        
                        // Primary Action Button
                        Button {
                            subscriptionManager.openSubscriptionManagement()
                            dismiss()
                        } label: {
                            HStack {
                                Text(subscriptionManager.subscriptionStatus == .inactive ? "View subscription options" : "Manage subscription")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.2, green: 0.5, blue: 0.35))
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Info Text
                        VStack(spacing: 8) {
                            Text("You'll be redirected to Apple's subscription settings.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                            
                            Text("Subscriptions are handled securely through your Apple ID.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Membership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.35))
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                Task {
                    await subscriptionManager.loadSubscriptionStatus()
                }
            }
        }
    }
}

