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
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var mode: AuthMode
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var agreeTerms: Bool = false
    @State private var isLoading: Bool = false
    @State private var signupStep: Int = 1 // 1 = Basics, 2 = Account
    
    /// Hook to integrate with your auth/onboarding flow.
    /// Parameters: mode, email, password, firstName (optional), lastName (optional), dateOfBirth (optional)
    var onContinue: ((AuthMode, String, String, String?, String?, Date?) -> Void)?
    
    init(
        mode: AuthMode = .login,
        onContinue: ((AuthMode, String, String, String?, String?, Date?) -> Void)? = nil
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
                
                // Checkbox only shown in signup step 2
                if mode == .signup && signupStep == 2 {
                    HStack(spacing: 10) {
                        CheckCircle(isOn: $agreeTerms)
                        Text("I agree to the privacy & data usage terms")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: signupStep)
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
            // App Icon - Circular with subtle glow (reduced intensity)
            ZStack {
                // Soft glow/halo background (reduced by ~10%)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.09), accent.opacity(0.0)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 6)
                
                // Circular container
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(accent.opacity(0.135), lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(0.18), radius: 10, x: 0, y: 0)
                
                // App Icon
                Image("ikon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
            
            Text("LONGEVITY AI")
                .font(.system(size: 28, weight: .semibold))
                .kerning(1.2)
                .foregroundColor(.white)
            
            Text(mode == .login ? "Continue your longevity journey." : "Create your longevity profile")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var formFields: some View {
        ZStack {
            // Step 1: Basics (First name, Date of birth)
            if mode == .signup && signupStep == 1 {
                VStack(spacing: 24) {
                    GlassTextField(
                        title: "First name",
                        placeholder: "John",
                        text: $firstName,
                        icon: "person"
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        GlassDatePicker(
                            title: "Date of birth",
                            date: $dateOfBirth
                        )
                        
                        Text("Used to calculate your biological age.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 4)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
            
            // Step 2: Account (Email, Password)
            if mode == .signup && signupStep == 2 {
                VStack(spacing: 24) {
                    GlassTextField(
                        title: "Email address",
                        placeholder: "user@example.com",
                        text: $email,
                        icon: "envelope"
                    )
                    
                    GlassSecureField(
                        title: "Create password",
                        placeholder: "•••••••",
                        text: $password,
                        icon: "eye.slash"
                    )
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            
            // Login fields
            if mode == .login {
                VStack(spacing: 24) {
                    GlassTextField(
                        title: "Email address",
                        placeholder: "user@example.com",
                        text: $email,
                        icon: "envelope"
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        GlassSecureField(
                            title: "Password",
                            placeholder: "•••••••",
                            text: $password,
                            icon: "eye.slash"
                        )
                        
                        Button(action: {
                            // TODO: Implement forgot password flow
                            print("Forgot password tapped")
                        }) {
                            Text("Forgot password?")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.leading, 4)
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: signupStep)
    }
    
    private var primaryButton: some View {
        var isDisabled: Bool {
            if isLoading { return true }
            if mode == .login {
                return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                       password.isEmpty
            } else {
                // Signup step 1: Need first name
                if signupStep == 1 {
                    return firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                // Signup step 2: Need email, password, and terms agreement
                return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                       password.isEmpty || 
                       !agreeTerms
            }
        }
        
        var buttonText: String {
            if mode == .login {
                return "Continue"
            } else {
                return signupStep == 1 ? "Continue" : "Create account"
            }
        }
        
        return Button {
            guard !isLoading else { return }
            
            if mode == .signup && signupStep == 1 {
                // Move to step 2
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    signupStep = 2
                }
            } else {
                // Submit form
                isLoading = true
                Task { @MainActor in
                    if mode == .signup {
                        onContinue?(mode, email.trimmingCharacters(in: .whitespacesAndNewlines), password, firstName.trimmingCharacters(in: .whitespacesAndNewlines), nil, dateOfBirth)
                    } else {
                        onContinue?(mode, email.trimmingCharacters(in: .whitespacesAndNewlines), password, nil, nil, nil)
                    }
                    isLoading = false
                }
            }
        } label: {
            HStack {
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                if isLoading {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.8)
                        .padding(.leading, 8)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(mode == .login ? accent : accent.opacity(0.9))
                    .shadow(
                        color: mode == .login 
                            ? accent.opacity(0.315) 
                            : accent.opacity(0.162),
                        radius: mode == .login ? 12.6 : 8.1,
                        x: 0,
                        y: mode == .login ? 6.3 : 3.6
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
    
    private var footerLinks: some View {
        VStack(spacing: 10) {
            if mode == .login {
                Button {
                    mode = .signup
                    signupStep = 1 // Reset to step 1 when switching to signup
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Sign Up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else if signupStep == 2 {
                // Show "Already have an account?" only in step 2
                Button {
                    mode = .login
                    signupStep = 1 // Reset signup step
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Sign In")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: signupStep)
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
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.5))
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
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
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
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

private struct GlassDatePicker: View {
    let title: String
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 18)
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(Color(red: 0, green: 0.93, blue: 0.63).opacity(0.9))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
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

private struct DatePickerField: View {
    let title: String
    @Binding var date: Date
    @State private var showDatePicker: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Button {
                showDatePicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 18)
                    
                    Text(dateFormatter.string(from: date))
                        .foregroundColor(.white)
                    
                    Spacer()
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
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("Date of Birth", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                
                Button("Done") {
                    showDatePicker = false
                }
                .padding()
            }
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
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

