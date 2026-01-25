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
    @StateObject private var languageManager = LanguageManager.shared
    
    @State private var mode: AuthMode
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var agreeTerms: Bool = false
    @State private var isLoading: Bool = false
    @State private var showForgotPassword: Bool = false
    @State private var showPrivacyPolicy: Bool = false
    @State private var showTermsOfService: Bool = false
    
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
    
    private let accent = Color.primaryGreen
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
                
                // Checkbox for signup
                if mode == .signup {
                    HStack(alignment: .top, spacing: 10) {
                        CheckCircle(isOn: $agreeTerms)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(languageManager.localized("I agree to the"))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Button {
                                    showPrivacyPolicy = true
                                } label: {
                                    Text(languageManager.localized("Privacy Policy"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.primaryGreen)
                                        .underline()
                                }
                                
                                Text("&")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Button {
                                    showTermsOfService = true
                                } label: {
                                    Text(languageManager.localized("Terms of Service"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.primaryGreen)
                                        .underline()
                                }
                            }
                        }
                        
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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordFlowView { returnedEmail in
                // Prefill email when returning from forgot password flow
                email = returnedEmail
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
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
            
            Text(languageManager.localized("The Longevity App"))
                .font(.system(size: 28, weight: .semibold))
                .kerning(1.2)
                .foregroundColor(.white)
            
            Text(mode == .login ? languageManager.localized("Continue your longevity journey.") : languageManager.localized("Create your longevity profile"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    @ViewBuilder
    private var formFields: some View {
        if mode == .signup {
            // Signup: All fields in one page
            VStack(spacing: 24) {
                GlassTextField(
                    title: languageManager.localized("First name"),
                    placeholder: "John",
                    text: $firstName,
                    icon: "person"
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    GlassDatePicker(
                        title: languageManager.localized("Date of birth"),
                        date: $dateOfBirth
                    )
                    
                    Text(languageManager.localized("Used to calculate your biological age."))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 4)
                        .padding(.top, 2)
                }
                
                GlassTextField(
                    title: languageManager.localized("Email address"),
                    placeholder: "user@example.com",
                    text: $email,
                    icon: "envelope"
                )
                
                GlassSecureField(
                    title: languageManager.localized("Create password"),
                    placeholder: "•••••••",
                    text: $password,
                    icon: "eye.slash",
                    helperText: languageManager.localized("A strong password helps protect your longevity data."),
                    showValidation: true,
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        } else {
            // Login fields
            VStack(spacing: 24) {
                GlassTextField(
                    title: languageManager.localized("Email address"),
                    placeholder: "user@example.com",
                    text: $email,
                    icon: "envelope"
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    GlassSecureField(
                        title: languageManager.localized("Create password"),
                        placeholder: "•••••••",
                        text: $password,
                        icon: "eye.slash"
                    )
                    
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text(languageManager.localized("Forgot password?"))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }
    
    private var primaryButton: some View {
        var isDisabled: Bool {
            if isLoading { return true }
            if mode == .login {
                return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                       password.isEmpty
            } else {
                // Signup: Need first name, email, password, and terms agreement
                return firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                       email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                       password.isEmpty || 
                       !agreeTerms
            }
        }
        
        var buttonText: String {
            if mode == .login {
                return languageManager.localized("Continue")
            } else {
                return languageManager.localized("Create account")
            }
        }
        
        return Button {
            guard !isLoading else { return }
            
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
                } label: {
                    HStack(spacing: 4) {
                        Text(languageManager.localized("Don't have an account?"))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        Text(languageManager.localized("Sign Up"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else {
                // Show "Already have an account?" in signup
                Button {
                    mode = .login
                } label: {
                    HStack(spacing: 4) {
                        Text(languageManager.localized("Already have an account?"))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        Text(languageManager.localized("Sign In"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
}

// MARK: - Components

struct GlassTextField: View {
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

struct GlassSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var helperText: String? = nil
    var validationMessage: String? = nil
    var showValidation: Bool = false
    var email: String? = nil // For password validation against email
    
    @State private var isSecure: Bool = true
    @State private var hasStartedTyping: Bool = false
    @State private var hasLostFocus: Bool = false
    @FocusState private var isFocused: Bool
    
    private var shouldShowValidation: Bool {
        (hasStartedTyping || hasLostFocus) && showValidation
    }
    
    private var validationResult: PasswordValidationResult {
        guard !text.isEmpty else { return .valid }
        return PasswordValidator.validate(text, email: email)
    }
    
    private var displayValidationMessage: String? {
        guard shouldShowValidation, !text.isEmpty else { return nil }
        if let validationMessage = validationMessage {
            return validationMessage
        }
        let result = validationResult
        return result == .valid ? nil : result.message
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 10) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(.white)
                        .focused($isFocused)
                        .accessibilityLabel(title)
                        .accessibilityHint(helperText ?? "")
                        .onChange(of: text) { oldValue, newValue in
                            if !hasStartedTyping && !newValue.isEmpty {
                                hasStartedTyping = true
                            }
                        }
                        .onChange(of: isFocused) { oldValue, newValue in
                            if !newValue && hasStartedTyping {
                                hasLostFocus = true
                            }
                        }
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.white)
                        .focused($isFocused)
                        .accessibilityLabel(title)
                        .accessibilityHint(helperText ?? "")
                        .onChange(of: text) { oldValue, newValue in
                            if !hasStartedTyping && !newValue.isEmpty {
                                hasStartedTyping = true
                            }
                        }
                        .onChange(of: isFocused) { oldValue, newValue in
                            if !newValue && hasStartedTyping {
                                hasLostFocus = true
                            }
                        }
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
            
            // Helper text (always shown if provided)
            if let helperText = helperText {
                Text(helperText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 4)
                    .padding(.top, 2)
                    .accessibilityLabel("Password helper: \(helperText)")
            }
            
            // Validation message (shown when validation is active)
            if let message = displayValidationMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.76, blue: 0.03).opacity(0.9))
                    
                    Text(message)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 1.0, green: 0.76, blue: 0.03).opacity(0.9))
                }
                .padding(.leading, 4)
                .padding(.top, 2)
                .accessibilityLabel("Password validation: \(message)")
            }
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
                    .accentColor(Color.primaryGreen.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        .foregroundColor(Color.primaryGreen)
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

