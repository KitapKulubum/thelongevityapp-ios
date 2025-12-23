//
//  DailyCheckinService.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation

final class DailyCheckinService {
    static let shared = DailyCheckinService()
    
    private init() {}
    
    // Base URL configuration based on build configuration
    private var baseURL: URL {
        #if DEBUG
        // Use 127.0.0.1 instead of localhost for iOS Simulator compatibility
        return URL(string: "http://127.0.0.1:4000")!
        #else
        // TODO: Replace with production URL when ready
        return URL(string: "https://api.yourproductiondomain.com")!
        #endif
    }
    
    func submitDailyCheckin(
        date: String,
        sleepHours: Double,
        steps: Int,
        vigorousMinutes: Int,
        processedFoodScore: Int,
        alcoholUnits: Int,
        stressLevel: Int,
        lateCaffeine: Bool,
        screenLate: Bool,
        bedtimeHour: Double,
        completion: @escaping (Result<DailyAgeResponse, Error>) -> Void
    ) {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("age").appendingPathComponent("daily-update")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the exact JSON payload structure
        let metrics = DailyCheckinMetrics(
            date: date,
            sleepHours: sleepHours,
            steps: steps,
            vigorousMinutes: vigorousMinutes,
            processedFoodScore: processedFoodScore,
            alcoholUnits: alcoholUnits,
            stressLevel: stressLevel,
            lateCaffeine: lateCaffeine,
            screenLate: screenLate,
            bedtimeHour: bedtimeHour
        )
        
        let requestBody = DailyCheckinRequest(metrics: metrics)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
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
                completion(.failure(NSError(domain: "DailyCheckinService",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(DailyAgeResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// Request structure matching the exact JSON payload
private struct DailyCheckinRequest: Encodable {
    let metrics: DailyCheckinMetrics
}

private struct DailyCheckinMetrics: Encodable {
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

// Response model
struct DailyAgeResponse: Decodable {
    let state: BiologicalAgeState
    let today: TodayEntry?
}

