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

// Trend response model (legacy)
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

// MARK: - Stats Summary & History

struct HistoryPoint: Codable, Identifiable, Equatable {
    var id = UUID()
    let date: String
    let biologicalAgeYears: Double
    let deltaYears: Double
    let score: Double  // Changed from Int to Double to support decimal values like 2.5
    
    enum CodingKeys: String, CodingKey {
        case date
        case biologicalAgeYears
        case deltaYears
        case score
        // id is excluded - it's generated locally, not from backend
    }
    
    // Custom Equatable implementation - compare data fields, not id
    static func == (lhs: HistoryPoint, rhs: HistoryPoint) -> Bool {
        return lhs.date == rhs.date &&
               lhs.biologicalAgeYears == rhs.biologicalAgeYears &&
               lhs.deltaYears == rhs.deltaYears &&
               lhs.score == rhs.score
    }
}

struct BiologicalAgeState: Codable, Equatable {
    let chronologicalAgeYears: Double
    let baselineBiologicalAgeYears: Double?  // Optional for new users who haven't completed onboarding
    let currentBiologicalAgeYears: Double?    // Optional for new users who haven't completed onboarding
    let agingDebtYears: Double
    let rejuvenationStreakDays: Int
    let accelerationStreakDays: Int
    let totalRejuvenationDays: Int
    let totalAccelerationDays: Int
}

struct TodayEntry: Codable, Equatable {
    let date: String
    let score: Double  // Changed from Int to Double to support decimal values like -8.5
    let deltaYears: Double
    let reasons: [String]
}

struct StatsSummaryResponse: Codable, Equatable {
    let userId: String
    let state: BiologicalAgeState
    let today: TodayEntry?
    let weeklyHistory: [HistoryPoint]
    let monthlyHistory: [HistoryPoint]
    let yearlyHistory: [HistoryPoint]
}

// Chat request/response kept for potential future use
struct ChatRequest: Encodable {
    let message: String
}
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

// MARK: - Onboarding & Daily Check-in Models

enum AnswerValue: Double, CaseIterable, Codable {
    case minus1 = -1.0
    case minusHalf = -0.5
    case zero = 0.0
    case plusHalf = 0.5
    case plus1 = 1.0
}

struct OptionItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: AnswerValue
}

struct OnboardingQuestion: Identifiable {
    let id: String
    let prompt: String
    let options: [OptionItem]
}

struct DailyQuestion: Identifiable {
    let id: String
    let prompt: String
    let options: [OptionItem]
}

struct OnboardingAnswersPayload: Codable {
    let sleep: Double
    let activity: Double
    let muscle: Double
    let visceralFat: Double
    let nutritionPattern: Double
    let sugar: Double
    let stress: Double
    let smokingAlcohol: Double
    let metabolicHealth: Double
    let energyFocus: Double
}

struct DailyMetricsPayload: Codable {
    // Note: date field removed - backend computes it based on user's timezone
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

struct OnboardingSubmitRequest: Codable {
    let chronologicalAgeYears: Double
    let answers: OnboardingAnswersPayload
}

struct OnboardingResultDTO: Codable {
    let userId: String
    let chronologicalAgeYears: Double
    let baselineBiologicalAgeYears: Double
    let currentBiologicalAgeYears: Double
    let BAOYears: Double
    let totalScore: Double
}

struct DailySubmitRequest: Codable {
    let metrics: DailyMetricsPayload
}

struct DailyResultDTO: Codable {
    let state: BiologicalAgeState
    let today: TodayEntry?
}

