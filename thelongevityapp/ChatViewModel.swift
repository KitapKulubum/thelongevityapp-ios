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
    @Published var isWaitingForResponse: Bool = false  // Loading state for AI chat responses
    
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
        // Disable chat input during onboarding
        if mode == .onboarding {
            return false
        }
        // Disable chat input when daily check-in is active AND expanded
        if case .active(let expanded) = dailyCheckInState, expanded {
            return false
        }
        // Enable when inactive, collapsed, or completed
        return true
    }
    
    var isChatDisabled: Bool {
        // Chat is disabled during onboarding
        if mode == .onboarding {
            return true
        }
        // Chat is disabled (visually) when daily check-in is active AND expanded
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
        // Don't set mode here - wait for onAppear to check backend status
        // This ensures we have the correct onboarding status from backend before deciding
        // Mode will be set in onAppear based on appState.hasCompletedOnboarding
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
        print("[ChatViewModel] Added intro message, total messages: \(messages.count)")
        
        // Show first question after a brief delay to ensure intro message is rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showNextOnboardingQuestion()
        }
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
        print("[ChatViewModel] Added question message: \(question.prompt), total messages: \(messages.count)")
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
                // Get chronological age from backend (from signup dateOfBirth)
                // Priority: 1) AppState userChronologicalAge (from postAuthMe), 2) Summary state, 3) Fallback to 0
                let chronologicalAge: Double = {
                    if let age = appState.userChronologicalAge, age > 0 {
                        return age
                    } else if let summaryAge = appState.summary?.state.chronologicalAgeYears, summaryAge > 0 {
                        return summaryAge
                    } else {
                        // This should not happen for new signups, but provide a safe fallback
                        print("[ChatViewModel] Warning: No chronological age found, using 0")
                        return 0.0
                    }
                }()
                
                print("[ChatViewModel] Using chronological age: \(chronologicalAge)")
                
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
                
                // Send timezone to backend after onboarding completion
                let deviceTimezone = TimeZone.current.identifier
                do {
                    _ = try await APIClient.shared.patchProfile(timezone: deviceTimezone)
                    await MainActor.run {
                        appState.updateUserProfile(
                            firstName: appState.userFirstName,
                            lastName: appState.userLastName,
                            chronologicalAge: appState.userChronologicalAge,
                            timezone: deviceTimezone
                        )
                        print("[ChatViewModel] Timezone sent to backend: \(deviceTimezone)")
                    }
                } catch {
                    print("[ChatViewModel] Failed to send timezone after onboarding: \(error)")
                    // Don't block onboarding completion if timezone update fails
                }
                
                // Build welcome message with onboarding results
                let bioAge = result.currentBiologicalAgeYears
                let chronoAge = result.chronologicalAgeYears
                let diff = bioAge - chronoAge
                let absDiff = abs(diff)
                let diffText = String(format: "%.2f", absDiff)
                let comparisonText: String
                if diff >= 0 {
                    comparisonText = "currently \(diffText) years above"
                } else {
                    comparisonText = "currently \(diffText) years below"
                }
                
                // Determine key insights based on score
                let scoreInsight: String
                if result.totalScore < -0.5 {
                    scoreInsight = "Your lifestyle shows strong rejuvenation potential. Keep up these positive habits."
                } else if result.totalScore > 0.5 {
                    scoreInsight = "There are opportunities to optimize your daily habits for better biological aging."
                } else {
                    scoreInsight = "You're on a balanced path. Small improvements can enhance your results."
                }
                
                let welcomeMessage = """
                Welcome! 🎉
                
                This app tracks your biological age based on daily lifestyle choices. Your baseline: \(String(format: "%.2f", bioAge)) years biological age, \(comparisonText) your \(String(format: "%.0f", chronoAge)) chronological years.
                
                \(scoreInsight)
                
                Complete your daily check-in each day to see real-time updates on your Score tab. Your biological age and trends will update based on your daily habits.
                
                How can I help you today?
                """
                
                let welcomeChatMessage = ChatMessage(
                    role: .assistant,
                    text: welcomeMessage,
                    timestamp: Date()
                )
                
                // After successful onboarding submission, refresh auth status to get updated hasCompletedOnboarding
                // This ensures we have the latest onboarding status from backend
                do {
                    let token = try await AuthManager.shared.getIDToken()
                    let authResponse = try await APIClient.shared.postAuthMe(idToken: token)
                    
                    await MainActor.run {
                        // Update onboarding status from backend response (source of truth)
                        appState.setOnboardingStatus(authResponse.hasCompletedOnboarding)
                        print("[ChatViewModel] Onboarding status from postAuthMe: \(authResponse.hasCompletedOnboarding)")
                        
                        // Switch to daily mode first so welcome message is visible
                        mode = .daily
                        // Clear previous messages and add welcome message
                        messages.removeAll()
                        messages.append(welcomeChatMessage)
                        print("[ChatViewModel] Welcome message added, mode: \(mode), messages count: \(messages.count)")
                        // Set active tab to chat (AI) so user sees the welcome message
                        appState.activeTab = .chat
                        submitState = .success
                        
                        isSubmitting = false
                        cachedOnboardingRequest = nil
                        lastFailedAction = nil
                        
                        // Refresh summary to get latest data including hasCompletedOnboarding
                        Task {
                            do {
                                let summary = try await APIClient.shared.getSummary()
                                await MainActor.run {
                                    appState.updateSummary(summary)
                                    // updateSummary already updates onboarding status from summary
                                }
                            } catch {
                                print("[ChatViewModel] Failed to refresh summary: \(error)")
                            }
                        }
                    }
                } catch {
                    // If postAuthMe fails, still mark onboarding as complete locally
                    // but log the error
                    print("[ChatViewModel] Failed to refresh auth status after onboarding: \(error)")
                    await MainActor.run {
                        appState.markOnboardingComplete()
                        mode = .daily
                        messages.removeAll()
                        messages.append(welcomeChatMessage)
                        appState.activeTab = .chat
                        submitState = .success
                        isSubmitting = false
                        cachedOnboardingRequest = nil
                        lastFailedAction = nil
                    }
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
                let diffText = String(format: "%.2f", abs(diff))
                let comparisonText: String
                if diff >= 0 {
                    comparisonText = "Your biological age is currently \(diffText) years above your chronological age"
                } else {
                    comparisonText = "Your biological age is currently \(diffText) years below your chronological age"
                }
                let explanation = """
                Your estimated biological age is \(String(format: "%.2f", bioAge)) years. \(comparisonText).
                
                Total score: \(String(format: "%.2f", result.totalScore))
                Baseline offset (BAOYears): \(String(format: "%.2f", result.BAOYears))
                
                This is a lifestyle-based estimate, not medical advice.
                """
                
                let resultMessage = ChatMessage(
                    role: .assistant,
                    text: explanation,
                    timestamp: Date()
                )
                
                // After successful onboarding submission, refresh auth status to get updated hasCompletedOnboarding
                do {
                    let token = try await AuthManager.shared.getIDToken()
                    let authResponse = try await APIClient.shared.postAuthMe(idToken: token)
                    
                    await MainActor.run {
                        // Update onboarding status from backend response (source of truth)
                        appState.setOnboardingStatus(authResponse.hasCompletedOnboarding)
                        print("[ChatViewModel] Retry - Onboarding status from postAuthMe: \(authResponse.hasCompletedOnboarding)")
                        
                        messages.append(resultMessage)
                        submitState = .success
                        
                        Task {
                            do {
                                let summary = try await APIClient.shared.getSummary()
                                await MainActor.run {
                                    appState.updateSummary(summary)
                                    // updateSummary already updates onboarding status from summary
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
                    // If postAuthMe fails, still mark onboarding as complete locally
                    print("[ChatViewModel] Retry - Failed to refresh auth status after onboarding: \(error)")
                    await MainActor.run {
                        appState.markOnboardingComplete()
                        messages.append(resultMessage)
                        submitState = .success
                        mode = .daily
                        isSubmitting = false
                        cachedOnboardingRequest = nil
                        lastFailedAction = nil
                    }
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
        // Check if today is already submitted (backend is source of truth)
        if appState.isTodaySubmitted {
            // Already completed today - show completed state or allow viewing
            switch dailyCheckInState {
            case .inactive, .completed:
                dailyCheckInState = .completed
            case .active(let expanded):
                dailyCheckInState = .active(expanded: !expanded)
            }
            return
        }
        
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
                // Note: date field removed - backend computes it based on user's timezone
                let metrics = buildDailyMetricsPayload()
                
                let request = DailySubmitRequest(
                    metrics: metrics
                )
                
                // Cache request for retry
                cachedDailyRequest = request
                lastFailedAction = .submitDaily
                
                let result = try await APIClient.shared.postDaily(request)
                
                await MainActor.run {
                    submitState = .success
                    
                    // Set state to completed
                    dailyCheckInState = .completed
                    
                    // Completion message with insight and follow-up
                    let completionText: String
                    if let todayEntry = result.today {
                        let delta = todayEntry.deltaYears
                        let absDelta = abs(delta)
                        let deltaFormatted = String(format: "%.2f", absDelta)
                        let sign = delta < 0 ? "−" : (delta > 0 ? "+" : "")
                        
                        let deltaMessage: String
                        if delta < -0.5 {
                            deltaMessage = "Today's Δ: \(sign)\(deltaFormatted) years (you got younger today)"
                        } else if delta > 0.5 {
                            deltaMessage = "Today's Δ: \(sign)\(deltaFormatted) years"
                        } else {
                            deltaMessage = "Today's Δ: minimal change"
                        }
                        
                        // Build reasons summary
                        let reasonsText: String
                        if !todayEntry.reasons.isEmpty {
                            let reasonsList = todayEntry.reasons.prefix(3).joined(separator: ", ")
                            reasonsText = "\n\nKey factors: \(reasonsList)"
                        } else {
                            reasonsText = ""
                        }
                        
                        completionText = """
                        Daily check-in completed ✅
                        
                        \(deltaMessage).\(reasonsText)
                        
                        Is there a topic you'd like help with?
                        """
                    } else {
                        completionText = """
                        Daily check-in completed ✅
                        
                        Is there a topic you'd like help with?
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
                    let errorMsg: String
                    if error is DecodingError {
                        errorMsg = "Server returned invalid data format. Please try again later."
                    } else if let apiError = error as? APIError {
                        switch apiError {
                        case .invalidResponse:
                            errorMsg = "Server returned invalid data format. Please try again later."
                        case .networkError:
                            errorMsg = "Network error. Please check your connection and try again."
                        case .httpError(_, let statusCode, _):
                            if statusCode >= 500 {
                                errorMsg = "Server error. Please try again later."
                            } else {
                                errorMsg = "Couldn't save. Please try again."
                            }
                        default:
                            errorMsg = "Couldn't save. Please try again."
                        }
                    } else {
                        errorMsg = "Couldn't save. Please try again."
                    }
                    
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
                    submitState = .success
                    
                    // Set state to completed
                    dailyCheckInState = .completed
                    
                    // Completion message with insight and follow-up
                    let completionText: String
                    if let todayEntry = result.today {
                        let delta = todayEntry.deltaYears
                        let absDelta = abs(delta)
                        let deltaFormatted = String(format: "%.2f", absDelta)
                        let sign = delta < 0 ? "−" : (delta > 0 ? "+" : "")
                        
                        let deltaMessage: String
                        if delta < -0.5 {
                            deltaMessage = "Today's Δ: \(sign)\(deltaFormatted) years (you got younger today)"
                        } else if delta > 0.5 {
                            deltaMessage = "Today's Δ: \(sign)\(deltaFormatted) years"
                        } else {
                            deltaMessage = "Today's Δ: minimal change"
                        }
                        
                        completionText = """
                        Daily check-in completed ✅
                        
                        \(deltaMessage)
                        Score: \(String(format: "%.2f", todayEntry.score))
                        
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
                    let errorMsg: String
                    if error is DecodingError {
                        errorMsg = "Server returned invalid data format. Please try again later."
                    } else if let apiError = error as? APIError {
                        switch apiError {
                        case .invalidResponse:
                            errorMsg = "Server returned invalid data format. Please try again later."
                        case .networkError:
                            errorMsg = "Network error. Please check your connection and try again."
                        case .httpError(_, let statusCode, _):
                            if statusCode >= 500 {
                                errorMsg = "Server error. Please try again later."
                            } else {
                                errorMsg = "Couldn't save. Please try again."
                            }
                        default:
                            errorMsg = "Couldn't save. Please try again."
                        }
                    } else {
                        errorMsg = "Couldn't save. Please try again."
                    }
                    
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
        
        // Set loading state
        isWaitingForResponse = true
        
        // Send to chat API
        LongevityAPI.shared.sendChatMessage(message: text) { [weak self] result in
                DispatchQueue.main.async {
                    // Clear loading state
                    self?.isWaitingForResponse = false
                    
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
    
    private func buildDailyMetricsPayload() -> DailyMetricsPayload {
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
