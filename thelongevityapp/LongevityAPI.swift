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
    
    private let baseURL = URL(string: "http://localhost:4000")!
    
    func submitDailyUpdate(_ requestBody: DailyUpdateRequest,
                          completion: @escaping (Result<BiologicalAgeState, Error>) -> Void) {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("age").appendingPathComponent("daily-update")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format today as YYYY-MM-DD
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        // Convert simplified request to full backend structure
        let metrics = DailyUpdateRequestBackend.Metrics(
            date: today,
            sleepHours: requestBody.sleepHours,
            steps: requestBody.steps,
            vigorousMinutes: requestBody.vigorousMinutes,
            processedFoodScore: 3,
            alcoholUnits: 0,
            stressLevel: requestBody.stressLevel,
            lateCaffeine: requestBody.lateCaffeine,
            screenLate: requestBody.lateScreenUsage,
            bedtimeHour: 22.0 // Default bedtime
        )
        
        let backendBody = DailyUpdateRequestBackend(
            userId: requestBody.userId,
            chronologicalAgeYears: 32,
            metrics: metrics
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(backendBody)
        } catch {
            print("[LongevityAPI] Encoding error:", error)
            completion(.failure(error))
            return
        }
        
        print("[LongevityAPI] Sending daily update to", url)
        if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("[LongevityAPI] Request body:", bodyString)
        } else {
            print("[LongevityAPI] Request body: nil or invalid encoding")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[LongevityAPI] Network error:", error)
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[LongevityAPI] Status code:", httpResponse.statusCode)
            }
            
            guard let data = data else {
                print("[LongevityAPI] No data received from server")
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("[LongevityAPI] Response body:", raw)
            }
            
            do {
                let decoded = try JSONDecoder().decode(AgeStateResponse.self, from: data)
                completion(.success(decoded.state))
            } catch {
                print("[LongevityAPI] Decoding error:", error)
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchAgeState(userId: String,
                      completion: @escaping (Result<AgeStateResponse, Error>) -> Void) {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("age").appendingPathComponent("state")
            .appending(queryItems: [
                URLQueryItem(name: "userId", value: userId),
                URLQueryItem(name: "chronologicalAgeYears", value: "32")
            ])
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Age state error:", error)
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "LongevityAPI",
                                            code: -2,
                                            userInfo: [NSLocalizedDescriptionKey: "No data from server."])))
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("Age state response:", raw)
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(AgeStateResponse.self, from: data)
                completion(.success(response))
            } catch {
                print("Decode error:", error)
                completion(.failure(error))
            }
        }.resume()
    }
}

// Backend request structure (internal use only)
struct DailyUpdateRequestBackend: Encodable {
    let userId: String
    let chronologicalAgeYears: Double
    let metrics: Metrics
    
    struct Metrics: Encodable {
        let date: String
        let sleepHours: Double
        let steps: Int
        let vigorousMinutes: Int
        let processedFoodScore: Int
        let alcoholUnits: Int
        let stressLevel: Int
        let lateCaffeine: Bool
        let screenLate: Bool
        let bedtimeHour: Double
    }
}
