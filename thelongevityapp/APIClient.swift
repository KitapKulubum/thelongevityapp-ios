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
    
    func postAuthMe(idToken: String) async throws -> AuthProfileResponse {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("auth").appendingPathComponent("me")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(AuthMeRequest(idToken: idToken))
        addAuthHeader(&urlRequest, token: idToken)
        return try await perform(urlRequest, as: AuthProfileResponse.self, endpoint: "/api/auth/me")
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
        let urlRequest = try await authorizedRequest(url: url, method: "GET", body: Optional<Data>.none as Data?)
        return try await perform(urlRequest, as: StatsSummaryResponse.self, endpoint: "/api/stats/summary")
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
            return "Invalid response from \(endpoint)"
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
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            print("[APIClient] \(endpoint) failed: \(error.localizedDescription)")
            throw APIError.networkError(endpoint: endpoint, underlyingError: error)
        }
    }
}

// MARK: - DTOs
struct AuthMeRequest: Codable {
    let idToken: String
}

struct AuthProfileResponse: Codable {
    let uid: String
    let email: String?
    let profile: [String: String]?
}

