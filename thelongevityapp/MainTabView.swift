//
//  MainTabView.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI
import Charts

struct MainTabView: View {
    @StateObject private var scoreViewModel = ScoreViewModel()
    @EnvironmentObject private var appState: AppState
    
    init() {
        // AppState will be provided via environmentObject from RootView
    }
    
    var body: some View {
        let isOnboarding = !appState.hasCompletedOnboarding
        
        let aiTab = AICoachView()
            .tabItem {
                Image(systemName: "sparkles")
                Text("AI")
            }
            .tag(Tab.chat)
        
        let scoreTab = LongevityTrendView()
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Age")
            }
            .tag(Tab.score)
        
        let profileTab = ProfileView()
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(Tab.profile)
        
        let tabView = TabView(selection: Binding(
            get: { appState.activeTab },
            set: { newValue in
                // Prevent switching tabs during onboarding
                if !isOnboarding {
                    appState.activeTab = newValue
                } else {
                    // Force stay on AI tab during onboarding
                    appState.activeTab = .chat
                }
            }
        )) {
            aiTab
            scoreTab
            profileTab
        }
        
        let configuredTabView = tabView
            .environmentObject(scoreViewModel)
            .environmentObject(appState)
            .preferredColorScheme(.dark)
            .onAppear {
                handleOnAppear(isOnboarding: isOnboarding)
            }
            .onChange(of: appState.hasCompletedOnboarding) { oldValue, newValue in
                handleOnboardingChange(oldValue: oldValue, newValue: newValue)
            }
            .onChange(of: appState.activeTab) { oldValue, newValue in
                // Prevent tab switching during onboarding
                if isOnboarding && newValue != .chat {
                    appState.activeTab = .chat
                }
            }
        
        let withSummaryChange = configuredTabView
            .onChange(of: appState.summary?.userId ?? "") { _, _ in
                // Update score view model whenever summary changes (watch userId as proxy)
                if appState.summary != nil {
                    updateScoreViewModel()
                    print("[MainTabView] Summary updated, applying to scoreViewModel")
                }
            }
        
        let withBiologicalAgeChange = withSummaryChange
            .onChange(of: appState.summary?.state.currentBiologicalAgeYears ?? appState.summary?.state.chronologicalAgeYears ?? 0, initial: false) { _, _ in
                updateScoreViewModel()
            }
        
        let withAgingDebtChange = withBiologicalAgeChange
            .onChange(of: appState.summary?.state.agingDebtYears ?? 0, initial: false) { _, _ in
                updateScoreViewModel()
            }
        
        let withTodayChange = withAgingDebtChange
            .onChange(of: appState.summary?.today?.score ?? 0, initial: false) { _, _ in
                updateScoreViewModel()
            }
        
        return withTodayChange
    }
    
    private func handleOnAppear(isOnboarding: Bool) {
        // Force AI tab during onboarding
        if isOnboarding {
            appState.activeTab = .chat
        }
        
        // Bootstrap app state
        Task {
            do {
                try await appState.bootstrap(requireBackend: false)
                // After bootstrap, update score view model if summary is available
                await MainActor.run {
                    if appState.summary != nil {
                        updateScoreViewModel()
                        print("[MainTabView] Bootstrap complete, applied summary to scoreViewModel")
                    }
                }
            } catch {
                print("[MainTabView] Bootstrap failed: \(error)")
                // Continue with cached data if bootstrap fails
                await MainActor.run {
                    if appState.summary != nil {
                        updateScoreViewModel()
                        print("[MainTabView] Using cached summary after bootstrap failure")
                    }
                }
            }
        }
    }
    
    private func handleOnboardingChange(oldValue: Bool, newValue: Bool) {
        // When onboarding completes, ensure we're on AI tab
        if newValue && !oldValue {
            appState.activeTab = .chat
        }
    }
    
    private func updateScoreViewModel() {
        if let summary = appState.summary {
            scoreViewModel.apply(summary)
        }
    }
    
}

// MARK: - AI Coach View (Chat Screen)
struct AICoachView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @State private var chatMessage: String = ""
    
    init() {
        let tempAppState = AppState(userId: AuthManager.shared.uid ?? "")
        _viewModel = StateObject(wrappedValue: ChatViewModel(appState: tempAppState))
    }
    
    private func updateDailyCheckInState() {
        // Update daily check-in state based on backend summary.today
        // Backend is source of truth - if summary.today exists, check-in is completed
        if appState.isTodaySubmitted {
            // Check-in already completed today - set to completed state
            if case .inactive = viewModel.dailyCheckInState {
                viewModel.dailyCheckInState = .completed
            } else if case .active = viewModel.dailyCheckInState {
                // Only update to completed if not currently active (user might be in the middle of check-in)
                // Don't interrupt active check-in
            }
        } else {
            // Check-in not completed today - allow starting check-in
            if case .completed = viewModel.dailyCheckInState {
                // Reset to inactive if it was completed but backend says it's not
                viewModel.dailyCheckInState = .inactive
            }
        }
    }

    var body: some View {
        let isDailyMode = viewModel.mode == .daily
        let isEmptyDaily = viewModel.messages.isEmpty && viewModel.mode == .daily
        let isOnboarding = !appState.hasCompletedOnboarding || viewModel.mode == .onboarding
        
        return buildBody(isDailyMode: isDailyMode, isEmptyDaily: isEmptyDaily, isOnboarding: isOnboarding)
    }
    
    @ViewBuilder
    private func buildBody(isDailyMode: Bool, isEmptyDaily: Bool, isOnboarding: Bool) -> some View {
        VStack(spacing: 0) {
            buildProgressBar()
            buildDailyCheckInCard(isDailyMode: isDailyMode, isOnboarding: isOnboarding)
            buildMessagesArea(isEmptyDaily: isEmptyDaily, isOnboarding: isOnboarding)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            buildInputBar(isOnboarding: isOnboarding)
        }
        .background(
            BackgroundView()
                .ignoresSafeArea()
        )
        .onAppear {
            // Update viewModel's appState reference to use environment object
            viewModel.appState = appState
            
            // Start onboarding if not completed and messages are empty
            if !appState.hasCompletedOnboarding && viewModel.messages.isEmpty {
                print("[AICoachView] Starting onboarding - mode: \(viewModel.mode), messages count: \(viewModel.messages.count)")
                // Ensure mode is onboarding
                if viewModel.mode != .onboarding {
                    viewModel.mode = .onboarding
                }
                viewModel.startOnboarding()
            }
            
            // Update daily check-in state on appear
            updateDailyCheckInState()
        }
    }
    
    @ViewBuilder
    private func buildProgressBar() -> some View {
        if viewModel.mode == .onboarding {
            OnboardingProgressBar(
                progress: viewModel.onboardingProgress,
                currentQuestionIndex: viewModel.currentOnboardingQuestionIndex,
                totalQuestions: QuestionBanks.onboardingQuestions.count
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private func buildDailyCheckInCard(isDailyMode: Bool, isOnboarding: Bool) -> some View {
        if isDailyMode && !isOnboarding {
            VStack(spacing: 8) {
                DailyCheckInPinnedCard(viewModel: viewModel, appState: appState)
                
                // Show reminder message if daily check-in is not completed
                if !appState.isTodaySubmitted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        
                        Text("Complete daily check-in to track your score")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, -4)
                }
            }
        }
    }
    
    @ViewBuilder
    private func buildInputBar(isOnboarding: Bool) -> some View {
        if viewModel.mode == .daily && !isOnboarding {
            InputBarView(
                chatMessage: $chatMessage,
                onSend: {
                    if !chatMessage.isEmpty && viewModel.chatInputEnabled {
                        viewModel.sendFreeTextMessage(chatMessage)
                        chatMessage = ""
                    }
                }
            )
            .disabled(!viewModel.chatInputEnabled)
            .opacity(viewModel.chatInputEnabled ? 1.0 : 0.4)
        }
    }
    
    @ViewBuilder
    private func buildMessagesArea(isEmptyDaily: Bool, isOnboarding: Bool) -> some View {
        if isEmptyDaily && !isOnboarding {
                // Hero message for daily mode
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("Longevity AI is ready.")
                            .font(.system(size: 20, weight: .medium))
                        Text("Let's optimize your healthspan.")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Scrollable messages (always visible, but disabled when check-in is active)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Show all messages
                            ForEach(viewModel.messages) { message in
                                VStack(spacing: 8) {
                                    ChatBubbleView(message: message)
                                        // Don't reduce opacity during onboarding - messages should be fully visible
                                        .opacity((viewModel.isChatDisabled && viewModel.mode != .onboarding) ? 0.4 : 1.0)
                                    
                                    // Loading indicator when waiting for AI response
                                    if viewModel.isWaitingForResponse && message.id == viewModel.messages.last?.id && message.isUser {
                                        LongevityAILoadingView()
                                            .padding(.top, 8)
                                    }
                                    
                                    // Retry button for failed submissions
                                    if !message.isUser,
                                       message.id == viewModel.messages.last?.id,
                                       case .failed(let errorMsg) = viewModel.submitState,
                                       message.text.contains(errorMsg) {
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                viewModel.retryLastSubmission()
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "arrow.clockwise")
                                                        .font(.system(size: 12))
                                                    Text("Retry")
                                                        .font(.system(size: 14, weight: .semibold))
                                                }
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.green.opacity(0.2))
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                                        )
                                                )
                                            }
                                            
                                            if viewModel.mode == .onboarding && viewModel.currentOnboardingQuestionIndex > 0 {
                                                Button(action: {
                                                    viewModel.goBackToLastQuestion()
                                                }) {
                                                    Text("Edit answers")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.7))
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 10)
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
                                        .opacity(viewModel.isChatDisabled ? 0.4 : 1.0)
                                    }
                                }
                                .id(message.id)
                            }
                            
                            // Onboarding question options - show after the last message
                            if viewModel.mode == .onboarding,
                               let question = viewModel.currentOnboardingQuestion,
                               !viewModel.isSubmitting {
                                VStack(spacing: 12) {
                                    ForEach(question.options) { option in
                                        OptionButton(
                                            title: option.title,
                                            isSelected: false,
                                            action: {
                                                print("[AICoachView] Option tapped: \(option.title)")
                                                viewModel.selectOnboardingOption(option)
                                            }
                                        )
                                        .buttonStyle(PlainButtonStyle()) // Ensure button is tappable
                                    }
                                }
                                .padding(.horizontal, 0) // Already in VStack with padding
                                .padding(.top, 8)
                                .id("onboarding-options")
                                .allowsHitTesting(true) // Ensure options are tappable
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        // Add extra bottom space when input is disabled to avoid overlap
                        .padding(.bottom, viewModel.chatInputEnabled ? 0 : 80)
                    }
                    // Don't disable ScrollView during onboarding - only disable during daily check-in
                    .disabled(viewModel.isChatDisabled && viewModel.mode != .onboarding)
                    .onAppear {
                        // Scroll to bottom when view appears (especially for onboarding)
                        if !viewModel.messages.isEmpty {
                            if let last = viewModel.messages.last {
                                // Use longer delay for onboarding to ensure messages are rendered
                                let delay = viewModel.mode == .onboarding ? 0.6 : 0.3
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    withAnimation {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        // Update daily check-in state based on summary.today
                        updateDailyCheckInState()
                    }
                    .onChange(of: appState.summary?.today?.date ?? "") { _, _ in
                        // Update daily check-in state when summary.today changes
                        // This ensures UI reflects backend state (completed vs. not completed)
                        updateDailyCheckInState()
                    }
                    .onChange(of: viewModel.messages.count) {
                        // Scroll to last message when new message is added
                        if viewModel.mode == .onboarding {
                            // In onboarding mode, scroll to options instead of last message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                withAnimation {
                                    proxy.scrollTo("onboarding-options", anchor: .bottom)
                                }
                            }
                        } else if let last = viewModel.messages.last {
                            // In daily mode, scroll to last message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.currentOnboardingQuestionIndex) {
                        // Scroll to options when new question appears
                        if viewModel.mode == .onboarding {
                            // Use longer delay to ensure options are fully rendered
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                withAnimation {
                                    proxy.scrollTo("onboarding-options", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.mode) {
                        // When switching to onboarding mode, scroll to bottom
                        if viewModel.mode == .onboarding && !viewModel.messages.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let last = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

// ChatMessage is now defined in ChatViewModel.swift

struct ChatBubbleView: View {
    let message: ChatMessage
    
    private var formattedText: String {
        let processed = message.text
        // Handle markdown formatting: headers, bullet points, bold, etc.
        let lines = processed.components(separatedBy: CharacterSet.newlines)
        let cleanedLines = lines.map { line -> String in
            var l = line.trimmingCharacters(in: CharacterSet.whitespaces)
            
            // Handle headers (####, ###, ##, #)
            if l.hasPrefix("#### ") {
                l = "**" + l.replacingOccurrences(of: "#### ", with: "") + "**"
            } else if l.hasPrefix("### ") {
                l = "**" + l.replacingOccurrences(of: "### ", with: "") + "**"
            } else if l.hasPrefix("## ") {
                l = "**" + l.replacingOccurrences(of: "## ", with: "") + "**"
            } else if l.hasPrefix("# ") {
                l = "**" + l.replacingOccurrences(of: "# ", with: "") + "**"
            }
            
            // Handle bullet points (* or -)
            if l.hasPrefix("* ") {
                l = "• " + l.replacingOccurrences(of: "* ", with: "")
            } else if l.hasPrefix("- ") {
                l = "• " + l.replacingOccurrences(of: "- ", with: "")
            }
            
            return l
        }
        return cleanedLines.joined(separator: "\n")
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser { Spacer(minLength: 0) }
            
            Text(.init(formattedText))
                .font(.system(size: 15, design: .default))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    message.isUser ? 
                    AnyView(Capsule().fill(Color.green.opacity(0.15))) : 
                    AnyView(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05)))
                )
                .overlay(
                    message.isUser ? 
                    AnyView(Capsule().stroke(Color.green.opacity(0.2), lineWidth: 1)) : 
                    AnyView(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .foregroundColor(.white)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer(minLength: 0) }
        }
    }
}

struct InputBarView: View {
    @Binding var chatMessage: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask anything about your health, habits...", text: $chatMessage)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(chatMessage.isEmpty ? .gray : .white)
                    .frame(width: 44, height: 44)
            }
            .disabled(chatMessage.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Blurred card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .background(.ultraThinMaterial)
                
                // Subtle border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
        )
    }
}

// MARK: - Daily Check-In Components
struct HeaderView: View {
    let checkInStep: CheckInStep?
    let messages: [ChatMessage]
    let onStartCheckIn: () -> Void
    
    var body: some View {
        if checkInStep == nil {
            Button(action: onStartCheckIn) {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        
                        Text("Start Daily Check-In")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green, radius: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    Text("REQUIRED DAILY TO TRACK YOUR BIOLOGICAL AGE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green.opacity(0.7))
                        .kerning(1)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
}

struct MessagesView: View {
    let messages: [ChatMessage]
    let checkInStep: CheckInStep?
    @Binding var tempMetrics: DailyUpdateRequest.Metrics
    let onAnswer: (String) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(messages) { msg in
                        ChatBubbleView(message: msg)
                            .id(msg.id)
                    }
                    
                    if let step = checkInStep {
                        StepControlView(step: step, metrics: $tempMetrics, onAnswer: onAnswer)
                            .id("step-control")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onChange(of: messages.count) {
                withAnimation {
                    if let lastId = messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    } else if checkInStep != nil {
                        proxy.scrollTo("step-control", anchor: .bottom)
                    }
                }
            }
            .onChange(of: checkInStep) {
                withAnimation {
                    if checkInStep != nil {
                        proxy.scrollTo("step-control", anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color.black
            
            // Subtle Neural/Glow Background
            Circle()
                .fill(RadialGradient(colors: [Color.green.opacity(0.05), Color.clear], center: .center, startRadius: 50, endRadius: 300))
                .frame(width: 600, height: 600)
                .blur(radius: 80)
        }
    }
}

enum CheckInStep {
    case sleep, steps, vigorous, processedFood, alcohol, stress, caffeine, screen, bedtime
}

struct StepControlView: View {
    let step: CheckInStep
    @Binding var metrics: DailyUpdateRequest.Metrics
    let onAnswer: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                switch step {
                case .sleep:
                    ForEach([5.0, 6.0, 7.0, 8.0, 9.0], id: \.self) { hr in
                        CheckInButton(title: "\(Int(hr))h") {
                            metrics.sleepHours = hr
                            onAnswer("\(Int(hr)) hours")
                        }
                    }
                case .steps:
                    ForEach([2000, 5000, 8000, 10000, 15000], id: \.self) { s in
                        CheckInButton(title: "\(s/1000)k") {
                            metrics.steps = s
                            onAnswer("\(s) steps")
                        }
                    }
                case .vigorous:
                    ForEach([0, 15, 30, 45, 60], id: \.self) { m in
                        CheckInButton(title: "\(m)m") {
                            metrics.vigorousMinutes = m
                            onAnswer("\(m) minutes")
                        }
                    }
                case .processedFood:
                    ForEach([1, 3, 5, 8, 10], id: \.self) { level in
                        CheckInButton(title: "\(level)") {
                            metrics.processedFoodScore = level
                            onAnswer("Score \(level)")
                        }
                    }
                case .alcohol:
                    ForEach([0, 1, 2, 3, 5], id: \.self) { unit in
                        CheckInButton(title: "\(unit)") {
                            metrics.alcoholUnits = unit
                            onAnswer("\(unit) units")
                        }
                    }
                case .stress:
                    ForEach([1, 3, 5, 8, 10], id: \.self) { l in
                        CheckInButton(title: "\(l)") {
                            metrics.stressLevel = l
                            onAnswer("Level \(l)")
                        }
                    }
                case .caffeine:
                    CheckInButton(title: "No") {
                        metrics.lateCaffeine = false
                        onAnswer("No caffeine")
                    }
                    CheckInButton(title: "Yes") {
                        metrics.lateCaffeine = true
                        onAnswer("Yes, had caffeine")
                    }
                case .screen:
                    CheckInButton(title: "No") {
                        metrics.screenLate = false
                        onAnswer("No screens")
                    }
                    CheckInButton(title: "Yes") {
                        metrics.screenLate = true
                        onAnswer("Yes, used screens")
                    }
                case .bedtime:
                    ForEach([21.0, 22.0, 23.0, 0.0, 1.0], id: \.self) { t in
                        CheckInButton(title: String(format: "%.0f:00", t)) {
                            metrics.bedtimeHour = t
                            onAnswer(String(format: "%.0f:00", t))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct CheckInButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Longevity Trend View (Score Screen)
struct LongevityTrendView: View {
    @EnvironmentObject private var scoreViewModel: ScoreViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var deltaViewModel = DeltaAnalyticsViewModel()
    @State private var selectedRange: TrendRange = .weekly
    
    // Design tokens
    private let screenPadding: CGFloat = 20
    private let sectionSpacing: CGFloat = 24
    private let cardRadius: CGFloat = 20
    
    @ViewBuilder
    private func trendSection() -> some View {
        VStack(spacing: 0) {
            // Delta Chart View
            DeltaChartView(
                viewModel: deltaViewModel,
                range: selectedRange.rawValue
            )
            .frame(minHeight: 240)
            .padding(.horizontal, screenPadding)
            
            // Check-in metadata (immediately under graph, small gray meta)
            if let summary = deltaViewModel.dailySummary ?? deltaViewModel.yearlySummary {
                HStack {
                    Text("\(summary.checkIns) check-ins this period")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.35))
                    
                    Spacer()
                }
                .padding(.horizontal, screenPadding)
                .padding(.top, 12)
                .padding(.bottom, sectionSpacing)
            } else {
                Spacer()
                    .frame(height: sectionSpacing)
            }
        }
    }
    
    @ViewBuilder
    private func metricsRow() -> some View {
        // This function appears to be unused (replaced by contextMetricsRow)
        // Keeping for backward compatibility but using new color logic
        let agingDebtColorState = colorForBiologicalAge(
            biologicalAge: scoreViewModel.biologicalAgeYears,
            chronologicalAge: scoreViewModel.chronologicalAgeYears
        )
        
        let todayDelta = scoreViewModel.todayDeltaYears ?? 0
        let todayDeltaColorState: BiologicalAgeColorState = {
            if todayDelta < -0.5 {
                return .positive
            } else if abs(todayDelta) <= 0.5 {
                return .neutral
            } else {
                return .attention
            }
        }()
        
        return HStack(spacing: 24) {
            MetricCard(
                title: "AGING DEBT",
                value: String(format: "%.2fy", abs(scoreViewModel.agingDebtYears)),
                colorState: agingDebtColorState
            )
            
            MetricCard(
                title: "TODAY Δ",
                value: String(format: "%.2fy", abs(todayDelta)),
                colorState: todayDeltaColorState
            )
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func streakSection() -> some View {
        // Streak value from backend - date-based and consecutive (not calculated locally)
        HStack {
            Spacer()
            
            HStack(spacing: 8) {
            Text("🔥")
                    .font(.system(size: 16))
            Text("\(scoreViewModel.rejuvenationStreakDays) DAY STREAK")
                    .font(.system(size: 12, weight: .bold))
                    .kerning(0.5)
        }
        .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func shareRow() -> some View {
        HStack(spacing: 20) {
            Text("SHARE INSIGHTS")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .kerning(1)
            
            Spacer()
            
            HStack(spacing: 16) {
                ShareIconButton(icon: "circle.grid.2x2.fill")
                ShareIconButton(icon: "music.note")
                ShareIconButton(icon: "square.and.arrow.up")
            }
        }
    }
    
    @ViewBuilder
    private var headerRowOnly: some View {
        HStack {
            Spacer()
            
            Text("LONGEVITY AGE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .kerning(1.5)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func headerRow(diff: Double, isGood: Bool) -> some View {
        headerRowOnly
    }
    
    @ViewBuilder
    private func statusChip(diff: Double, isGood: Bool) -> some View {
        // Use diff to determine status
        let trendValue: Double = diff
        let trendLabel: String = isGood ? "Rejuvenation" : "Acceleration"
        
        let chipColor: Color = {
            if trendValue < 0 {
                    return .green
            } else if trendValue > 0 {
                    return .orange
                } else {
                    return .white.opacity(0.6)
            }
        }()
        
        let chipIcon: String = {
            if trendValue < 0 {
                    return "✨"
            } else if trendValue > 0 {
                    return "↗"
                } else {
                    return "—"
            }
        }()
        
        HStack(spacing: 6) {
            Text(chipIcon)
            Text(String(format: "%@: %.2fy", trendLabel, abs(trendValue)))
                    .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(chipColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(chipColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(chipColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: chipColor.opacity(0.2), radius: 8)
    }
    
    var body: some View {
        let diff = scoreViewModel.biologicalAgeYears - scoreViewModel.chronologicalAgeYears
        let isGood = diff <= 0
        let header = headerRow(diff: diff, isGood: isGood)
        let scrollContent = scrollViewContent(header: header)
        
        let zStack = ZStack {
            Color.black.ignoresSafeArea()
            scrollContent
        }
        
        let configuredZStack = zStack
            .onAppear {
                // First try to apply cached summary if available
                if appState.summary != nil {
                    updateScoreFromSummary()
                    print("[LongevityTrendView] Applied cached summary on appear")
                }
                
                // Then fetch fresh data
                Task {
                    await scoreViewModel.fetchSummary()
                    // Load delta analytics data
                    deltaViewModel.loadData(range: selectedRange.rawValue)
                }
            }
            .onChange(of: appState.summary?.userId ?? "") { _, _ in
                // Update score view model whenever summary changes (watch userId as proxy)
                if appState.summary != nil {
                    updateScoreFromSummary()
                    print("[LongevityTrendView] Summary updated, applying to scoreViewModel")
                }
            }
        
        let withBiologicalAgeChange = configuredZStack
            .onChange(of: appState.summary?.state.currentBiologicalAgeYears ?? appState.summary?.state.chronologicalAgeYears ?? 0, initial: false) { _, _ in
                updateScoreFromSummary()
            }
        
        let withAgingDebtChange = withBiologicalAgeChange
            .onChange(of: appState.summary?.state.agingDebtYears ?? 0, initial: false) { _, _ in
                updateScoreFromSummary()
            }
        
        return withAgingDebtChange
            .onChange(of: appState.summary?.today?.score ?? 0, initial: false) { _, _ in
                updateScoreFromSummary()
            }
    }
    
    private func updateScoreFromSummary() {
        if let summary = appState.summary {
            scoreViewModel.apply(summary)
        }
    }
    
    @ViewBuilder
    private func scrollViewContent(header: some View) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. Header Row (title only, no status chip)
                headerRowOnly
                .padding(.horizontal, screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 40)
                
                // 2. Hero Section - Biological Age (dominant, centered)
                heroBiologicalAge
                .padding(.horizontal, screenPadding)
                .padding(.bottom, 28)
                
                // 3. Context Row (Aging Debt / Today Δ) - subtle
                contextMetricsRow()
                .padding(.horizontal, screenPadding)
                .padding(.bottom, 36)
                
                // 4. Streak (calm reward, higher up)
                if scoreViewModel.rejuvenationStreakDays > 0 {
                    calmStreakSection()
                        .padding(.horizontal, screenPadding)
                        .padding(.bottom, 32)
                }
                
                // 5. Time Range Selector (above graph, closer to hero)
                timeRangeControl
                .padding(.horizontal, screenPadding)
                .padding(.bottom, 28)
                
                // 6. Trend Graph Area (main visual) + check-in metadata
                trendSection()
                
                // 8. Microcopy (bottom)
                microcopySection
                .padding(.horizontal, screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 100) // Extra padding to avoid TabBar overlap
            }
        }
    }
    
    // MARK: - Hero Biological Age Section
    @ViewBuilder
    private var heroBiologicalAge: some View {
        let diff = scoreViewModel.biologicalAgeYears - scoreViewModel.chronologicalAgeYears
        let colorState = colorForBiologicalAge(
            biologicalAge: scoreViewModel.biologicalAgeYears,
            chronologicalAge: scoreViewModel.chronologicalAgeYears
        )
        let trendValue: Double = abs(diff)
        
        VStack(spacing: 20) {
            // Biological Age - Hero (dominant, centered)
            VStack(spacing: 6) {
                Text(String(format: "%.2f", scoreViewModel.biologicalAgeYears))
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .foregroundColor(colorState.color)
                
                Text("BIOLOGICAL")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(colorState.color.opacity(0.65))
                    .kerning(1.2)
            }
            
            // Rejuvenation insight (inline, under Biological Age) - optik hizalama
            if diff < -0.5 && trendValue > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("✨")
                        .font(.system(size: 12))
                        .opacity(0.7)
                        .baselineOffset(-1)
                    Text("\(String(format: "%.2f", trendValue)) years younger than your chronological age")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
            } else if diff > 0.5 && trendValue > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("↗")
                        .font(.system(size: 12))
                        .opacity(0.7)
                        .baselineOffset(-1)
                    Text("\(String(format: "%.2f", trendValue)) years older than your chronological age")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
            } else if abs(diff) <= 0.5 {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                        .font(.system(size: 12))
                        .opacity(0.7)
                        .baselineOffset(-1)
                    Text("Aligned with your chronological age")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
            }
            
            // Chronological Age - Secondary reference (smaller, lower contrast)
            VStack(spacing: 3) {
                Text(String(format: "%.2f", scoreViewModel.chronologicalAgeYears))
                    .font(.system(size: 24, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
                
                Text("Chronological")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.25))
                    .kerning(0.5)
            }
            .padding(.top, 12)
        }
    }
    
    // MARK: - Context Metrics Row (subtle, below hero)
    @ViewBuilder
    private func contextMetricsRow() -> some View {
        // Calculate color states based on aging debt and today delta
        // Aging debt = biologicalAge - chronologicalAge (same as diff)
        let agingDebtColorState = colorForBiologicalAge(
            biologicalAge: scoreViewModel.biologicalAgeYears,
            chronologicalAge: scoreViewModel.chronologicalAgeYears
        )
        
        // Today delta: negative = rejuvenation, positive = aging, near zero = neutral
        let todayDelta = scoreViewModel.todayDeltaYears ?? 0
        let todayDeltaColorState: BiologicalAgeColorState = {
            if todayDelta < -0.5 {
                return .positive
            } else if abs(todayDelta) <= 0.5 {
                return .neutral
            } else {
                return .attention
            }
        }()
        
        return HStack(spacing: 32) {
            MetricCard(
                title: "AGING DEBT",
                value: String(format: "%.2fy", abs(scoreViewModel.agingDebtYears)),
                colorState: agingDebtColorState
            )
            
            MetricCard(
                title: "TODAY Δ",
                value: String(format: "%.2fy", abs(todayDelta)),
                colorState: todayDeltaColorState
            )
            
            Spacer()
        }
    }
    
    // MARK: - Calm Streak Section (reward style, not CTA)
    @ViewBuilder
    private func calmStreakSection() -> some View {
        HStack {
            Spacer()
            
            HStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: 13))
                    .opacity(0.7)
                Text("\(scoreViewModel.rejuvenationStreakDays) day consistency streak")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
    }
    
    
    // MARK: - Microcopy Section
    @ViewBuilder
    private var microcopySection: some View {
        Text("How your lifestyle affects your biological age over time")
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.white.opacity(0.35))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var timeRangeControl: some View {
        HStack(spacing: 4) {
            ForEach([TrendRange.weekly, .monthly, .yearly], id: \.self) { range in
                Button(action: {
                    selectedRange = range
                    // Update delta analytics when range changes
                    deltaViewModel.loadData(range: range.rawValue)
                }) {
                    Text(range.rawValue.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(selectedRange == range ? .black : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(selectedRange == range ? Color.green.opacity(0.9) : Color.clear)
                        )
                }
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }
    
    private func handleScoreViewAppear() {
        Task {
            await scoreViewModel.fetchSummary()
        }
    }
}

// MARK: - Color Logic Helper

/// Determines color for biological age indicators based on the difference from chronological age
/// - Green: biologicalAge < chronologicalAge - 0.5 (positive rejuvenation)
/// - Gray: abs(diff) <= 0.5 (aligned state)
/// - Amber: biologicalAge > chronologicalAge + 0.5 (attention state, not red)
enum BiologicalAgeColorState {
    case positive    // Green - rejuvenation
    case neutral     // Gray - aligned
    case attention   // Amber/Orange - needs attention
    
    var color: Color {
        switch self {
        case .positive:
            return .green
        case .neutral:
            return Color(white: 0.6) // Neutral gray
        case .attention:
            return Color.orange // Warm amber/orange, not red
        }
    }
}

func colorForBiologicalAge(biologicalAge: Double, chronologicalAge: Double) -> BiologicalAgeColorState {
    let diff = biologicalAge - chronologicalAge
    
    if diff < -0.5 {
        return .positive
    } else if abs(diff) <= 0.5 {
        return .neutral
    } else {
        return .attention
    }
}

// MARK: - Supporting Components
struct StatColumn: View {
    let value: Double
    let label: String
    let color: Color
    let labelColor: Color
    var hasGlow: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(String(format: "%.2f", value))
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .foregroundColor(color)
                .shadow(color: hasGlow ? color.opacity(0.3) : .clear, radius: 10)
            
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(labelColor)
                .kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let colorState: BiologicalAgeColorState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .kerning(1)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(colorState.color)
        }
    }
}

struct ShareIconButton: View {
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

// MARK: - Daily Check-In Sheet

struct TrendChartView: View {
    let points: [HistoryPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            let ages = points.map { $0.biologicalAgeYears }
            let maxAge = ages.max() ?? 33.0
            let minAge = ages.min() ?? 31.0
            let ageRange = max(maxAge - minAge, 1.0)
            
            // Generate points for the path
            let chartPoints = points.enumerated().map { index, point in
                CGPoint(
                    x: width * CGFloat(index) / CGFloat(max(points.count - 1, 1)),
                    y: height * (0.8 - (point.biologicalAgeYears - minAge) / ageRange * 0.6) // Keep it centered vertically
                )
            }
            
            ZStack {
                // Background Gradient Fill
                Path { path in
                    guard !chartPoints.isEmpty else { return }
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: chartPoints[0])
                    
                    for i in 1..<chartPoints.count {
                        let mid = CGPoint(x: (chartPoints[i-1].x + chartPoints[i].x) / 2, y: (chartPoints[i-1].y + chartPoints[i].y) / 2)
                        path.addQuadCurve(to: mid, control: chartPoints[i-1])
                    }
                    path.addLine(to: chartPoints.last!)
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.15), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Chart Line (Smooth)
                Path { path in
                    guard !chartPoints.isEmpty else { return }
                    path.move(to: chartPoints[0])
                    
                    for i in 1..<chartPoints.count {
                        let p0 = chartPoints[i-1]
                        let p1 = chartPoints[i]
                        let controlPoint1 = CGPoint(x: (p0.x + p1.x) / 2, y: p0.y)
                        let controlPoint2 = CGPoint(x: (p0.x + p1.x) / 2, y: p1.y)
                        path.addCurve(to: p1, control1: controlPoint1, control2: controlPoint2)
                    }
                }
                .stroke(
                    LinearGradient(colors: [.green, .green.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                
                // "Now" Indicator at the very end
                if let lastPoint = chartPoints.last {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .shadow(color: .green, radius: 10)
                        
                        Text("Now")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                            .offset(y: 40)
                    }
                    .position(lastPoint)
                }
            }
        }
    }
}

// New chart view for Trends API (TrendPointNew)
struct TrendChartViewNew: View {
    let points: [TrendPointNew]
    let color: Color = .green // Match Biological Age color
    
    var body: some View {
        GeometryReader { geometry in
            if points.isEmpty {
                EmptyView()
            } else {
                let width = geometry.size.width
                let height = geometry.size.height
                
                let ages = points.map { $0.biologicalAge }
                let maxAge = ages.max() ?? 33.0
                let minAge = ages.min() ?? 31.0
                let ageRange = max(maxAge - minAge, 1.0)
                
                // Generate points for the path
                let chartPoints = points.enumerated().map { index, point in
                    CGPoint(
                        x: width * CGFloat(index) / CGFloat(max(points.count - 1, 1)),
                        y: height * (0.8 - (point.biologicalAge - minAge) / ageRange * 0.6)
                    )
                }
                
                ZStack {
                    // Background Gradient Fill
                    Path { path in
                        guard !chartPoints.isEmpty else { return }
                        path.move(to: CGPoint(x: 0, y: height))
                        path.addLine(to: chartPoints[0])
                        
                        for i in 1..<chartPoints.count {
                            let mid = CGPoint(x: (chartPoints[i-1].x + chartPoints[i].x) / 2, y: (chartPoints[i-1].y + chartPoints[i].y) / 2)
                            path.addQuadCurve(to: mid, control: chartPoints[i-1])
                        }
                        path.addLine(to: chartPoints.last!)
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Chart Line (Smooth)
                    Path { path in
                        guard !chartPoints.isEmpty else { return }
                        path.move(to: chartPoints[0])
                        
                        for i in 1..<chartPoints.count {
                            let p0 = chartPoints[i-1]
                            let p1 = chartPoints[i]
                            let controlPoint1 = CGPoint(x: (p0.x + p1.x) / 2, y: p0.y)
                            let controlPoint2 = CGPoint(x: (p0.x + p1.x) / 2, y: p1.y)
                            path.addCurve(to: p1, control1: controlPoint1, control2: controlPoint2)
                        }
                    }
                    .stroke(
                        LinearGradient(colors: [color, color.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    // "Now" Indicator at the very end
                    if let lastPoint = chartPoints.last {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 12, height: 12)
                                .shadow(color: color, radius: 10)
                        }
                        .position(lastPoint)
                    }
                }
            }
        }
    }
}

// MARK: - Daily Check-In Sheet
struct DailyCheckInSheet: View {
    @EnvironmentObject private var ageStore: AgeStore
    @Environment(\.dismiss) var dismiss
    @State private var sleepHours: Double = 7.0
    @State private var steps: Int = 6000
    @State private var vigorousMinutes: Int = 0
    @State private var stressLevel: Int = 5
    @State private var lateCaffeine: Bool = false
    @State private var lateScreenUsage: Bool = false
    @State private var bedtimeHour: Double = 22.0
    @State private var isSubmitting = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Form {
                    Section(header: Text("Sleep").foregroundColor(.white)) {
                        Stepper("Sleep Hours: \(String(format: "%.1f", sleepHours))", value: $sleepHours, in: 0...12, step: 0.5)
                            .foregroundColor(.white)
                        Stepper("Bedtime Hour: \(String(format: "%.0f", bedtimeHour)):00", value: $bedtimeHour, in: 18...24, step: 0.5)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(.systemGray6))
                    
                    Section(header: Text("Activity").foregroundColor(.white)) {
                        Stepper("Steps: \(steps)", value: $steps, in: 0...50000, step: 1000)
                            .foregroundColor(.white)
                        Stepper("Vigorous Minutes: \(vigorousMinutes)", value: $vigorousMinutes, in: 0...300, step: 5)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(.systemGray6))
                    
                    Section(header: Text("Stress").foregroundColor(.white)) {
                        Stepper("Stress Level: \(stressLevel)/10", value: $stressLevel, in: 1...10)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(.systemGray6))
                    
                    Section(header: Text("Habits").foregroundColor(.white)) {
                        Toggle("Late Caffeine (after 16:00)", isOn: $lateCaffeine)
                            .foregroundColor(.white)
                        Toggle("Late Screen Usage", isOn: $lateScreenUsage)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(.systemGray6))
                    
                    Section {
                        Button(action: submitCheckIn) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                                    Text("Submit Check-In")
                                        .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
                            .background(isSubmitting ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isSubmitting)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
            }
        }
        }
        .preferredColorScheme(.dark)
    }
    
    private func submitCheckIn() {
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let metrics = DailyUpdateRequest.Metrics(
            date: today,
            sleepHours: sleepHours,
            steps: steps,
            vigorousMinutes: vigorousMinutes,
            processedFoodScore: 3,
            alcoholUnits: 0,
            stressLevel: stressLevel,
            lateCaffeine: lateCaffeine,
            screenLate: lateScreenUsage,
            bedtimeHour: bedtimeHour
        )
        
        let request = DailyUpdateRequest(metrics: metrics)
        
                    Task {
            await ageStore.submitDailyUpdate(request)
            await MainActor.run {
                isSubmitting = false
                if ageStore.lastError == nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Plan View
struct PlanView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Text("Plan")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    
                    Text("Your personalized longevity plan will appear here.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Plan")
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Profile View (Profile & Settings)
struct ProfileView: View {
    @EnvironmentObject private var ageStore: AgeStore
    @EnvironmentObject private var appState: AppState
    @StateObject private var authManager = AuthManager.shared
    @State private var showLogoutAlert: Bool = false
    @State private var isLoggingOut: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var selectedLanguage: String = "English"
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var contentOffset: CGFloat = 0
    @State private var isDeletePressed: Bool = false
    
    private let availableLanguages = ["English", "Türkçe", "Español", "Français", "Deutsch"]
    private let cardSpacing: CGFloat = 24
    private let cardPadding: CGFloat = 20
    
    private var displayName: String {
        if let firstName = appState.userFirstName, let lastName = appState.userLastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = appState.userFirstName {
            return firstName
        } else if let lastName = appState.userLastName {
            return lastName
        } else {
            return ""
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Page Header (Score screen style)
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            
                            Text("PROFILE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .kerning(1.5)
                            
                            Spacer()
                        }
                        
                        // User name
                        if !displayName.isEmpty {
                            Text(displayName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .kerning(-0.3)
                        }
                    }
                    .padding(.horizontal, cardPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    
                    // Membership Card (Primary)
                    membershipCard
                        .padding(.horizontal, cardPadding)
                        .padding(.bottom, cardSpacing)
                    
                    // Language Card (Secondary)
                    languageCard
                        .padding(.horizontal, cardPadding)
                        .padding(.bottom, cardSpacing)
                    
                    // Legal Section (Low emphasis)
                    legalSection
                        .padding(.horizontal, cardPadding)
                        .padding(.bottom, cardSpacing * 2)
                    
                    // Account Actions (Bottom, de-emphasized)
                    accountActions
                        .padding(.horizontal, cardPadding)
                        .padding(.bottom, 60)
                }
                .opacity(contentOffset > 0 ? 1 : 0)
                .offset(y: contentOffset > 0 ? 0 : 20)
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task {
                    await handleLogout()
                }
            }
        } message: {
            Text("You will need to sign in again to access your account.")
        }
        .alert("Delete account?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await handleDeleteAccount()
                }
            }
        } message: {
            Text("This will permanently delete your data and cannot be undone.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                contentOffset = 1
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
    
    // MARK: - Membership Card (Primary, visually dominant)
    private var membershipCard: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            openAppleSubscriptions()
        }) {
            MinimalCard(elevated: true) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Membership")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Monthly membership")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Managed via Apple Subscriptions")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
            Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    HStack(spacing: 6) {
                        Text("Open Subscriptions")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 4)
                }
                .padding(24)
            }
        }
        .buttonStyle(MinimalButtonStyle())
    }
    
    private func openAppleSubscriptions() {
        if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Language Card (Secondary)
    private var languageCard: some View {
        Menu {
            ForEach(availableLanguages, id: \.self) { language in
                    Button(action: {
                    selectedLanguage = language
                }) {
                    HStack {
                        Text(language)
                        if selectedLanguage == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            MinimalCard {
                HStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Language")
                                .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(selectedLanguage)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Legal Section (Low emphasis)
    private var legalSection: some View {
        MinimalCard {
            VStack(spacing: 0) {
                Button(action: { showTerms = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(width: 16)
                        
                        Text("Terms of Service")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 28)
                
                Button(action: { showPrivacy = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(width: 16)
                        
                        Text("Privacy Policy")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Account Actions (Bottom, de-emphasized)
    private var accountActions: some View {
        VStack(spacing: 20) {
            // Log out (neutral text button)
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showLogoutAlert = true
            }) {
                Text("Log out")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Delete account (small text button, red only on interaction)
            Button(action: {
                showDeleteAccountAlert = true
            }) {
                Text("Delete account")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isDeletePressed ? .red.opacity(0.8) : .white.opacity(0.4))
            }
            .onLongPressGesture(minimumDuration: 0) { pressing in
                isDeletePressed = pressing
                if pressing {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            } perform: {}
        }
    }
    
    private func handleLogout() async {
        isLoggingOut = true
        do {
            // Call backend logout endpoint
            try await APIClient.shared.postLogout()
        } catch {
            print("[ProfileView] Backend logout failed: \(error)")
            // Continue with client-side logout even if backend fails
        }
        
        // Client-side logout - must be on MainActor since AuthManager is @MainActor
        await MainActor.run {
            do {
                try authManager.signOut()
                print("[ProfileView] Successfully signed out from Firebase")
            } catch {
                print("[ProfileView] Sign out failed: \(error)")
            }
        }
        
        await MainActor.run {
            isLoggingOut = false
        }
    }
    
    private func handleDeleteAccount() async {
        isDeletingAccount = true
        // TODO: Implement delete account API call
        // For now, just show a placeholder
        // Call backend delete account endpoint when available
        // try await APIClient.shared.deleteAccount()
        print("[ProfileView] Delete account requested")
        
        // After successful deletion, logout
        await handleLogout()
        
        await MainActor.run {
            isDeletingAccount = false
        }
    }
}

// MARK: - AI Coach Indicator
struct AICoachIndicator: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.3
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                // Outer pulsing ring
                Circle()
                    .stroke(Color.green.opacity(ringOpacity), lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .scaleEffect(pulseScale)
                
                // Inner dot
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: .green.opacity(0.6), radius: 4)
            }
            
            Text("AI Coach • Active")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.green.opacity(0.8))
                .kerning(0.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
                ringOpacity = 0.1
            }
        }
    }
}

// MARK: - Minimal Profile Icon
struct MinimalProfileIcon: View {
    @State private var breathingScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Soft glow/halo background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.green.opacity(0.1), Color.green.opacity(0.0)],
                        center: .center,
                        startRadius: 15,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)
                .blur(radius: 6)
            
            // Thin ring with subtle glow
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: 60, height: 60)
                .shadow(color: Color.green.opacity(0.2), radius: 8)
            
            // Inner circle
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            // App Icon (circular)
            Image("ikon")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        }
        .scaleEffect(breathingScale)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.02
            }
        }
    }
}

// MARK: - AI Coach Status Row
struct AICoachStatusRow: View {
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 8) {
            // Tiny pulsing dot
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseScale)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            
            Text("AI Coach • Active")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }
}

// MARK: - Minimal Card Component
struct MinimalCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var elevated: Bool = false
    
    init(elevated: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.elevated = elevated
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: elevated ? Color.black.opacity(0.3) : Color.black.opacity(0.2),
                        radius: elevated ? 16 : 8,
                        x: 0,
                        y: elevated ? 8 : 4
                    )
            )
    }
}

// MARK: - Minimal Button Style
struct MinimalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue && !oldValue {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Terms of Service")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text("Last updated: December 2025")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Please read these terms of service carefully before using our application.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)
                        
                        // Add your terms content here
                        Text("1. Acceptance of Terms\n\nBy accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 16)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Privacy Policy")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text("Last updated: December 2025")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("We are committed to protecting your privacy. This policy explains how we collect, use, and safeguard your information.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)
                        
                        // Add your privacy policy content here
                        Text("1. Information We Collect\n\nWe collect information that you provide directly to us, including your name, email address, and health metrics.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 16)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Refer View
struct ReferView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var referralCode: String = "LONGEVITY2025"
    @State private var copiedToClipboard: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            
                            Text("Refer Friends")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Share Longevity AI with friends and earn rewards")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Referral Code
                        VStack(spacing: 12) {
                            Text("YOUR REFERRAL CODE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .kerning(1)
                            
                            HStack(spacing: 12) {
                                Text(referralCode)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.green.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                
                                Button(action: {
                                    UIPasteboard.general.string = referralCode
                                    copiedToClipboard = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        copiedToClipboard = false
                                    }
                                }) {
                                    Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.green)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(Color.green.opacity(0.1))
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            
                            if copiedToClipboard {
                                Text("Copied to clipboard!")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        // Share Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                // Share via system share sheet
                                shareReferralCode()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Referral Code")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Refer Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func shareReferralCode() {
        let text = "Join me on Longevity AI! Use my referral code: \(referralCode)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Subscription View
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: String = "premium"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.yellow)
                            
                            Text("Premium Subscription")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Unlock all features and maximize your longevity journey")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Features List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PREMIUM FEATURES")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .kerning(1)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                featureRow(icon: "sparkles", text: "Advanced AI Coaching")
                                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Detailed Analytics")
                                featureRow(icon: "bell.badge.fill", text: "Priority Support")
                                featureRow(icon: "lock.open.fill", text: "Unlimited Check-ins")
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        // Subscribe Button
                        Button(action: {
                            // Handle subscription purchase
                            print("Subscribe to premium")
                        }) {
                            HStack {
                                Text("Subscribe to Premium")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Supporting Types and Views
enum CoachTone: String {
    case supportive = "Supportive"
    case scientific = "Scientific"
    case direct = "Direct"
}

enum ResponseStyle: String {
    case short = "Short"
    case balanced = "Balanced"
    case expert = "Expert"
}

enum OptimizationGoal: String, Hashable {
    case highEnergy = "High Energy"
    case betterSleep = "Better Sleep"
    case stressResilience = "Stress Resilience"
    
    var icon: String {
        switch self {
        case .highEnergy: return "bolt.fill"
        case .betterSleep: return "moon.fill"
        case .stressResilience: return "leaf.fill"
        }
    }
}

struct GoalChip: View {
    let goal: OptimizationGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: goal.icon)
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                
                Text(goal.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(Color.green.opacity(isSelected ? 0.3 : 0.15), lineWidth: 1)
                    )
            )
        }
    }
}

struct SegmentedPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.green.opacity(0.2) : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.green.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: isSelected ? Color.green.opacity(0.3) : Color.clear, radius: 8)
        }
    }
}

// MARK: - New Onboarding & Daily Check-in Components

struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct OnboardingProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let currentQuestionIndex: Int
    let totalQuestions: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
            
            // Progress text
            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(totalQuestions)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

struct DailyCheckInPinnedCard: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var appState: AppState
    
    var body: some View {
        let state = viewModel.dailyCheckInState
        let isExpanded: Bool = {
            if case .active(let expanded) = state {
                return expanded
            }
            return false
        }()
        
        return VStack(spacing: 0) {
            if case .completed = state {
                // Completed state
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    
                    Text("Daily Check-in Complete")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                Spacer()
                    
                    Button(action: {
                        withAnimation {
                            viewModel.toggleDailyCheckIn()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
            } else {
                // Expandable card (INACTIVE or ACTIVE)
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Check-in")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Takes ~30 seconds")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        if isExpanded {
                            Text("\(Int(viewModel.dailyProgress * 100))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {
                            withAnimation {
                                viewModel.toggleDailyCheckIn()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 14))
                        }
                    }
                    
                    if isExpanded {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * viewModel.dailyProgress, height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        // Current question or intro
                        if let question = viewModel.currentDailyQuestion {
                            VStack(alignment: .leading, spacing: 12) {
                                if viewModel.currentDailyQuestionIndex == 0 {
                                    Text("Let's do your daily check-in. How was your sleep last night?")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                } else {
                                    Text(question.prompt)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                VStack(spacing: 8) {
                                    ForEach(question.options) { option in
                                        OptionButton(
                                            title: option.title,
                                            isSelected: false,
                                            action: {
                                                viewModel.selectDailyOption(option)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Longevity AI Loading View
struct LongevityAILoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Infinity symbol with rotation animation
            ZStack {
                // Infinity symbol path
                InfinityShape()
                    .stroke(Color(red: 0.2, green: 0.5, blue: 0.35), lineWidth: 2.5)
                    .frame(width: 28, height: 14)
                    .rotationEffect(.degrees(rotation))
            }
            .frame(width: 36, height: 36)
            
            Text("Longevity AI")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
        )
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// Infinity symbol shape
struct InfinityShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2
        let radius = min(width, height) / 4
        
        // Left loop - complete circle
        path.addArc(
            center: CGPoint(x: centerX - radius, y: centerY),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )
        
        // Right loop - complete circle
        path.addArc(
            center: CGPoint(x: centerX + radius, y: centerY),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )
        
        return path
    }
}

// MARK: - Delta Analytics Chart Views

struct DeltaChartView: View {
    @ObservedObject var viewModel: DeltaAnalyticsViewModel
    let range: String  // "weekly", "monthly", or "yearly"
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Area
            if viewModel.isLoading {
                DeltaChartLoadingView()
                    .frame(height: 200)
            } else if let error = viewModel.errorMessage {
                DeltaChartErrorView(message: error)
                    .frame(height: 200)
            } else if range == "yearly" {
                YearlyDeltaChartView(points: viewModel.monthlyPoints)
                    .frame(height: 200)
            } else {
                DailyDeltaChartView(points: viewModel.dailyPoints)
                    .frame(height: 200)
            }
        }
    }
}


// MARK: - Daily Chart View (Weekly/Monthly)

struct DailyDeltaChartView: View {
    let points: [DeltaDailyPoint]
    
    var body: some View {
        if points.isEmpty {
            VStack {
                Text("No data available")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart {
                let firstValidIndex = points.firstIndex { $0.dailyDeltaYears != nil }
                
                ForEach(Array(points.enumerated()), id: \.element.date) { index, point in
                    if let dailyDeltaYears = point.dailyDeltaYears {
                        let isFirstAttentionPoint = dailyDeltaYears > 0.5 && index == firstValidIndex
                        
                        // Determine color based on delta value (daily change, not absolute age comparison)
                        // Negative delta = rejuvenation, Positive delta = aging
                        let deltaColorState: BiologicalAgeColorState = {
                            if dailyDeltaYears < -0.5 {
                                return .positive // Significant rejuvenation
                            } else if abs(dailyDeltaYears) <= 0.5 {
                                return .neutral // Minimal change
                            } else {
                                return .attention // Significant aging (amber, not red)
                            }
                        }()
                        
                        let lineColor = deltaColorState.color.opacity(0.7)
                        let pointColor = deltaColorState == .attention && isFirstAttentionPoint 
                            ? deltaColorState.color.opacity(0.5) 
                            : deltaColorState.color.opacity(0.6)
                        
                        LineMark(
                            x: .value("Date", parseDate(point.date)),
                            y: .value("Delta", dailyDeltaYears)
                        )
                        .foregroundStyle(lineColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        
                        PointMark(
                            x: .value("Date", parseDate(point.date)),
                            y: .value("Delta", dailyDeltaYears)
                        )
                        .foregroundStyle(pointColor)
                        .symbolSize(36)
                    }
                    // If dailyDeltaYears is nil, no mark is drawn (creates gap)
                }
                
                // Zero line (subtle)
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(.white.opacity(0.15))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel(format: .dateTime.month().day())
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.system(size: 9))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.system(size: 9))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.clear)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Yearly Chart View

struct YearlyDeltaChartView: View {
    let points: [DeltaMonthlyPoint]
    
    var body: some View {
        if points.isEmpty {
            VStack {
                Text("No data available")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart {
                ForEach(points, id: \.month) { point in
                    // Determine color based on net delta value
                    let deltaColorState: BiologicalAgeColorState = {
                        if point.netDelta < -0.5 {
                            return .positive
                        } else if abs(point.netDelta) <= 0.5 {
                            return .neutral
                        } else {
                            return .attention
                        }
                    }()
                    
                    BarMark(
                        x: .value("Month", parseMonth(point.month)),
                        y: .value("Net Delta", point.netDelta)
                    )
                    .foregroundStyle(deltaColorState.color.opacity(0.7))
                    .cornerRadius(4)
                }
                
                // Zero line (subtle)
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(.white.opacity(0.15))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.system(size: 9))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.system(size: 9))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.clear)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func parseMonth(_ monthString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: monthString) ?? Date()
    }
}

// MARK: - Loading View

struct DeltaChartLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            Text("Loading chart...")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

struct DeltaChartErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
