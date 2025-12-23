//
//  APIClient.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import Foundation

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
    
    func postOnboarding(_ request: OnboardingSubmitRequest) async throws -> OnboardingResultDTO {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("onboarding").appendingPathComponent("submit")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        print("[APIClient] POST \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[APIClient] POST /api/onboarding/submit failed: Invalid response type")
                throw APIError.invalidResponse(endpoint: "/api/onboarding/submit")
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8) ?? "(unable to decode)"
                print("[APIClient] POST /api/onboarding/submit failed: \(httpResponse.statusCode)")
                print("[APIClient] Response body: \(responseBody)")
                throw APIError.httpError(endpoint: "/api/onboarding/submit", statusCode: httpResponse.statusCode, responseBody: responseBody)
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(OnboardingResultDTO.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            print("[APIClient] POST /api/onboarding/submit failed: \(error.localizedDescription)")
            throw APIError.networkError(endpoint: "/api/onboarding/submit", underlyingError: error)
        }
    }
    
    func postDaily(_ request: DailySubmitRequest) async throws -> DailyResultDTO {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("daily").appendingPathComponent("submit")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        print("[APIClient] POST \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[APIClient] POST /api/daily/submit failed: Invalid response type")
                throw APIError.invalidResponse(endpoint: "/api/daily/submit")
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8) ?? "(unable to decode)"
                print("[APIClient] POST /api/daily/submit failed: \(httpResponse.statusCode)")
                print("[APIClient] Response body: \(responseBody)")
                throw APIError.httpError(endpoint: "/api/daily/submit", statusCode: httpResponse.statusCode, responseBody: responseBody)
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(DailyResultDTO.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            print("[APIClient] POST /api/daily/submit failed: \(error.localizedDescription)")
            throw APIError.networkError(endpoint: "/api/daily/submit", underlyingError: error)
        }
    }
    
    func getSummary(userId: String) async throws -> SummaryDTO {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api").appendingPathComponent("stats").appendingPathComponent("summary"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = urlComponents.url else {
            throw APIError.invalidURL(endpoint: "/api/stats/summary")
        }
        
        print("[APIClient] GET \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[APIClient] GET /api/stats/summary failed: Invalid response type")
                throw APIError.invalidResponse(endpoint: "/api/stats/summary")
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8) ?? "(unable to decode)"
                print("[APIClient] GET /api/stats/summary failed: \(httpResponse.statusCode)")
                print("[APIClient] Response body: \(responseBody)")
                throw APIError.httpError(endpoint: "/api/stats/summary", statusCode: httpResponse.statusCode, responseBody: responseBody)
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(SummaryDTO.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            print("[APIClient] GET /api/stats/summary failed: \(error.localizedDescription)")
            throw APIError.networkError(endpoint: "/api/stats/summary", underlyingError: error)
        }
    }
}

// MARK: - API Error Types
enum APIError: LocalizedError {
    case invalidURL(endpoint: String)
    case invalidResponse(endpoint: String)
    case httpError(endpoint: String, statusCode: Int, responseBody: String)
    case networkError(endpoint: String, underlyingError: Error)
    
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
        }
    }
}
