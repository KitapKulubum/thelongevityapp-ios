//
//  ChatViewModel.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import Foundation
import SwiftUI

enum ChatMode {
    case onboarding
    case daily
}

enum ChatRole {
    case user
    case assistant
}

enum SubmitState {
    case idle
    case loading
    case failed(errorMessage: String)
    case success
}

enum SubmitAction {
    case submitOnboarding
    case submitDaily
}

enum DailyCheckInState {
    case inactive
    case active(expanded: Bool)
    case completed
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String
    let timestamp: Date
    
    var isUser: Bool { role == .user }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var mode: ChatMode = .daily
    @Published var currentOnboardingQuestionIndex: Int = 0
    @Published var onboardingAnswers: [String: Double] = [:]
    @Published var currentDailyQuestionIndex: Int = 0
    @Published var dailyAnswers: [String: Double] = [:]
    @Published var dailyCheckInState: DailyCheckInState = .inactive
    @Published var isSubmitting: Bool = false
    @Published var submitState: SubmitState = .idle
    
    var appState: AppState
    
    // Cached requests for retry
    private var cachedOnboardingRequest: OnboardingSubmitRequest?
    private var cachedDailyRequest: DailySubmitRequest?
    private var lastFailedAction: SubmitAction?
    
    var currentOnboardingQuestion: OnboardingQuestion? {
        guard mode == .onboarding,
              currentOnboardingQuestionIndex < QuestionBanks.onboardingQuestions.count else {
            return nil
        }
        return QuestionBanks.onboardingQuestions[currentOnboardingQuestionIndex]
    }
    
    var currentDailyQuestion: DailyQuestion? {
        guard case .active(let expanded) = dailyCheckInState,
              expanded,
              currentDailyQuestionIndex < QuestionBanks.dailyQuestions.count else {
            return nil
        }
        return QuestionBanks.dailyQuestions[currentDailyQuestionIndex]
    }
    
    var chatInputEnabled: Bool {
        // Disable chat input only when daily check-in is active AND expanded
        if case .active(let expanded) = dailyCheckInState, expanded {
            return false
        }
        // Enable when inactive, collapsed, or completed
        return true
    }
    
    var isChatDisabled: Bool {
        // Chat is disabled (visually) only when daily check-in is active AND expanded
        if case .active(let expanded) = dailyCheckInState, expanded {
            return true
        }
        return false
    }
    
    var onboardingProgress: Double {
        guard !QuestionBanks.onboardingQuestions.isEmpty else { return 0 }
        return Double(onboardingAnswers.count) / Double(QuestionBanks.onboardingQuestions.count)
    }
    
    var dailyProgress: Double {
        guard !QuestionBanks.dailyQuestions.isEmpty else { return 0 }
        return Double(dailyAnswers.count) / Double(QuestionBanks.dailyQuestions.count)
    }
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func startOnboarding() {
        mode = .onboarding
        messages = []
        currentOnboardingQuestionIndex = 0
        onboardingAnswers = [:]
        
        let introMessage = ChatMessage(
            role: .assistant,
            text: "Welcome! I'll ask you 10 questions to understand your current health baseline. This takes about 2 minutes.",
            timestamp: Date()
        )
        messages.append(introMessage)
        
        // Show first question
        showNextOnboardingQuestion()
    }
    
    private func showNextOnboardingQuestion() {
        guard let question = currentOnboardingQuestion else {
            // All questions answered, submit
            submitOnboarding()
            return
        }
        
        let questionMessage = ChatMessage(
            role: .assistant,
            text: question.prompt,
            timestamp: Date()
        )
        messages.append(questionMessage)
    }
    
    func selectOnboardingOption(_ option: OptionItem) {
        guard let question = currentOnboardingQuestion else { return }
        
        // Store answer
        onboardingAnswers[question.id] = option.value.rawValue
        
        // Add user message
        let userMessage = ChatMessage(
            role: .user,
            text: option.title,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Advance to next question after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.currentOnboardingQuestionIndex += 1
            self?.showNextOnboardingQuestion()
        }
    }
    
    private func submitOnboarding() {
        isSubmitting = true
        submitState = .loading
        
        let calculatingMessage = ChatMessage(
            role: .assistant,
            text: "Calculating your baseline...",
            timestamp: Date()
        )
        messages.append(calculatingMessage)
        
        Task {
            do {
                // Get chronological age - should be provided by user or from backend
                // For now, use a default or get from AgeStore if available
                // TODO: Add chronological age input during onboarding
                let chronologicalAge = 32.0 // Default fallback - should be user input
                
                // Build payload from answers
        let payload = OnboardingAnswersPayload(
            sleep: onboardingAnswers["sleep"] ?? 0,
            activity: onboardingAnswers["activity"] ?? 0,
            muscle: onboardingAnswers["muscle"] ?? 0,
            visceralFat: onboardingAnswers["visceralFat"] ?? 0,
            nutritionPattern: onboardingAnswers["nutritionPattern"] ?? 0,
            sugar: onboardingAnswers["sugar"] ?? 0,
            stress: onboardingAnswers["stress"] ?? 0,
            smokingAlcohol: onboardingAnswers["smokingAlcohol"] ?? 0,
            metabolicHealth: onboardingAnswers["metabolicHealth"] ?? 0,
            energyFocus: onboardingAnswers["energyFocus"] ?? 0
        )
        
                let request = OnboardingSubmitRequest(
                    chronologicalAgeYears: chronologicalAge,
                    answers: payload
                )
                
                // Cache request for retry
                cachedOnboardingRequest = request
                lastFailedAction = .submitOnboarding
                
                let result = try await APIClient.shared.postOnboarding(request)
                
                // Build explanation message
                let bioAge = result.currentBiologicalAgeYears
                let diff = bioAge - result.chronologicalAgeYears
                let direction = diff >= 0 ? "older" : "younger"
                let diffText = String(format: "%.1f", abs(diff))
                let explanation = """
                Your estimated biological age is \(String(format: "%.1f", bioAge)) years (\(diffText) years \(direction) than your chronological age).
                
                Total score: \(String(format: "%.0f", result.totalScore))
                Baseline offset (BAOYears): \(String(format: "%.1f", result.BAOYears))
                
                This is a lifestyle-based estimate, not medical advice.
                """
                
                let resultMessage = ChatMessage(
                    role: .assistant,
                    text: explanation,
                    timestamp: Date()
                )
                
                await MainActor.run {
                    messages.append(resultMessage)
                    appState.markOnboardingComplete()
                    submitState = .success
                    
                    // Refresh summary
                    Task {
                        do {
                            let summary = try await APIClient.shared.getSummary()
                            await MainActor.run {
                                appState.updateSummary(summary)
                            }
                        } catch {
                            print("[ChatViewModel] Failed to refresh summary: \(error)")
                        }
                    }
                    
                    // Switch to daily mode
                    mode = .daily
                    isSubmitting = false
                    cachedOnboardingRequest = nil
                    lastFailedAction = nil
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Couldn't save. Please try again."
                    submitState = .failed(errorMessage: errorMsg)
                    
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        text: errorMsg,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isSubmitting = false
                }
            }
        }
    }
    
    func retryLastSubmission() {
        guard let action = lastFailedAction else { return }
        
        switch action {
        case .submitOnboarding:
            if let request = cachedOnboardingRequest {
                retryOnboarding(request: request)
            }
        case .submitDaily:
            if let request = cachedDailyRequest {
                retryDaily(request: request)
            }
        }
    }
    
    private func retryOnboarding(request: OnboardingSubmitRequest) {
        isSubmitting = true
        submitState = .loading
        
        // Remove last error message if it exists
        if case .failed = submitState, let lastMsg = messages.last, lastMsg.role == .assistant {
            messages.removeLast()
        }
        
        let calculatingMessage = ChatMessage(
            role: .assistant,
            text: "Retrying...",
            timestamp: Date()
        )
        messages.append(calculatingMessage)
        
        Task {
            do {
                let result = try await APIClient.shared.postOnboarding(request)
                
                let bioAge = result.currentBiologicalAgeYears
                let diff = bioAge - result.chronologicalAgeYears
                let direction = diff >= 0 ? "older" : "younger"
                let diffText = String(format: "%.1f", abs(diff))
                let explanation = """
                Your estimated biological age is \(String(format: "%.1f", bioAge)) years (\(diffText) years \(direction) than your chronological age).
                
                Total score: \(String(format: "%.0f", result.totalScore))
                Baseline offset (BAOYears): \(String(format: "%.1f", result.BAOYears))
                
                This is a lifestyle-based estimate, not medical advice.
                """
                
                let resultMessage = ChatMessage(
                    role: .assistant,
                    text: explanation,
                    timestamp: Date()
                )
                
                await MainActor.run {
                    messages.append(resultMessage)
                    appState.markOnboardingComplete()
                    submitState = .success
                    
                    Task {
                        do {
                            let summary = try await APIClient.shared.getSummary()
                            await MainActor.run {
                                appState.updateSummary(summary)
                            }
                        } catch {
                            print("[ChatViewModel] Failed to refresh summary: \(error)")
                        }
                    }
                    
                    mode = .daily
                    isSubmitting = false
                    cachedOnboardingRequest = nil
                    lastFailedAction = nil
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Couldn't save. Please try again."
                    submitState = .failed(errorMessage: errorMsg)
                    
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        text: errorMsg,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isSubmitting = false
                }
            }
        }
    }
    
    func toggleDailyCheckIn() {
        // Toggle arrow logic: only changes state, no chat messages
        switch dailyCheckInState {
        case .inactive:
            dailyCheckInState = .active(expanded: true)
            currentDailyQuestionIndex = 0
            dailyAnswers = [:]
        case .active(let expanded):
            dailyCheckInState = .active(expanded: !expanded)
        case .completed:
            dailyCheckInState = .active(expanded: true)
            currentDailyQuestionIndex = 0
            dailyAnswers = [:]
        }
    }
    
    func selectDailyOption(_ option: OptionItem) {
        guard let question = currentDailyQuestion else { return }
        
        // Store answer
        dailyAnswers[question.id] = option.value.rawValue
        
        // Advance to next question (no chat messages)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.currentDailyQuestionIndex += 1
            
            if self.currentDailyQuestion == nil {
                // All questions answered, ready to submit
                self.submitDailyCheckIn()
            }
        }
    }
    
    private func submitDailyCheckIn() {
        isSubmitting = true
        submitState = .loading
        
        Task {
            do {
                let today = DateFormatter.yyyyMMdd.string(from: Date())
                let metrics = buildDailyMetricsPayload(for: today)
                
                let request = DailySubmitRequest(
                    metrics: metrics
                )
                
                // Cache request for retry
                cachedDailyRequest = request
                lastFailedAction = .submitDaily
                
                let result = try await APIClient.shared.postDaily(request)
                
                await MainActor.run {
                    appState.updateLastDailyDate(today)
                    submitState = .success
                    
                    // Set state to completed
                    dailyCheckInState = .completed
                    
                    // Completion message with insight and follow-up
                    let completionText: String
                    if let todayEntry = result.today {
                        let delta = String(format: "%.2f", todayEntry.deltaYears)
                        completionText = """
                        Daily check-in completed ✅
                        
                        Today's aging: \(delta) years
                        Score: \(todayEntry.score)
                        
                        Want a quick plan to improve tomorrow's score?
                        """
                    } else {
                        completionText = """
                        Daily check-in completed ✅
                        
                        Want a quick plan to improve tomorrow's score?
                        """
                    }
                    
                    let completionMessage = ChatMessage(
                        role: .assistant,
                        text: completionText,
                        timestamp: Date()
                    )
                    messages.append(completionMessage)
                    
                    // Refresh summary
                    Task {
                        do {
                            let summary = try await APIClient.shared.getSummary()
                            await MainActor.run {
                                appState.updateSummary(summary)
                            }
                        } catch {
                            print("[ChatViewModel] Failed to refresh summary: \(error)")
                        }
                    }
                    
                    isSubmitting = false
                    cachedDailyRequest = nil
                    lastFailedAction = nil
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Couldn't save. Please try again."
                    submitState = .failed(errorMessage: errorMsg)
                    
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        text: errorMsg,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isSubmitting = false
                }
            }
        }
    }
    
    private func retryDaily(request: DailySubmitRequest) {
        isSubmitting = true
        submitState = .loading
        
        Task {
            do {
                let result = try await APIClient.shared.postDaily(request)
                
                await MainActor.run {
                    appState.updateLastDailyDate(request.metrics.date)
                    submitState = .success
                    
                    // Set state to completed
                    dailyCheckInState = .completed
                    
                    // Completion message with insight and follow-up
                    let completionText: String
                    if let todayEntry = result.today {
                        let delta = String(format: "%.2f", todayEntry.deltaYears)
                        completionText = """
                        Daily check-in completed ✅
                        
                        Today's aging: \(delta) years
                        Score: \(todayEntry.score)
                        
                        Want a quick plan to improve tomorrow's score?
                        """
                    } else {
                        completionText = """
                        Daily check-in completed ✅
                        
                        Want a quick plan to improve tomorrow's score?
                        """
                    }
                    
                    let completionMessage = ChatMessage(
                        role: .assistant,
                        text: completionText,
                        timestamp: Date()
                    )
                    messages.append(completionMessage)
                    
                    // Refresh summary
                    Task {
                        do {
                            let summary = try await APIClient.shared.getSummary()
                            await MainActor.run {
                                appState.updateSummary(summary)
                            }
                        } catch {
                            print("[ChatViewModel] Failed to refresh summary: \(error)")
                        }
                    }
                    
                    isSubmitting = false
                    cachedDailyRequest = nil
                    lastFailedAction = nil
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Couldn't save. Please try again."
                    submitState = .failed(errorMessage: errorMsg)
                    
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        text: errorMsg,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isSubmitting = false
                }
            }
        }
    }
    
    func goBackToLastQuestion() {
        if mode == .onboarding && currentOnboardingQuestionIndex > 0 {
            currentOnboardingQuestionIndex -= 1
            // Remove last user answer
            if currentOnboardingQuestionIndex < QuestionBanks.onboardingQuestions.count {
                let question = QuestionBanks.onboardingQuestions[currentOnboardingQuestionIndex]
                onboardingAnswers.removeValue(forKey: question.id)
            }
            // Remove last user message
            if let lastUserMsg = messages.lastIndex(where: { $0.isUser }) {
                messages.remove(at: lastUserMsg)
            }
        } else if mode == .daily && currentDailyQuestionIndex > 0 {
            currentDailyQuestionIndex -= 1
            // Remove last user answer
            if currentDailyQuestionIndex < QuestionBanks.dailyQuestions.count {
                let question = QuestionBanks.dailyQuestions[currentDailyQuestionIndex]
                dailyAnswers.removeValue(forKey: question.id)
            }
            // Remove last user message
            if let lastUserMsg = messages.lastIndex(where: { $0.isUser }) {
                messages.remove(at: lastUserMsg)
            }
        }
    }
    
    func sendFreeTextMessage(_ text: String) {
        let userMessage = ChatMessage(
            role: .user,
            text: text,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Send to chat API
        LongevityAPI.shared.sendChatMessage(message: text) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let answer):
                    let assistantMessage = ChatMessage(
                        role: .assistant,
                        text: answer,
                        timestamp: Date()
                    )
                    self?.messages.append(assistantMessage)
                case .failure(_):
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        text: "Sorry, I couldn't process that. Please try again.",
                        timestamp: Date()
                    )
                    self?.messages.append(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func buildDailyMetricsPayload(for date: String) -> DailyMetricsPayload {
        let sleepScore = dailyAnswers["sleep"] ?? 0
        let movementScore = dailyAnswers["movement"] ?? 0
        let foodScore = dailyAnswers["foodQuality"] ?? 0
        let sugarScore = dailyAnswers["sugar"] ?? 0
        let stressScore = dailyAnswers["stress"] ?? 0
        let selfCareScore = dailyAnswers["selfCare"] ?? 0
        
        // Map -1...1 to reasonable metric defaults
        let sleepHours = clamp(7.0 + sleepScore * 1.5, min: 4.0, max: 9.0)
        let steps = Int(clamp(6000 + movementScore * 3000, min: 1000, max: 15000))
        let vigorousMinutes = Int(clamp(30 + movementScore * 30, min: 0, max: 90))
        
        // Processed food score: 1 (good) ... 5 (poor)
        let nutritionScore = (foodScore + sugarScore) / 2
        let processedFoodScore = Int(clamp(3 - nutritionScore * 2, min: 1, max: 5))
        
        // Alcohol units: 0-3 based on self-care / stress
        let alcoholUnits = Int(clamp(1 - selfCareScore + max(0, stressScore), min: 0, max: 3))
        
        // Stress level: 1 (low) ... 5 (high)
        let stressLevel = Int(clamp(3 - stressScore * 2, min: 1, max: 5))
        
        let lateCaffeine = selfCareScore < -0.5
        let screenLate = sleepScore < -0.5
        let bedtimeHour = clamp(23 - sleepScore * 1.5, min: 20, max: 24)
        
        return DailyMetricsPayload(
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
    }
    
    private func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        var v = value
        if v < min { v = min }
        if v > max { v = max }
        return v
    }
}
