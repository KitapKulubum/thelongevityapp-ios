//
//  DailyUpdateRequest.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation

struct DailyUpdateRequest: Encodable {
    let userId: String
    let chronologicalAgeYears: Double
    let metrics: Metrics
    
    struct Metrics: Encodable {
        var date: String
        var sleepHours: Double
        var steps: Int
        var vigorousMinutes: Int
        var processedFoodScore: Int
        var alcoholUnits: Int
        var stressLevel: Int
        var lateCaffeine: Bool
        var screenLate: Bool
        var bedtimeHour: Double
    }
}

