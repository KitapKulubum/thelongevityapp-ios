//
//  AgeModels.swift
//  thelongevityapp
//
//  Created on 4.12.2025.
//

import Foundation

// Trend range enum
enum TrendRange: String, CaseIterable, Hashable {
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

// Trend point model
struct TrendPoint: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let biologicalAgeYears: Double
    let agingDebtYears: Double
}

// Trend response model
struct TrendResponse: Decodable {
    let range: String
    let points: [TrendPoint]
    let summary: TrendSummary
    
    struct TrendSummary: Decodable {
        let currentBiologicalAgeYears: Double
        let agingDebtYears: Double
        let rejuvenationStreakDays: Int
        let accelerationStreakDays: Int
        let totalRejuvenationDays: Int
        let totalAccelerationDays: Int
    }
}

// Chat request model
struct ChatRequest: Encodable {
    let userId: String
    let message: String
}

// Chat response model
struct ChatResponse: Decodable {
    let answer: String
}

// Age state response model
struct AgeStateResponse: Decodable {
    let profile: AgeProfile
    let state: AgeState
    let today: TodayEntry?
    
    struct AgeProfile: Decodable {
        let chronologicalAgeYears: Double
        let baselineBiologicalAgeYears: Double
    }
    
    struct AgeState: Decodable {
        let currentBiologicalAgeYears: Double
        let agingDebtYears: Double
        let rejuvenationStreakDays: Int
        let accelerationStreakDays: Int
        let totalRejuvenationDays: Int
        let totalAccelerationDays: Int
    }
    
    struct TodayEntry: Decodable {
        let deltaYears: Double
        let reasons: [String]
    }
}

