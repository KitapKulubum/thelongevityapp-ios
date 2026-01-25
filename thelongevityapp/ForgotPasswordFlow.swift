//
//  ForgotPasswordFlow.swift
//  thelongevityapp
//
//  Forgot Password flow with 6-digit OTP verification
//

import SwiftUI

// MARK: - Flow Coordinator
enum ForgotPasswordStep {
    case email
    case verifyCode(email: String)
    case newPassword(email: String, resetToken: String)
    case success(email: String)
}

// MARK: - Main Flow Container
struct ForgotPasswordFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var currentStep: ForgotPasswordStep = .email
    @State private var email: String = ""
    @State private var resetToken: String = ""
    
    var onComplete: ((String) -> Void)? // Called with email when flow completes
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.16, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                Group {
                    switch currentStep {
                    case .email:
                        ResetPasswordEmailView(
                            email: $email,
                            onContinue: { email in
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentStep = .verifyCode(email: email)
                                }
                            }
                        )
                    case .verifyCode(let email):
                        VerifyCodeView(
                            email: email,
                            onVerified: { token in
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentStep = .newPassword(email: email, resetToken: token)
                                }
                            },
                            onBack: {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentStep = .email
                                }
                            }
                        )
                    case .newPassword(let email, let token):
                        NewPasswordView(
                            email: email,
                            resetToken: token,
                            onSuccess: {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentStep = .success(email: email)
                                }
                            },
                            onBack: {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentStep = .verifyCode(email: email)
                                }
                            }
                        )
                    case .success(let email):
                        SuccessView(
                            email: email,
                            onBackToSignIn: {
                                onComplete?(email)
                                dismiss()
                            }
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Group {
                        switch currentStep {
                        case .email:
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.white.opacity(0.7))
                        case .verifyCode:
                            Button {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentStep = .email
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        case .newPassword(let email, _):
                            Button {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentStep = .verifyCode(email: email)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        case .success:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - A) ResetPasswordEmailView
struct ResetPasswordEmailView: View {
    @Binding var email: String
    @StateObject private var languageManager = LanguageManager.shared
    @State private var isLoading: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var errorMessage: String?
    
    var onContinue: (String) -> Void
    
    private let accent = Color.primaryGreen
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                
                // Logo
                logoBlock
                
                // Title & Subtitle
                VStack(spacing: 12) {
                    Text(languageManager.localized("Reset password"))
                        .font(.system(size: 28, weight: .semibold))
                        .kerning(1.2)
                        .foregroundColor(.white)
                    
                    Text(languageManager.localized("We'll send a verification code to your email."))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Email Input
                VStack(spacing: 16) {
                    GlassTextField(
                        title: languageManager.localized("Email address"),
                        placeholder: "user@example.com",
                        text: $email,
                        icon: "envelope"
                    )
                    .disabled(isLoading)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                    }
                }
                .padding(.horizontal, 24)
                
                // Send Code Button
                Button {
                    Task {
                        await sendCode()
                    }
                } label: {
                    HStack {
                        Text(languageManager.localized("Send code"))
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
                            .fill(accent.opacity(0.9))
                            .shadow(
                                color: accent.opacity(0.162),
                                radius: 8.1,
                                x: 0,
                                y: 3.6
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity((isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .overlay(
            // Confirmation Toast
            Group {
                if showConfirmation {
                    VStack {
                        Spacer()
                        HStack {
                            Text(languageManager.localized("If an account exists for this email, we've sent a code."))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        )
        .animation(.easeInOut(duration: 0.3), value: showConfirmation)
    }
    
    private var logoBlock: some View {
        VStack(spacing: 14) {
            ZStack {
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
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(accent.opacity(0.135), lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(0.18), radius: 10, x: 0, y: 0)
                
                Image("ikon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
        }
    }
    
    private func sendCode() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await APIClient.shared.requestPasswordReset(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            
            // Always show confirmation (security: don't reveal if email exists)
            showConfirmation = true
            
            // Navigate after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onContinue(email.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } catch {
            errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .general)
            showConfirmation = false
        }
        
        isLoading = false
    }
}

// MARK: - B) VerifyCodeView
struct VerifyCodeView: View {
    let email: String
    @StateObject private var languageManager = LanguageManager.shared
    @State private var code: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var resendCountdown: Int = 60
    @State private var canResend: Bool = false
    @State private var countdownTimer: Timer?
    @FocusState private var isCodeFocused: Bool
    
    var onVerified: (String) -> Void
    var onBack: () -> Void
    
    private let accent = Color.primaryGreen
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                
                // Logo
                logoBlock
                
                // Title & Subtitle
                VStack(spacing: 12) {
                    Text(languageManager.localized("Enter verification code"))
                        .font(.system(size: 28, weight: .semibold))
                        .kerning(1.2)
                        .foregroundColor(.white)
                    
                    Text("\(languageManager.localized("We sent a 6-digit code to")) \(email)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Code Input
                VStack(spacing: 16) {
                    CodeInputView(code: $code, isFocused: $isCodeFocused)
                        .disabled(isLoading)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                    }
                    
                    // Resend Code
                    HStack(spacing: 8) {
                        if !canResend {
                            Text("\(languageManager.localized("Resend code in")) \(resendCountdown)s")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Button {
                                Task {
                                    await resendCode()
                                }
                            } label: {
                                Text(languageManager.localized("Resend code"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(accent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                }
                .padding(.horizontal, 24)
                
                // Verify Button
                Button {
                    Task {
                        await verifyCode()
                    }
                } label: {
                    HStack {
                        Text(languageManager.localized("Verify"))
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
                            .fill(accent.opacity(0.9))
                            .shadow(
                                color: accent.opacity(0.162),
                                radius: 8.1,
                                x: 0,
                                y: 3.6
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading || code.count != 6)
                .opacity((isLoading || code.count != 6) ? 0.6 : 1)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            isCodeFocused = true
            startCountdown()
        }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil
        }
    }
    
    private var logoBlock: some View {
        VStack(spacing: 14) {
            ZStack {
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
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(accent.opacity(0.135), lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(0.18), radius: 10, x: 0, y: 0)
                
                Image("ikon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
        }
    }
    
    private func verifyCode() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIClient.shared.verifyPasswordResetCode(
                email: email,
                code: code
            )
            onVerified(response.resetToken)
        } catch let error as APIError {
            // Try to parse backend message first
            if case .httpError(_, let statusCode, let responseBody) = error {
                if let backendMessage = ErrorMessageHelper.parseBackendError(responseBody) {
                    errorMessage = backendMessage
                } else if statusCode == 400 {
                    errorMessage = "Invalid or expired code. Please request a new one."
                } else if statusCode == 429 {
                    errorMessage = "Too many attempts. Please wait a moment and try again."
                } else {
                    errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .general)
                }
            } else {
                errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .general)
            }
        } catch {
            errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .general)
        }
        
        isLoading = false
    }
    
    private func resendCode() async {
        canResend = false
        resendCountdown = 60
        
        do {
            try await APIClient.shared.requestPasswordReset(email: email)
            startCountdown()
        } catch {
            errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .general)
        }
    }
    
    private func startCountdown() {
        countdownTimer?.invalidate()
        resendCountdown = 60
        canResend = false
        
        DispatchQueue.main.async { [self] in
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                resendCountdown -= 1
                if resendCountdown <= 0 {
                    canResend = true
                    timer.invalidate()
                    countdownTimer = nil
                }
            }
        }
    }
}

// MARK: - Code Input Component (6 boxes)
struct CodeInputView: View {
    @Binding var code: String
    @FocusState.Binding var isFocused: Bool
    @StateObject private var languageManager = LanguageManager.shared
    
    private let accent = Color.primaryGreen
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageManager.localized("Verification code"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    CodeDigitBox(
                        digit: index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : "",
                        isFocused: isFocused && index == code.count
                    )
                }
            }
            
            // Hidden text field for input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
                .onChange(of: code) { oldValue, newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        code = String(newValue.prefix(6))
                    }
                    // Only allow digits
                    code = code.filter { $0.isNumber }
                }
        }
    }
}

struct CodeDigitBox: View {
    let digit: String
    let isFocused: Bool
    
    private let accent = Color.primaryGreen
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? accent.opacity(0.5) : Color.white.opacity(0.08),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .frame(height: 56)
            
            if digit.isEmpty {
                Text("•")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white.opacity(0.2))
            } else {
                Text(digit)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - C) NewPasswordView
struct NewPasswordView: View {
    let email: String
    let resetToken: String
    @StateObject private var languageManager = LanguageManager.shared
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var onSuccess: () -> Void
    var onBack: () -> Void
    
    private let accent = Color.primaryGreen
    
    private var isValid: Bool {
        newPassword.count >= 8 && newPassword == confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                
                // Logo
                logoBlock
                
                // Title
                VStack(spacing: 12) {
                    Text(languageManager.localized("Create a new password"))
                        .font(.system(size: 28, weight: .semibold))
                        .kerning(1.2)
                        .foregroundColor(.white)
                }
                
                // Password Inputs
                VStack(spacing: 16) {
                    GlassSecureField(
                        title: "New password",
                        placeholder: "•••••••",
                        text: $newPassword,
                        icon: "eye.slash",
                        helperText: "A strong password helps protect your longevity data.",
                        validationMessage: errorMessage,
                        showValidation: true,
                        email: email
                    )
                    .disabled(isLoading)
                    
                    GlassSecureField(
                        title: "Confirm password",
                        placeholder: "•••••••",
                        text: $confirmPassword,
                        icon: "eye.slash"
                    )
                    .disabled(isLoading)
                    
                    // Show mismatch message if passwords don't match
                    if !confirmPassword.isEmpty && newPassword != confirmPassword {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.76, blue: 0.03).opacity(0.9))
                            
                            Text(languageManager.localized("Passwords don't match yet."))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(red: 1.0, green: 0.76, blue: 0.03).opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)
                        .accessibilityLabel("Password validation: \(languageManager.localized("Passwords don't match yet."))")
                    }
                }
                .padding(.horizontal, 24)
                
                // Update Password Button
                Button {
                    Task {
                        await updatePassword()
                    }
                } label: {
                    HStack {
                        Text(languageManager.localized("Update password"))
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
                            .fill(accent.opacity(0.9))
                            .shadow(
                                color: accent.opacity(0.162),
                                radius: 8.1,
                                x: 0,
                                y: 3.6
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading || !isValid)
                .opacity((isLoading || !isValid) ? 0.6 : 1)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    private var logoBlock: some View {
        VStack(spacing: 14) {
            ZStack {
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
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(accent.opacity(0.135), lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(0.18), radius: 10, x: 0, y: 0)
                
                Image("ikon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
        }
    }
    
    private func updatePassword() async {
        isLoading = true
        errorMessage = nil
        
        // Client-side validation (already shown inline via GlassSecureField)
        guard newPassword == confirmPassword else {
            isLoading = false
            return // Mismatch message shown inline
        }
        
        do {
            try await APIClient.shared.confirmPasswordReset(
                resetToken: resetToken,
                newPassword: newPassword
            )
            onSuccess()
        } catch let error as APIError {
            // Handle backend password validation errors
            errorMessage = parsePasswordError(error)
        } catch {
            errorMessage = ErrorMessageHelper.getContextualMessage(for: error, context: .general)
        }
        
        isLoading = false
    }
    
    private func parsePasswordError(_ error: APIError) -> String {
        switch error {
        case .httpError(_, let statusCode, let responseBody):
            if statusCode == 400 {
                // Parse backend error code from response body
                if responseBody.contains("PASSWORD_TOO_SHORT") {
                    return "Try a slightly stronger password — at least 8 characters."
                } else if responseBody.contains("PASSWORD_TOO_WEAK") || responseBody.contains("PASSWORD_POLICY_VIOLATION") {
                    return "This password is easy to guess. Try adding more characters."
                }
            }
            return "Failed to update password. Please try again."
        default:
            return "Failed to update password. Please try again."
        }
    }
}

// MARK: - D) SuccessView
struct SuccessView: View {
    let email: String
    @StateObject private var languageManager = LanguageManager.shared
    var onBackToSignIn: () -> Void
    
    private let accent = Color.primaryGreen
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(accent)
            }
            
            // Message
            VStack(spacing: 12) {
                Text(languageManager.localized("Your password has been updated."))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Back to Sign In Button
            Button {
                onBackToSignIn()
            } label: {
                HStack {
                    Text(languageManager.localized("Back to sign in"))
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(accent.opacity(0.9))
                        .shadow(
                            color: accent.opacity(0.162),
                            radius: 8.1,
                            x: 0,
                            y: 3.6
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

