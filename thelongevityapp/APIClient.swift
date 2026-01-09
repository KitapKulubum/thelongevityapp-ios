//
//  APIClient.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import Foundation
import FirebaseAuth

final class APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    private var baseURL: URL {
        #if DEBUG
        // Use 127.0.0.1 instead of localhost for iOS Simulator compatibility
        return URL(string: "http://127.0.0.1:4000")!
        #else
        return URL(string: "https://api.yourproductiondomain.com")!
        #endif
    }
    
    func postAuthMe(idToken: String, firstName: String? = nil, lastName: String? = nil, dateOfBirth: Date? = nil) async throws -> AuthProfileResponse {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("auth").appendingPathComponent("me")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format dateOfBirth as "yyyy-MM-dd" if provided
        let dateOfBirthString: String?
        if let date = dateOfBirth {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateOfBirthString = formatter.string(from: date)
        } else {
            dateOfBirthString = nil
        }
        
        let request = AuthMeRequest(
            idToken: idToken,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirthString
        )
        urlRequest.httpBody = try JSONEncoder().encode(request)
        addAuthHeader(&urlRequest, token: idToken)
        return try await perform(urlRequest, as: AuthProfileResponse.self, endpoint: "/api/auth/me")
    }
    
    func postLogout() async throws {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("auth").appendingPathComponent("logout")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? await AuthManager.shared.getIDToken() {
            addAuthHeader(&urlRequest, token: token)
        }
        _ = try await perform(urlRequest, as: EmptyResponse.self, endpoint: "/api/auth/logout")
    }
    
    func postOnboarding(_ request: OnboardingSubmitRequest) async throws -> OnboardingResultDTO {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("onboarding").appendingPathComponent("submit")
        let urlRequest = try await authorizedRequest(url: url, method: "POST", body: request)
        return try await perform(urlRequest, as: OnboardingResultDTO.self, endpoint: "/api/onboarding/submit")
    }
    
    func postDaily(_ request: DailySubmitRequest) async throws -> DailyResultDTO {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("age").appendingPathComponent("daily-update")
        let urlRequest = try await authorizedRequest(url: url, method: "POST", body: request)
        return try await perform(urlRequest, as: DailyResultDTO.self, endpoint: "/api/age/daily-update")
    }
    
    func getSummary() async throws -> StatsSummaryResponse {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("stats").appendingPathComponent("summary")
        let urlRequest = try await authorizedRequest(url: url, method: "GET", body: nil as Data?)
        return try await perform(urlRequest, as: StatsSummaryResponse.self, endpoint: "/api/stats/summary")
    }
    
    func patchProfile(timezone: String) async throws -> AuthProfileResponse {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("auth").appendingPathComponent("profile")
        var urlRequest = try await authorizedRequest(url: url, method: "PATCH", body: nil as Data?)
        
        let requestBody = ProfileUpdateRequest(timezone: timezone)
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)
        
        return try await perform(urlRequest, as: AuthProfileResponse.self, endpoint: "/api/auth/profile")
    }
    
    func fetchTrends() async throws -> TrendsResponse {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("longevity").appendingPathComponent("trends")
        let urlRequest = try await authorizedRequest(url: url, method: "GET", body: nil as Data?)
        return try await perform(urlRequest, as: TrendsResponse.self, endpoint: "/api/longevity/trends")
    }
    
    func getDeltaAnalytics(range: String) async throws -> DeltaAnalyticsResponse {
        guard ["weekly", "monthly", "yearly"].contains(range) else {
            throw APIError.invalidURL(endpoint: "/api/analytics/delta")
        }
        
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("analytics").appendingPathComponent("delta")
            .appending(queryItems: [URLQueryItem(name: "range", value: range)])
        
        let urlRequest = try await authorizedRequest(url: url, method: "GET", body: nil as Data?)
        
        // Log full response before decoding
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse(endpoint: "/api/analytics/delta")
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8) ?? "(unable to decode)"
                throw APIError.httpError(endpoint: "/api/analytics/delta", statusCode: httpResponse.statusCode, responseBody: responseBody)
            }
            
            // Log full response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("[APIClient] Full response for /api/analytics/delta: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            
            // Determine response type based on range and decode accordingly
            if range == "yearly" {
                let yearlyResponse = try decoder.decode(YearlyDeltaResponse.self, from: data)
                return .yearly(yearlyResponse)
            } else {
                let dailyResponse = try decoder.decode(WeeklyDeltaResponse.self, from: data)
                if range == "weekly" {
                    return .weekly(dailyResponse)
                } else {
                    return .monthly(dailyResponse)
                }
            }
        } catch let decodingError as DecodingError {
            print("[APIClient] /api/analytics/delta failed: Decoding error")
            printDecodingError(decodingError, endpoint: "/api/analytics/delta")
            throw APIError.invalidResponse(endpoint: "/api/analytics/delta")
        } catch let error as APIError {
            throw error
        } catch {
            print("[APIClient] /api/analytics/delta failed: \(error.localizedDescription)")
            throw APIError.networkError(endpoint: "/api/analytics/delta", underlyingError: error)
        }
    }
}

// MARK: - API Error Types
enum APIError: LocalizedError {
    case invalidURL(endpoint: String)
    case invalidResponse(endpoint: String)
    case httpError(endpoint: String, statusCode: Int, responseBody: String)
    case networkError(endpoint: String, underlyingError: Error)
    case missingAuthToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let endpoint):
            return "Invalid URL for \(endpoint)"
        case .invalidResponse(let endpoint):
            return "Invalid response from \(endpoint). The server returned data in an unexpected format."
        case .httpError(let endpoint, let statusCode, _):
            return "\(endpoint) returned status code \(statusCode)"
        case .networkError(let endpoint, let error):
            return "Network error for \(endpoint): \(error.localizedDescription)"
        case .missingAuthToken:
            return "Authorization token is missing. Please sign in again."
        }
    }
}

// MARK: - Private helpers
private extension APIClient {
    func authorizedRequest<T: Encodable>(url: URL, method: String, body: T?) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        let token = try await AuthManager.shared.getIDToken()
        addAuthHeader(&request, token: token)
        return request
    }
    
    func authorizedRequest(url: URL, method: String, body: Data?) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let token = try await AuthManager.shared.getIDToken()
        addAuthHeader(&request, token: token)
        return request
    }
    
    func addAuthHeader(_ request: inout URLRequest, token: String) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    private func printDecodingError(_ error: DecodingError, endpoint: String) {
        switch error {
        case .typeMismatch(let type, let context):
            print("[APIClient] DECODING ERROR - Type Mismatch:")
            print("  Expected type: \(type)")
            print("  Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("  Debug: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                print("  Underlying error: \(underlyingError)")
            }
        case .valueNotFound(let type, let context):
            print("[APIClient] DECODING ERROR - Value Not Found:")
            print("  Expected type: \(type)")
            print("  Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("  Debug: \(context.debugDescription)")
            print("  ⚠️ Backend is returning null for required field: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .keyNotFound(let key, let context):
            print("[APIClient] DECODING ERROR - Key Not Found:")
            print("  Missing key: \(key.stringValue)")
            print("  Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("  Debug: \(context.debugDescription)")
            print("  ⚠️ Backend is missing required field: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .dataCorrupted(let context):
            print("[APIClient] DECODING ERROR - Data Corrupted:")
            print("  Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("  Debug: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                print("  Underlying error: \(underlyingError)")
                if let nsError = underlyingError as NSError? {
                    print("  Error domain: \(nsError.domain)")
                    print("  Error code: \(nsError.code)")
                    print("  Error userInfo: \(nsError.userInfo)")
                }
            }
            print("  ⚠️ Backend is returning invalid data format at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        @unknown default:
            print("[APIClient] DECODING ERROR - Unknown: \(error)")
        }
    }
    
    func perform<T: Decodable>(_ request: URLRequest, as type: T.Type, endpoint: String) async throws -> T {
        print("[APIClient] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
                print("[APIClient] \(endpoint) failed: Invalid response type")
                throw APIError.invalidResponse(endpoint: endpoint)
        }
        
        guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8) ?? "(unable to decode)"
                print("[APIClient] \(endpoint) failed: \(httpResponse.statusCode)")
                print("[APIClient] Response body: \(responseBody)")
                throw APIError.httpError(endpoint: endpoint, statusCode: httpResponse.statusCode, responseBody: responseBody)
            }
            
            let decoder = JSONDecoder()
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("[APIClient] Raw response for \(endpoint): \(responseString.prefix(500))")
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let decodingError as DecodingError {
            // Decoding errors are not network errors - they indicate backend data format issues
            print("[APIClient] \(endpoint) failed: Decoding error")
            printDecodingError(decodingError, endpoint: endpoint)
            throw APIError.invalidResponse(endpoint: endpoint)
        } catch {
            print("[APIClient] \(endpoint) failed: \(error.localizedDescription)")
            throw APIError.networkError(endpoint: endpoint, underlyingError: error)
        }
    }
}

// MARK: - DTOs
struct AuthMeRequest: Codable {
    let idToken: String
    let firstName: String?
    let lastName: String?
    let dateOfBirth: String?  // Format: "yyyy-MM-dd"
}

struct AuthProfileResponse: Codable {
    let uid: String
    let email: String?
    let hasCompletedOnboarding: Bool
    let profile: ProfileInfo?
    
    struct ProfileInfo: Codable {
        let firstName: String?
        let lastName: String?
        let chronologicalAgeYears: Double?
        let timezone: String?  // IANA timezone identifier (e.g., "Europe/Istanbul")
    }
}

struct EmptyResponse: Codable {
    // Empty response for logout
}

struct ProfileUpdateRequest: Codable {
    let timezone: String  // IANA timezone identifier
}

