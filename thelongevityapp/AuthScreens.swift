//
//  AuthScreens.swift
//  thelongevityapp
//
//  Created for a stylized login / sign-up experience that matches the app's
//  neon-green / dark aesthetic. These screens are UI-only placeholders; wire
//  `onContinue` to your auth flow when ready.
//

import SwiftUI

enum AuthMode {
    case login, signup
}

struct AuthLandingView: View {
    @State private var mode: AuthMode
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreeTerms: Bool = false
    @State private var isLoading: Bool = false
    
    /// Hook to integrate with your auth/onboarding flow.
    var onContinue: ((AuthMode, String, String) -> Void)?
    
    init(
        mode: AuthMode = .login,
        onContinue: ((AuthMode, String, String) -> Void)? = nil
    ) {
        _mode = State(initialValue: mode)
        self.onContinue = onContinue
    }
    
    private let accent = Color(red: 0, green: 0.93, blue: 0.63)
    private let darkBgTop = Color.black
    private let darkBgBottom = Color(red: 0.05, green: 0.16, blue: 0.12)
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [darkBgTop, darkBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer().frame(height: 20)
                
                logoBlock
                    .padding(.top, 16)
                
                formFields
                    .padding(.horizontal, 24)
                
                if mode == .signup {
                    HStack(spacing: 10) {
                        CheckCircle(isOn: $agreeTerms)
                        Text("I agree to the Data Processing Terms")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                }
                
                primaryButton
                    .padding(.horizontal, 24)
                
                footerLinks
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    private var logoBlock: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(accent.opacity(0.12))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "leaf.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(accent)
                        .frame(width: 36, height: 36)
                        .shadow(color: accent.opacity(0.5), radius: 14, x: 0, y: 0)
                )
            
            Text("LONGEVITY AI")
                .font(.system(size: 28, weight: .bold))
                .kerning(1.2)
                .foregroundColor(.white)
            
            Text(mode == .login ? "BIO-INTELLIGENCE ACCESS" : "INITIALIZE PROTOCOL")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accent.opacity(0.8))
                .textCase(.uppercase)
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 18) {
            GlassTextField(
                title: mode == .login ? "Email Address" : "Coordinates // Email Address",
                placeholder: "user@example.com",
                text: $email,
                icon: "envelope"
            )
            
            GlassSecureField(
                title: mode == .login ? "Password" : "Security // Create Password",
                placeholder: "•••••••",
                text: $password,
                icon: "eye.slash"
            )
        }
    }
    
    private var primaryButton: some View {
        Button {
            guard !isLoading else { return }
            isLoading = true
            Task { @MainActor in
                onContinue?(mode, email.trimmingCharacters(in: .whitespacesAndNewlines), password)
                isLoading = false
            }
        } label: {
            HStack {
                Text(mode == .login ? "ACCESS TERMINAL" : "INITIATE ACCESS")
                    .font(.system(size: 16, weight: .bold))
                if isLoading {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.8)
                        .padding(.leading, 8)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(accent)
                    .shadow(color: accent.opacity(0.4), radius: 16, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading || (mode == .signup && !agreeTerms))
        .opacity((mode == .signup && !agreeTerms) ? 0.7 : 1)
    }
    
    private var footerLinks: some View {
        VStack(spacing: 10) {
            if mode == .login {
                Button {
                    mode = .signup
                } label: {
                    Text("Don't have an account? Initialize Sequence")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                }
            } else {
                Button {
                    mode = .login
                } label: {
                    Text("Already operational? Sign In")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                }
            }
        }
    }
}

// MARK: - Components

private struct GlassTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 18)
                
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
}

private struct GlassSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    @State private var isSecure: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 10) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
}

private struct CheckCircle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    .frame(width: 22, height: 22)
                
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0.93, blue: 0.63))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// Preview for quick visual checks
struct AuthLandingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AuthLandingView()
            AuthLandingView(mode: .signup)
        }
    }
}

