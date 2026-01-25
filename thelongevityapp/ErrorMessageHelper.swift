//
//  ErrorMessageHelper.swift
//  thelongevityapp
//
//  Centralized error message management for user-friendly, premium error messages
//

import Foundation
import FirebaseAuth

struct ErrorMessageHelper {
    
    /// Parses backend error response to extract user-friendly message
    static func parseBackendError(_ responseBody: String) -> String? {
        guard let data = responseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // Try to extract message from common error response formats
        if let message = json["message"] as? String {
            return message
        }
        if let error = json["error"] as? String {
            return error
        }
        
        return nil
    }
    
    /// Returns user-friendly error message for APIError
    static func getMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return getMessage(for: apiError)
        }
        
        // Handle Firebase Auth errors
        if let nsError = error as NSError?,
           let errorCode = AuthErrorCode(_bridgedNSError: nsError) {
            return getFirebaseAuthMessage(for: errorCode)
        }
        
        // Generic error
        return "Something went wrong. Please try again."
    }
    
    /// Returns user-friendly error message for APIError
    static func getMessage(for apiError: APIError) -> String {
        switch apiError {
        case .invalidURL(_):
            return "Invalid request. Please try again."
            
        case .invalidResponse(_):
            return "We received an unexpected response. Please try again later."
            
        case .httpError(_, let statusCode, let responseBody):
            // Try to parse backend message first
            if let backendMessage = parseBackendError(responseBody) {
                return backendMessage
            }
            
            // Fallback to status code-based messages
            switch statusCode {
            case 400:
                return "Invalid request. Please check your input and try again."
            case 401:
                return "Your session has expired. Please sign in again."
            case 403:
                // Check if it's subscription required
                let lowercased = responseBody.lowercased()
                if lowercased.contains("subscription_required") || 
                   lowercased.contains("subscription required") {
                    return "An active subscription is required to access this feature."
                }
                return "You don't have permission to perform this action."
            case 404:
                return "The requested resource was not found."
            case 409:
                return "This action conflicts with your current data. Please refresh and try again."
            case 422:
                return "Invalid data provided. Please check your input and try again."
            case 429:
                return "Too many requests. Please wait a moment and try again."
            case 500...599:
                return "Our servers are experiencing issues. Please try again in a few moments."
            default:
                return "An error occurred. Please try again."
            }
            
        case .networkError(_, let underlyingError):
            return getNetworkErrorMessage(for: underlyingError)
            
        case .missingAuthToken:
            return "Your session has expired. Please sign in again."
        }
    }
    
    /// Returns user-friendly network error message
    static func getNetworkErrorMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your network settings and try again."
            case .networkConnectionLost:
                return "Connection lost. Please check your internet connection and try again."
            case .timedOut:
                return "Request timed out. Please check your connection and try again."
            case .cannotConnectToHost:
                return "Unable to connect to our servers. Please try again in a few moments."
            case .cannotFindHost:
                return "Unable to reach our servers. Please check your internet connection."
            case .dnsLookupFailed:
                return "Unable to connect. Please check your internet connection."
            default:
                return "Network error. Please check your connection and try again."
            }
        }
        
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSURLErrorTimedOut:
                return "Request timed out. Please try again."
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection. Please check your network settings."
            case NSURLErrorNetworkConnectionLost:
                return "Connection lost. Please try again."
            case NSURLErrorCannotConnectToHost:
                return "Unable to connect to our servers. Please try again later."
            default:
                return "Network error. Please try again."
            }
        }
        
        return "Network error. Please check your connection and try again."
    }
    
    /// Returns user-friendly Firebase Auth error message
    static func getFirebaseAuthMessage(for errorCode: AuthErrorCode) -> String {
        switch errorCode.code {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .userNotFound:
            return "No account found with this email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .emailAlreadyInUse:
            return "This email is already registered. Please sign in instead."
        case .weakPassword:
            return "Password is too weak. Please choose a stronger password (at least 6 characters)."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .userDisabled:
            return "This account has been disabled. Please contact support."
        case .operationNotAllowed:
            return "This operation is not allowed. Please contact support."
        default:
            return "Authentication error. Please try again."
        }
    }
    
    /// Returns user-friendly message for specific error scenarios
    static func getContextualMessage(for error: Error, context: ErrorContext) -> String {
        let baseMessage = getMessage(for: error)
        
        switch context {
        case .login:
            if let apiError = error as? APIError,
               case .httpError(_, 401, _) = apiError {
                return "Invalid email or password. Please check your credentials and try again."
            }
            return baseMessage
            
        case .signup:
            if let nsError = error as NSError?,
               let errorCode = AuthErrorCode(_bridgedNSError: nsError) {
                switch errorCode.code {
                case .emailAlreadyInUse:
                    return "This email is already registered. Please sign in instead."
                case .weakPassword:
                    return "Password must be at least 6 characters long."
                default:
                    return baseMessage
                }
            }
            return baseMessage
            
        case .dailyCheckIn:
            if let apiError = error as? APIError,
               case .httpError(_, 409, _) = apiError {
                return "You've already completed today's check-in. Come back tomorrow!"
            }
            return baseMessage
            
        case .onboarding:
            return baseMessage
            
        case .subscription:
            if let apiError = error as? APIError,
               case .httpError(_, 403, let responseBody) = apiError {
                let lowercased = responseBody.lowercased()
                if lowercased.contains("subscription_required") {
                    return "An active subscription is required to access this feature."
                }
            }
            return baseMessage
            
        case .deleteAccount:
            if let apiError = error as? APIError,
               case .httpError(_, 403, let responseBody) = apiError {
                let lowercased = responseBody.lowercased()
                if lowercased.contains("email_verification_required") || 
                   lowercased.contains("email verification") {
                    return "Email verification is required to delete your account."
                }
            }
            return baseMessage
            
        case .general:
            return baseMessage
        }
    }
}

enum ErrorContext {
    case login
    case signup
    case dailyCheckIn
    case onboarding
    case subscription
    case deleteAccount
    case general
}

