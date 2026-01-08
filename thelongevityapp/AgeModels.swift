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

// Period enum for trends API
enum Period: String, CaseIterable {
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

// Trend point model (legacy - for old API)
struct TrendPoint: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let biologicalAgeYears: Double
    let agingDebtYears: Double
}

// New Trends API Models
struct TrendPointNew: Decodable, Identifiable {
    var id: String { date }
    let date: String  // YYYY-MM-DD format
    let biologicalAge: Double
}

struct TrendBucket: Decodable {
    let value: Double?  // Can be null if not available
    let available: Bool
    let projection: Bool?  // Only present for yearly when < 365 entries
    let points: [TrendPointNew]?  // Optional array of chart points
}

struct TrendsResponse: Decodable {
    let weekly: TrendBucket
    let monthly: TrendBucket
    let yearly: TrendBucket
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
    let hasCompletedOnboarding: Bool?  // Backend returns this field to indicate onboarding status (optional for backward compatibility)
    
    // Computed property to safely get onboarding status
    var onboardingStatus: Bool {
        // If hasCompletedOnboarding is explicitly set, use it
        if let status = hasCompletedOnboarding {
            return status
        }
        // Otherwise, infer from baselineBiologicalAgeYears (if it exists, onboarding is complete)
        return state.baselineBiologicalAgeYears != nil
    }
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

// MARK: - Delta Analytics Models

struct DeltaDailyPoint: Decodable {
    let date: String  // YYYY-MM-DD format
    let dailyDeltaYears: Double?  // Can be null for missing days (renamed from delta)
}

struct DeltaMonthlyPoint: Decodable {
    let month: String  // YYYY-MM format
    let rangeNetDeltaYears: Double  // Net delta for this month only (renamed from netDelta)
    let checkIns: Int
    let avgDeltaPerCheckIn: Double
}

struct DeltaSummary: Decodable {
    let netDeltaYears: Double  // Baseline dahil toplam delta (renamed from netDelta)
    let rangeNetDeltaYears: Double?  // Sadece seçili range içindeki delta (optional - backend'den gelmeyebilir)
    let rejuvenationYears: Double  // Sum of positive deltas (renamed from rejuvenation)
    let agingYears: Double  // Sum of absolute negative deltas (renamed from aging)
    let checkIns: Int
    let avgDeltaPerCheckIn: Double
}

// Weekly/Monthly Response
struct WeeklyDeltaResponse: Decodable {
    let range: String
    let timezone: String
    let baselineDeltaYears: Double  // Root level: Onboarding'deki baseline delta
    let totalDeltaYears: Double  // Root level: Baseline + tüm daily deltas
    let entriesCount: Int?  // Total entries count (optional, backend'den gelmeyebilir)
    let entriesInRange: Int?  // Entries in selected range (optional, backend'den gelmeyebilir)
    let start: String?  // Optional - backend'den gelmeyebilir
    let end: String?  // Optional - backend'den gelmeyebilir
    let series: [DeltaDailyPoint]?  // Optional - backend response'unda olmayabilir
    let summary: DeltaSummary
}

// Monthly Response (same structure as weekly)
typealias MonthlyDeltaResponse = WeeklyDeltaResponse

// Yearly Response
struct YearlyDeltaResponse: Decodable {
    let range: String
    let timezone: String
    let baselineDeltaYears: Double  // Root level: Onboarding'deki baseline delta
    let totalDeltaYears: Double  // Root level: Baseline + tüm daily deltas
    let entriesCount: Int?  // Total entries count (optional, backend'den gelmeyebilir)
    let entriesInRange: Int?  // Entries in selected range (optional, backend'den gelmeyebilir)
    let start: String?  // Optional - backend'den gelmeyebilir
    let end: String?  // Optional - backend'den gelmeyebilir
    let series: [DeltaMonthlyPoint]?  // Optional - backend response'unda olmayabilir
    let summary: DeltaSummary
}

// Union type for response
enum DeltaAnalyticsResponse {
    case weekly(WeeklyDeltaResponse)
    case monthly(MonthlyDeltaResponse)
    case yearly(YearlyDeltaResponse)
}

