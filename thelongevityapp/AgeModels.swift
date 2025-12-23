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

struct DailyAnswersPayload: Codable {
    let sleep: Double
    let movement: Double
    let foodQuality: Double
    let sugar: Double
    let stress: Double
    let mentalLoad: Double
    let moodSocial: Double
    let bodyFeel: Double
    let inflammationSignal: Double
    let selfCare: Double
}

struct OnboardingSubmitRequest: Codable {
    let userId: String
    let chronologicalAge: Int
    let answers: OnboardingAnswersPayload
}

struct OnboardingResultDTO: Codable {
    let totalScore: Double
    let BAOYears: Double
    let biologicalAge: Double
    let agingSpeedLabel: String
    let systemScores: [String: Double]
    let topRiskSystems: [String]
}

struct DailySubmitRequest: Codable {
    let userId: String
    let date: String // "YYYY-MM-DD"
    let answers: DailyAnswersPayload
}

struct DailyResultDTO: Codable {
    let dailyScore: Double
    let dailyAgingDays: Double
    let ema7: Double
    let ema30: Double
    let trendLabel: String
}

struct SummaryDTO: Codable {
    let biologicalAge: Double?
    let BAOYears: Double?
    let ema7: Double?
    let ema30: Double?
    let trendLabel: String?
    let topRiskSystems: [String]?
}

