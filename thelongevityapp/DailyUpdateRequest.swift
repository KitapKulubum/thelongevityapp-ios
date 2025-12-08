//
//  DailyUpdateRequest.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation

struct DailyUpdateRequest: Encodable {
    let userId: String
    let sleepHours: Double
    let steps: Int
    let vigorousMinutes: Int
    let stressLevel: Int
    let lateCaffeine: Bool
    let lateScreenUsage: Bool
}

