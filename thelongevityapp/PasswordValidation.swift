//
//  PasswordValidation.swift
//  thelongevityapp
//
//  Client-side password validation helper with calm, human-friendly messages
//

import Foundation

enum PasswordValidationResult {
    case valid
    case tooShort
    case tooWeak
    case policyViolation
    
    var message: String {
        switch self {
        case .valid:
            return "Looks good."
        case .tooShort:
            return "Try a slightly stronger password — at least 8 characters."
        case .tooWeak:
            return "This password is easy to guess. Try adding more characters."
        case .policyViolation:
            return "This password is easy to guess. Try adding more characters."
        }
    }
}

struct PasswordValidator {
    // Common weak passwords (subset of backend list)
    private static let weakPasswords: Set<String> = [
        "password", "123456", "12345678", "qwerty", "abc123", "password123",
        "admin", "letmein", "welcome", "monkey", "1234567890", "qwerty123",
        "password1", "123123", "dragon", "sunshine", "princess", "football",
        "master", "hello", "freedom", "whatever", "qazwsx", "trustno1"
    ]
    
    /// Validates password and returns a validation result with human-friendly message
    static func validate(_ password: String, email: String? = nil) -> PasswordValidationResult {
        // Check length
        if password.count < 8 {
            return .tooShort
        }
        
        // Check for weak passwords (case-insensitive)
        if weakPasswords.contains(password.lowercased()) {
            return .tooWeak
        }
        
        // Check for simple patterns
        if isSimplePattern(password) {
            return .tooWeak
        }
        
        // Check if password contains email username (3+ characters)
        if let email = email, let emailUsername = email.split(separator: "@").first {
            let username = String(emailUsername).lowercased()
            if username.count >= 3 && password.lowercased().contains(username) {
                return .policyViolation
            }
        }
        
        return .valid
    }
    
    /// Checks for simple sequential or keyboard patterns
    private static func isSimplePattern(_ password: String) -> Bool {
        let lowercased = password.lowercased()
        
        // Check for all same character
        if Set(lowercased).count == 1 {
            return true
        }
        
        // Check for sequential numbers (e.g., "12345678")
        if lowercased.allSatisfy({ $0.isNumber }) {
            let numbers = lowercased.compactMap { Int(String($0)) }
            if numbers.count >= 4 {
                var isSequential = true
                for i in 1..<numbers.count {
                    if numbers[i] != numbers[i-1] + 1 && numbers[i] != numbers[i-1] - 1 {
                        isSequential = false
                        break
                    }
                }
                if isSequential {
                    return true
                }
            }
        }
        
        // Check for keyboard patterns (e.g., "qwertyui", "asdfgh")
        let keyboardRows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for row in keyboardRows {
            if lowercased.count >= 4 && row.contains(lowercased) {
                return true
            }
        }
        
        return false
    }
}

