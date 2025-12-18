//
//  LongevityAPI.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation

final class LongevityAPI {
    static let shared = LongevityAPI()
    
    private init() {}
    
    // Base URL configuration based on build configuration
    private var baseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:4000")!
        #else
        // TODO: Replace with production URL when ready
        return URL(string: "https://api.yourproductiondomain.com")!
        #endif
    }
    
    func submitDailyUpdate(_ requestBody: DailyUpdateRequest,
                          completion: @escaping (Result<AgeStateResponse, Error>) -> Void) {
        // Get userId from Firebase Auth
        guard let userId = AuthManager.shared.userId else {
            print("Missing userId, cannot send daily update")
            let error = NSError(domain: "LongevityAPI",
                               code: -3,
                               userInfo: [NSLocalizedDescriptionKey: "User ID is missing. Please sign in."])
            completion(.failure(error))
            return
        }
        
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("age").appendingPathComponent("daily-update")
        
        // Debug: Print request URL
        print("[LongevityAPI] Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build payload with authenticated userId
        let payload = DailyUpdateRequest(
            userId: userId,
            chronologicalAgeYears: requestBody.chronologicalAgeYears,
            metrics: requestBody.metrics
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            
            // Debug: Print request JSON body
            if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
                print("[LongevityAPI] Request JSON body: \(jsonString)")
            } else {
                print("[LongevityAPI] Request JSON body: (unable to convert to string)")
            }
        } catch {
            print("[LongevityAPI] Encoding error:", error)
            completion(.failure(error))
            return
        }
        
        print("Sent daily update for user \(userId)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[LongevityAPI] Network error:", error)
                completion(.failure(error))
                return
            }
            
            // Check HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[LongevityAPI] Invalid response type")
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            // Debug: Print HTTP status code
            print("[LongevityAPI] HTTP Status code: \(httpResponse.statusCode)")
            
            // Check if status code is 200
            guard httpResponse.statusCode == 200 else {
                print("[LongevityAPI] Non-200 status code: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: httpResponse.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                print("[LongevityAPI] No data received from server")
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            // Debug: Print response body (string)
            if let responseString = String(data: data, encoding: .utf8) {
                print("[LongevityAPI] Response body: \(responseString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(AgeStateResponse.self, from: data)
                print("[LongevityAPI] ✅ Daily update response decoded successfully")
                print("[LongevityAPI] Profile: chronological=\(decoded.profile.chronologicalAgeYears), baseline=\(decoded.profile.baselineBiologicalAgeYears)")
                print("[LongevityAPI] State: biological=\(decoded.state.currentBiologicalAgeYears), debt=\(decoded.state.agingDebtYears), streak=\(decoded.state.rejuvenationStreakDays)")
                completion(.success(decoded))
            } catch let decodingError as DecodingError {
                print("[LongevityAPI] Decode error details:")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("  Type mismatch: expected \(type), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("  Value not found: \(type), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("  Key not found: \(key.stringValue), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("  Data corrupted: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                @unknown default:
                    print("  Unknown decoding error: \(decodingError)")
                }
                let error = NSError(domain: "LongevityAPI",
                                   code: -4,
                                   userInfo: [NSLocalizedDescriptionKey: "Failed to decode daily update response: \(decodingError.localizedDescription)"])
                completion(.failure(error))
            } catch {
                print("[LongevityAPI] Decode error:", error)
                completion(.failure(error))
            }
        }.resume()
    }
    
    func sendChatMessage(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = AuthManager.shared.userId else {
            completion(.failure(NSError(domain: "LongevityAPI", code: -3, userInfo: [NSLocalizedDescriptionKey: "User ID missing"])))
            return
        }
        
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ChatRequest(userId: userId, message: message)
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "LongevityAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
                completion(.success(decoded.answer))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchAgeState(userId: String, completion: @escaping (Result<AgeStateResponse, Error>) -> Void) {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("age").appendingPathComponent("state").appendingPathComponent(userId)
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Age state error:", error)
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: httpResponse.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -2,
                                            userInfo: [NSLocalizedDescriptionKey: "No data from server."])))
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("[LongevityAPI] Age state response:", raw)
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(AgeStateResponse.self, from: data)
                completion(.success(response))
            } catch let decodingError as DecodingError {
                print("[LongevityAPI] Decode error details:")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("  Type mismatch: expected \(type), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("  Value not found: \(type), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("  Key not found: \(key.stringValue), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("  Data corrupted: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                @unknown default:
                    print("  Unknown decoding error: \(decodingError)")
                }
                let error = NSError(domain: "LongevityAPI",
                                   code: -4,
                                   userInfo: [NSLocalizedDescriptionKey: "Failed to decode response: \(decodingError.localizedDescription)"])
                completion(.failure(error))
            } catch {
                print("[LongevityAPI] Decode error:", error)
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchTrend(userId: String, range: TrendRange, completion: @escaping (Result<TrendResponse, Error>) -> Void) {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("age").appendingPathComponent("trend").appendingPathComponent(userId)
            .appending(queryItems: [
                URLQueryItem(name: "range", value: range.rawValue)
            ])
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Trend error:", error)
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: httpResponse.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -2,
                                            userInfo: [NSLocalizedDescriptionKey: "No data from server."])))
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("[LongevityAPI] Trend response:", raw)
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TrendResponse.self, from: data)
                completion(.success(response))
            } catch let decodingError as DecodingError {
                print("[LongevityAPI] Trend decode error details:")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("  Type mismatch: expected \(type), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("  Value not found: \(type), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("  Key not found: \(key.stringValue), context: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("  Data corrupted: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                @unknown default:
                    print("  Unknown decoding error: \(decodingError)")
                }
                let error = NSError(domain: "LongevityAPI",
                                   code: -4,
                                   userInfo: [NSLocalizedDescriptionKey: "Failed to decode trend response: \(decodingError.localizedDescription)"])
                completion(.failure(error))
            } catch {
                print("[LongevityAPI] Trend decode error:", error)
                completion(.failure(error))
            }
        }.resume()
    }
}

// Daily update request payload matches backend expectation
