//
//  MainTabView.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var ageStore = AgeStore()
    @EnvironmentObject private var appState: AppState
    
    init() {
        // AppState will be provided via environmentObject from RootView
    }
    
    var body: some View {
        TabView(selection: $appState.activeTab) {
            AICoachView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("AI")
                }
                .tag(Tab.chat)

            LongevityTrendView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Score")
                }
                .tag(Tab.score)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(Tab.profile)
        }
        .environmentObject(ageStore)
        .environmentObject(appState)
        .preferredColorScheme(.dark)
        .onAppear {
            // Bootstrap app state
            Task {
                await appState.bootstrap()
            }
            
            // Also refresh age store for backward compatibility
            if let userId = AuthManager.shared.userId {
                Task {
                    await ageStore.loadSummary(userId: userId)
                }
            }
        }
    }
}

// MARK: - AI Coach View (Chat Screen)
struct AICoachView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @State private var chatMessage: String = ""
    
    init() {
        let tempAppState = AppState(userId: AuthManager.shared.userId ?? "gizem-demo")
        _viewModel = StateObject(wrappedValue: ChatViewModel(appState: tempAppState))
    }
    
    var body: some View {
        let isDailyMode = viewModel.mode == .daily
        let isEmptyDaily = viewModel.messages.isEmpty && viewModel.mode == .daily
        
        return VStack(spacing: 0) {
            // Daily check-in pinned card (only in daily mode)
            if isDailyMode {
                DailyCheckInPinnedCard(viewModel: viewModel, appState: appState)
            }
            
            // Messages area
            if isEmptyDaily {
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
                            ForEach(viewModel.messages) { message in
                                VStack(spacing: 8) {
                                    ChatBubbleView(message: message)
                                        .opacity(viewModel.isChatDisabled ? 0.4 : 1.0)
                                    
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
                            
                            // Onboarding question options
                            if viewModel.mode == .onboarding,
                               let question = viewModel.currentOnboardingQuestion,
                               !viewModel.isSubmitting {
                                VStack(spacing: 12) {
                                    ForEach(question.options) { option in
                                        OptionButton(
                                            title: option.title,
                                            isSelected: false,
                                            action: {
                                                viewModel.selectOnboardingOption(option)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
                            // Daily check-in question options (when ACTIVE && expanded)
                            if viewModel.mode == .daily,
                               case .active(let expanded) = viewModel.dailyCheckInState,
                               expanded,
                               let question = viewModel.currentDailyQuestion,
                               !viewModel.isSubmitting {
                                VStack(spacing: 12) {
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
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .disabled(viewModel.isChatDisabled)
                    .onChange(of: viewModel.messages.count) {
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Input bar (show in daily mode, but disabled when check-in is active)
            if viewModel.mode == .daily {
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
            } else if viewModel.mode == .onboarding {
                // No input bar in onboarding mode
                EmptyView()
            }
        }
        .background(
            BackgroundView()
                .ignoresSafeArea()
        )
        .onAppear {
            // Update viewModel's appState reference to use environment object
            viewModel.appState = appState
            
            // Start onboarding if not completed
            if !appState.hasCompletedOnboarding && viewModel.messages.isEmpty {
                viewModel.startOnboarding()
            }
        }
        .onChange(of: appState.hasCompletedOnboarding) { _, newValue in
            if newValue && viewModel.mode == .onboarding {
                // Switch to daily mode after onboarding
                viewModel.mode = .daily
            }
        }
    }
}

// ChatMessage is now defined in ChatViewModel.swift

struct ChatBubbleView: View {
    let message: ChatMessage
    
    private var formattedText: String {
        let processed = message.text
        // Handle headers by converting them to bold lines
        let lines = processed.components(separatedBy: CharacterSet.newlines)
        let cleanedLines = lines.map { line -> String in
            var l = line.trimmingCharacters(in: CharacterSet.whitespaces)
            if l.hasPrefix("### ") {
                l = "**" + l.replacingOccurrences(of: "### ", with: "") + "**"
            } else if l.hasPrefix("## ") {
                l = "**" + l.replacingOccurrences(of: "## ", with: "") + "**"
            } else if l.hasPrefix("# ") {
                l = "**" + l.replacingOccurrences(of: "# ", with: "") + "**"
            }
            return l
        }
        return cleanedLines.joined(separator: "\n")
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser { Spacer(minLength: 0) }
            
            Text(.init(formattedText))
                .font(.system(size: 15))
                .fixedSize(horizontal: false, vertical: true)
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
    @EnvironmentObject private var ageStore: AgeStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    // Design tokens
    private let screenPadding: CGFloat = 20
    private let sectionSpacing: CGFloat = 24
    private let cardRadius: CGFloat = 20
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 1. Header Row
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                        }
                        .frame(width: 44, height: 44)
                        
                        Spacer()
                        
                        Text("LONGEVITY AGE & TREND")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .kerning(1.5)
                        
                        Spacer()
                        
                        // Rejuvenation/Acceleration Chip
                        if let ca = ageStore.profileChronologicalAgeYears,
                           let ba = ageStore.currentBiologicalAgeYears {
                            let diff = ba - ca
                            let isGood = diff <= 0
                            
                            HStack(spacing: 6) {
                                Text(isGood ? "✨" : "↗")
                                Text(String(format: "%@: %+.1fy", isGood ? "Rejuvenation" : "Acceleration", diff))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(isGood ? .green : .orange)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill((isGood ? Color.green : Color.orange).opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke((isGood ? Color.green : Color.orange).opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .shadow(color: (isGood ? Color.green : Color.orange).opacity(0.2), radius: 8)
                } else {
                            // Placeholder to maintain layout
                            Color.clear.frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, screenPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    
                    // 2. Main Stats Block (Chronological & Biological)
                    HStack(spacing: 24) {
                        StatColumn(
                            value: {
                                if let ca = ageStore.profileChronologicalAgeYears {
                                    return ca
                                } else if let bio = appState.summary?.biologicalAge {
                                    return bio
                                } else {
                                    return 32.0
                                }
                            }(),
                            label: "CHRONOLOGICAL",
                            color: .white.opacity(0.4),
                            labelColor: .white.opacity(0.3)
                        )
                        
                        StatColumn(
                            value: ageStore.currentBiologicalAgeYears ?? appState.summary?.biologicalAge ?? 32.0,
                            label: "BIOLOGICAL",
                            color: .green,
                            labelColor: .green.opacity(0.6),
                            hasGlow: true
                        )
                    }
                    .padding(.horizontal, screenPadding)
                    .padding(.bottom, sectionSpacing)
                    
                    // BAO Years display (if available from summary)
                    if let baoYears = appState.summary?.BAOYears {
                        HStack {
                            Text("BAO: \(String(format: "%+.1f", baoYears)) years")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(baoYears < 0 ? .green : .orange)
                        }
                        .padding(.horizontal, screenPadding)
                        .padding(.bottom, 8)
                    }
                    
                    // Top Risk Systems (if available from summary)
                    if let topRisks = appState.summary?.topRiskSystems, !topRisks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOP RISK SYSTEMS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .kerning(1)
                            
                            HStack(spacing: 8) {
                                ForEach(topRisks.prefix(3), id: \.self) { risk in
                                    Text(risk.uppercased())
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.opacity(0.1))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, screenPadding)
                        .padding(.bottom, sectionSpacing)
                    }
                    
                    // 3. Time Range Segmented Control
                    HStack(spacing: 4) {
                        ForEach([TrendRange.weekly, .monthly, .yearly], id: \.self) { range in
                            Button(action: {
                                ageStore.selectedRange = range
                                // Trend data now comes from summary, no separate call needed
                                if let userId = AuthManager.shared.userId {
                                    Task { await ageStore.loadSummary(userId: userId) }
                                }
                            }) {
                                Text(range.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ageStore.selectedRange == range ? .black : .white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(ageStore.selectedRange == range ? Color.green : Color.clear)
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
                    .padding(.horizontal, screenPadding)
                    .padding(.bottom, sectionSpacing)
                    
                    // 4. Trend Graph Area
                    if !ageStore.trendPoints.isEmpty {
                        TrendChartView(points: ageStore.trendPoints)
                            .frame(height: 240)
                            .padding(.horizontal, screenPadding)
                            .padding(.bottom, sectionSpacing)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.green)
                            Text("Analyzing longevity trend...")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, screenPadding)
                        .padding(.bottom, sectionSpacing)
                    }
                    
                    // 5. Metrics Row (Aging Debt / Today Δ)
                    HStack(spacing: 24) {
                        MetricCard(
                            title: "AGING DEBT",
                            value: String(format: "%+.2fy", ageStore.agingDebtYears ?? 0),
                            isGood: (ageStore.agingDebtYears ?? 0) <= 0
                        )
                        
                        MetricCard(
                            title: "TODAY Δ",
                            value: String(format: "%+.2fy", ageStore.todayDeltaYears ?? 0),
                            isGood: (ageStore.todayDeltaYears ?? 0) <= 0
                        )
                        
                        Spacer()
                        
                        // Streak Badge
                            if ageStore.rejuvenationStreakDays > 0 {
                            HStack(spacing: 6) {
                                Text("🔥")
                                Text("\(ageStore.rejuvenationStreakDays) DAY STREAK")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                    }
                    .padding(.horizontal, screenPadding)
                    .padding(.bottom, sectionSpacing)
                    
                    // 6. Share Insights Row
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
                    .padding(.horizontal, screenPadding)
                    .padding(.bottom, 100) // Extra padding to avoid TabBar overlap
                }
            }
        }
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
    let isGood: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .kerning(1)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isGood ? .green : .orange)
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
    let points: [TrendPoint]
    
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
        guard let userId = AuthManager.shared.userId else {
            return
        }
        
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let chronologicalAge = ageStore.profileChronologicalAgeYears ?? 32.0
        
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
        
        let request = DailyUpdateRequest(
            userId: userId,
            chronologicalAgeYears: chronologicalAge,
            metrics: metrics
        )
        
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

// MARK: - Profile View (System Configuration)
struct ProfileView: View {
    @EnvironmentObject private var ageStore: AgeStore
    @State private var coachTone: CoachTone = .scientific
    @State private var responseStyle: ResponseStyle = .balanced
    @State private var selectedGoals: Set<OptimizationGoal> = [.highEnergy, .betterSleep, .stressResilience]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Subtle background glow
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.green.opacity(0.03), Color.clear], center: .center, startRadius: 50, endRadius: 200))
                    .frame(width: 400, height: 400)
                    .blur(radius: 50)
                    .offset(x: 0, y: -100)
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top Nav Bar
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                        }
                        
                        Spacer()
                        
                        Text("SYSTEM CONFIGURATION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .kerning(1.5)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // Header Block
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gizem")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: .green, radius: 4)
                                
                                Text("SYSTEM ACTIVE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                                    .kerning(1)
                            }
                        }
                        
            Spacer()
                        
                        Button(action: {}) {
                            ZStack {
                                Circle()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    
                    // Current Optimization Goals Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CURRENT OPTIMIZATION GOALS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .kerning(1)
                        
                        HStack(spacing: 12) {
                            GoalChip(
                                goal: .highEnergy,
                                isSelected: selectedGoals.contains(.highEnergy),
                                action: { toggleGoal(.highEnergy) }
                            )
                            
                            GoalChip(
                                goal: .betterSleep,
                                isSelected: selectedGoals.contains(.betterSleep),
                                action: { toggleGoal(.betterSleep) }
                            )
                            
                            GoalChip(
                                goal: .stressResilience,
                                isSelected: selectedGoals.contains(.stressResilience),
                                action: { toggleGoal(.stressResilience) }
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    
                    // AI Personalization Core Card
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text("AI PERSONALIZATION CORE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .kerning(1)
                        }
                        
                        // Coach Tone
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COACH TONE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .kerning(1)
                            
                            HStack(spacing: 8) {
                                SegmentedPill(
                                    title: "Supportive",
                                    isSelected: coachTone == .supportive,
                                    action: { coachTone = .supportive }
                                )
                                
                                SegmentedPill(
                                    title: "Scientific",
                                    isSelected: coachTone == .scientific,
                                    action: { coachTone = .scientific }
                                )
                                
                                SegmentedPill(
                                    title: "Direct",
                                    isSelected: coachTone == .direct,
                                    action: { coachTone = .direct }
                                )
                            }
                        }
                        
                        // Response Style
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RESPONSE STYLE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .kerning(1)
                            
                            HStack(spacing: 8) {
                                SegmentedPill(
                                    title: "Short",
                                    isSelected: responseStyle == .short,
                                    action: { responseStyle = .short }
                                )
                                
                                SegmentedPill(
                                    title: "Balanced",
                                    isSelected: responseStyle == .balanced,
                                    action: { responseStyle = .balanced }
                                )
                                
                                SegmentedPill(
                                    title: "Expert",
                                    isSelected: responseStyle == .expert,
                                    action: { responseStyle = .expert }
                                )
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    
                    // Update Configuration Button
                    Button(action: updateConfiguration) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("UPDATE CONFIGURATION")
                                .font(.system(size: 14, weight: .bold))
                                .kerning(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    // Latency Text
                    Text("AI PROCESSING LATENCY: 12MS")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .kerning(0.5)
                        .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func toggleGoal(_ goal: OptimizationGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
    
    private func updateConfiguration() {
        // TODO: Save to backend or UserDefaults
        print("Updating configuration: coachTone=\(coachTone), responseStyle=\(responseStyle), goals=\(selectedGoals)")
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
