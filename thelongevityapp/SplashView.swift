//
//  SplashView.swift
//  thelongevityapp
//
//  Created for premium, calm splash screen animation
//

import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Animation states
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.92
    @State private var haloOpacity: Double = 0
    @State private var haloScale: CGFloat = 0.95
    @State private var contentOpacity: Double = 1.0
    
    // Navigation state
    @Binding var shouldDismiss: Bool
    
    private let accentGreen = Color.primaryGreen
    
    var body: some View {
        ZStack {
            // Full-screen black background
            Color.black
                .ignoresSafeArea()
            
            // Content
            VStack {
                Spacer()
                
                // Logo container with animations
                ZStack {
                    // Subtle radial green glow behind logo (low opacity)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentGreen.opacity(0.12), accentGreen.opacity(0.0)],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 10)
                    
                    // Halo ring (thin, breathing)
                    Circle()
                        .stroke(accentGreen.opacity(haloOpacity), lineWidth: 1.5)
                        .frame(width: 80, height: 80)
                        .scaleEffect(haloScale)
                    
                    // App Icon (circular, crisp)
                    Image("ikon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)
                }
                
                Spacer()
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        let logoDuration: Double = reduceMotion ? 0.3 : 0.45
        let haloDuration: Double = reduceMotion ? 0.4 : 0.65
        let totalDuration: Double = reduceMotion ? 0.7 : 1.1
        
        // 1. Logo fade + scale in (0.45s, easeOut)
        withAnimation(.easeOut(duration: logoDuration)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        
        // 2. Halo ring "breath" once (0.65s, easeInOut)
        // Start after logo animation begins (0.2s delay for smooth transition)
        let haloDelay = reduceMotion ? 0.15 : 0.2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + haloDelay) {
            withAnimation(.easeInOut(duration: haloDuration)) {
                haloOpacity = reduceMotion ? 0.2 : 0.35
                haloScale = reduceMotion ? 1.03 : 1.08
            }
            
            // Fade out halo
            DispatchQueue.main.asyncAfter(deadline: .now() + haloDuration * 0.6) {
                withAnimation(.easeInOut(duration: haloDuration * 0.4)) {
                    haloOpacity = 0
                    haloScale = reduceMotion ? 1.01 : 1.05
                }
            }
        }
        
        // 3. Crossfade transition to next screen (0.2s)
        let transitionDelay = totalDuration + (reduceMotion ? 0.1 : 0.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDelay) {
            withAnimation(.easeOut(duration: 0.2)) {
                contentOpacity = 0
            }
            
            // Trigger dismissal after fade completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                shouldDismiss = true
            }
        }
    }
}

