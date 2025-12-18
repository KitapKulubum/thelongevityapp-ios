//
//  MainTabView.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var ageStore = AgeStore()
    
    var body: some View {
        TabView {
            AICoachView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("AI")
                }
            
            PlanView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Plan")
                }
            
            LongevityTrendView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Score")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
        .environmentObject(ageStore)
        .preferredColorScheme(.dark)
        .onAppear {
            if let userId = AuthManager.shared.userId {
                Task {
                    await ageStore.refreshAll(userId: userId)
                }
            }
        }
    }
}

// MARK: - AI Coach View (Left Screen)
struct AICoachView: View {
    @EnvironmentObject private var ageStore: AgeStore
    @State private var chatMessage: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var checkInStep: CheckInStep? = nil
    @State private var tempMetrics = DailyUpdateRequest.Metrics(
        date: "", sleepHours: 7.0, steps: 6000, vigorousMinutes: 0,
        processedFoodScore: 3, alcoholUnits: 0, stressLevel: 5,
        lateCaffeine: false, screenLate: false, bedtimeHour: 22.0
    )
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Glowing green pattern overlay
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.green.opacity(0.1), Color.clear], center: .center, startRadius: 50, endRadius: 200))
                    .frame(width: 400, height: 400)
                    .blur(radius: 50)
            }
            .offset(x: 0, y: -100)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Longevity AI is ready.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Let's optimize your healthspan.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            if messages.isEmpty && checkInStep == nil {
                                // Large glowing green checkmark (Initial state)
                                ZStack {
                                    Circle()
                                        .fill(RadialGradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)], center: .center, startRadius: 30, endRadius: 80))
                                        .frame(width: 160, height: 160)
                                        .blur(radius: 20)
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 120, height: 120)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 70, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 0)
                                .padding(.vertical, 40)
                                
                                ActionButton(title: "Start Daily Check-In", action: startCheckIn)
                                    .padding(.horizontal, 24)
                                
                                ActionButton(title: "Analyze Habits", action: {
                                    let msg = "Analyze my health habits and suggest longevity optimizations."
                                    messages.append(ChatMessage(isUser: true, text: msg))
                                    sendFreeTextMessage(msg)
                                })
                                    .padding(.horizontal, 24)
                                
                                ActionButton(title: "Suggest Improvements", action: {
                                    let msg = "What are the top 3 things I can do to lower my biological age?"
                                    messages.append(ChatMessage(isUser: true, text: msg))
                                    sendFreeTextMessage(msg)
                                })
                                    .padding(.horizontal, 24)
                            } else {
                                ForEach(messages) { msg in
                                    ChatBubble(message: msg)
                                        .id(msg.id)
                                }
                                
                                if let step = checkInStep {
                                    StepControlView(step: step, metrics: $tempMetrics, onAnswer: handleAnswer)
                                        .id("step-control")
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id ?? "step-control", anchor: .bottom)
                        }
                    }
                }
                
                // Chat input
                HStack {
                    TextField("Ask Longevity AI anything...", text: $chatMessage)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Button(action: {
                        if !chatMessage.isEmpty {
                            let text = chatMessage
                            messages.append(ChatMessage(isUser: true, text: text))
                            chatMessage = ""
                            sendFreeTextMessage(text)
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func startCheckIn() {
        messages.append(ChatMessage(isUser: false, text: "Welcome to your longevity check-in! Let's start with your sleep. How many hours did you sleep last night?"))
        checkInStep = .sleep
    }
    
    private func handleAnswer(answer: String) {
        messages.append(ChatMessage(isUser: true, text: answer))
        
        switch checkInStep {
        case .sleep:
            messages.append(ChatMessage(isUser: false, text: "Great. How many steps did you take today?"))
            checkInStep = .steps
        case .steps:
            messages.append(ChatMessage(isUser: false, text: "How many minutes of vigorous exercise did you do?"))
            checkInStep = .vigorous
        case .vigorous:
            messages.append(ChatMessage(isUser: false, text: "On a scale of 1-10, how much processed food did you eat?"))
            checkInStep = .processedFood
        case .processedFood:
            messages.append(ChatMessage(isUser: false, text: "How many units of alcohol did you consume?"))
            checkInStep = .alcohol
        case .alcohol:
            messages.append(ChatMessage(isUser: false, text: "How was your stress level today? (1-10)"))
            checkInStep = .stress
        case .stress:
            messages.append(ChatMessage(isUser: false, text: "Did you have caffeine after 16:00?"))
            checkInStep = .caffeine
        case .caffeine:
            messages.append(ChatMessage(isUser: false, text: "Did you use screens in the hour before bed?"))
            checkInStep = .screen
        case .screen:
            messages.append(ChatMessage(isUser: false, text: "What time did you go to bed?"))
            checkInStep = .bedtime
        case .bedtime:
            checkInStep = nil
            submitUpdate()
        case nil:
            break
        }
    }
    
    private func sendFreeTextMessage(_ text: String) {
        // If we're in the middle of a check-in, don't send to generic chat
        if checkInStep != nil {
            handleAnswer(answer: text)
            return
        }
        
        Task {
            LongevityAPI.shared.sendChatMessage(message: text) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let answer):
                        messages.append(ChatMessage(isUser: false, text: answer))
                    case .failure(let error):
                        messages.append(ChatMessage(isUser: false, text: "Error: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }
    
    private func submitUpdate() {
        messages.append(ChatMessage(isUser: false, text: "Processing your results..."))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        tempMetrics.date = dateFormatter.string(from: Date())
        
        let request = DailyUpdateRequest(
            userId: AuthManager.shared.userId ?? "gizem-demo",
            chronologicalAgeYears: ageStore.profileChronologicalAgeYears ?? 32.0,
            metrics: tempMetrics
        )
        
        Task {
            await ageStore.submitDailyUpdate(request)
            await MainActor.run {
                if let error = ageStore.lastError {
                    messages.append(ChatMessage(isUser: false, text: "Error saving data: \(error.localizedDescription)"))
                } else {
                    let bioAge = String(format: "%.2f", ageStore.currentBiologicalAgeYears ?? 0)
                    let delta = String(format: "%.2f", ageStore.todayDeltaYears ?? 0)
                    messages.append(ChatMessage(isUser: false, text: "Done! Your biological age is now \(bioAge). Today's change: \(delta) years."))
                    if !ageStore.todayReasons.isEmpty {
                        messages.append(ChatMessage(isUser: false, text: "Key factors: " + ageStore.todayReasons.joined(separator: ", ")))
                    }
                }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID().uuidString
    let isUser: Bool
    let text: String
}

struct ChatBubble: View {
    let message: ChatMessage
    
    private var formattedText: String {
        var processed = message.text
        // Handle headers by converting them to bold lines
        let lines = processed.components(separatedBy: .newlines)
        let cleanedLines = lines.map { line -> String in
            var l = line.trimmingCharacters(in: .whitespaces)
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
        HStack {
            if message.isUser { Spacer() }
            Text(.init(formattedText))
                .padding()
                .background(message.isUser ? Color.green.opacity(0.2) : Color(.systemGray6))
                .cornerRadius(16)
                .foregroundColor(.white)
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal, 24)
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
        VStack(spacing: 12) {
            switch step {
            case .sleep:
                HStack {
                    ForEach([5.0, 6.0, 7.0, 8.0, 9.0], id: \.self) { hr in
                        Button("\(Int(hr))h") {
                            metrics.sleepHours = hr
                            onAnswer("\(Int(hr)) hours")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            case .steps:
                HStack {
                    ForEach([2000, 5000, 8000, 10000, 15000], id: \.self) { s in
                        Button("\(s/1000)k") {
                            metrics.steps = s
                            onAnswer("\(s) steps")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            case .vigorous:
                HStack {
                    ForEach([0, 15, 30, 45, 60], id: \.self) { m in
                        Button("\(m)m") {
                            metrics.vigorousMinutes = m
                            onAnswer("\(m) minutes")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            case .processedFood:
                HStack {
                    ForEach([1, 3, 5, 8, 10], id: \.self) { level in
                        Button("\(level)") {
                            metrics.processedFoodScore = level
                            onAnswer("Score \(level)")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            case .alcohol:
                HStack {
                    ForEach([0, 1, 2, 3, 5], id: \.self) { unit in
                        Button("\(unit)") {
                            metrics.alcoholUnits = unit
                            onAnswer("\(unit) units")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            case .stress:
                HStack {
                    ForEach([1, 3, 5, 8, 10], id: \.self) { l in
                        Button("\(l)") {
                            metrics.stressLevel = l
                            onAnswer("Level \(l)")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            case .caffeine:
                HStack {
                    Button("No") {
                        metrics.lateCaffeine = false
                        onAnswer("No caffeine")
                    }
                    Button("Yes") {
                        metrics.lateCaffeine = true
                        onAnswer("Yes, had caffeine")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            case .screen:
                HStack {
                    Button("No") {
                        metrics.screenLate = false
                        onAnswer("No screens")
                    }
                    Button("Yes") {
                        metrics.screenLate = true
                        onAnswer("Yes, used screens")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            case .bedtime:
                HStack {
                    ForEach([21.0, 22.0, 23.0, 0.0, 1.0], id: \.self) { t in
                        Button(String(format: "%.0f:00", t)) {
                            metrics.bedtimeHour = t
                            onAnswer(String(format: "%.0f:00", t))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 1)
                        .background(Color.clear)
                )
        }
    }
}

// MARK: - Longevity Trend View (Right Screen)
struct LongevityTrendView: View {
    @EnvironmentObject private var ageStore: AgeStore
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Header with Rejuvenation Chip
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        Spacer()
                        Text("LONGEVITY AGE & TREND")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        
                        // Rejuvenation/Acceleration Chip
                        if let ca = ageStore.profileChronologicalAgeYears,
                           let ba = ageStore.currentBiologicalAgeYears {
                            let diff = ba - ca
                            let isGood = diff <= 0
                            
                            HStack(spacing: 4) {
                                Image(systemName: isGood ? "sparkles" : "arrow.up.right")
                                    .font(.caption)
                                Text(String(format: "%@: %+.2fy", isGood ? "Rejuvenation" : "Acceleration", diff))
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isGood ? Color.green : Color.orange)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 2. Large Age Cards (CA vs BA)
                    HStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text(String(format: "%.2f", ageStore.profileChronologicalAgeYears ?? 32.0))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                            Text("CHRONOLOGICAL")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 60)
                            .background(Color.gray.opacity(0.3))
                        
                        VStack(spacing: 8) {
                            Text(String(format: "%.2f", ageStore.currentBiologicalAgeYears ?? 32.0))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("BIOLOGICAL")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 20)
                    
                    // 3. Trend Graph
                    VStack(spacing: 20) {
                        if !ageStore.trendPoints.isEmpty {
                            TrendChartView(points: ageStore.trendPoints)
                                .frame(height: 220)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 220)
                                .overlay(Text("Loading trend...").foregroundColor(.gray))
                        }
                        
                        // Range Selector (Green Pill)
                        HStack {
                            Spacer()
                            Picker("Range", selection: $ageStore.selectedRange) {
                                Text("WEEKLY").tag(TrendRange.weekly)
                                Text("MONTHLY").tag(TrendRange.monthly)
                                Text("YEARLY").tag(TrendRange.yearly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 280)
                            .onChange(of: ageStore.selectedRange) { oldValue, newRange in
                                if let userId = AuthManager.shared.userId {
                                    Task { await ageStore.loadTrend(userId: userId, range: newRange) }
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 4. Trend Analysis (Debt, Today, Streak)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TREND ANALYSIS")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            // Aging Debt Card
                            MetricSmallCard(
                                title: "Aging Debt",
                                value: String(format: "%+.2fy", ageStore.agingDebtYears ?? 0),
                                isGood: (ageStore.agingDebtYears ?? 0) <= 0
                            )
                            
                            // Today Change Card
                            MetricSmallCard(
                                title: "Today Δ",
                                value: String(format: "%+.2fy", ageStore.todayDeltaYears ?? 0),
                                isGood: (ageStore.todayDeltaYears ?? 0) <= 0
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Streak Badge
                        if ageStore.rejuvenationStreakDays > 0 {
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text("\(ageStore.rejuvenationStreakDays) DAY STREAK")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(30)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    // 5. Share Insights
                    VStack(spacing: 16) {
                        Text("SHARE INSIGHTS")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            ShareButton(icon: "camera.fill")
                            ShareButton(icon: "play.tv.fill")
                            ShareButton(icon: "square.and.arrow.up")
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct MetricSmallCard: View {
    let title: String
    let value: String
    let isGood: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(isGood ? .green : .orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

struct AgeCard: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

struct TrendChartView: View {
    let points: [TrendPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Background Glow
                Path { path in
                    let maxAge = points.map { $0.biologicalAgeYears }.max() ?? 33.0
                    let minAge = points.map { $0.biologicalAgeYears }.min() ?? 31.0
                    let ageRange = max(maxAge - minAge, 1.0)
                    
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let normalizedAge = (point.biologicalAgeYears - minAge) / ageRange
                        let y = height * (1 - normalizedAge)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    // Close the path for fill
                    if !points.isEmpty {
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                }
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.2), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Chart line
                Path { path in
                    let maxAge = points.map { $0.biologicalAgeYears }.max() ?? 33.0
                    let minAge = points.map { $0.biologicalAgeYears }.min() ?? 31.0
                    let ageRange = max(maxAge - minAge, 1.0)
                    
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let normalizedAge = (point.biologicalAgeYears - minAge) / ageRange
                        let y = height * (1 - normalizedAge)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.green, lineWidth: 3)
                
                // "Now" marker at the end
                if !points.isEmpty {
                    let maxAge = points.map { $0.biologicalAgeYears }.max() ?? 1
                    let minAge = points.map { $0.biologicalAgeYears }.min() ?? 0
                    let ageRange = max(maxAge - minAge, 1)
                    let lastIndex = points.count - 1
                    let x = width * CGFloat(lastIndex) / CGFloat(max(points.count - 1, 1))
                    let normalizedAge = (points[lastIndex].biologicalAgeYears - minAge) / ageRange
                    let y = height * (1 - normalizedAge)
                    
                    // Point
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)
                        .shadow(color: .green, radius: 5)
                    
                    // Label
                    VStack {
                        Text("Now")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .position(x: x, y: y + 40)
                }
            }
        }
    }
}

struct ShareButton: View {
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(12)
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

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject private var ageStore: AgeStore
    @State private var chronoAge: Double = 32.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Settings")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Chronological Age")
                            .foregroundColor(.gray)
                        HStack {
                            Slider(value: $chronoAge, in: 18...100, step: 1)
                            Text("\(Int(chronoAge))")
                                .font(.title2.bold())
                                .foregroundColor(.green)
                                .frame(width: 50)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button(action: {
                        if AuthManager.shared.userId != nil {
                            // Update local store and send a dummy update to set the age on backend
                            ageStore.profileChronologicalAgeYears = chronoAge
                            // You might want to call an API to update the profile explicitly here
                        }
                    }) {
                        Text("Save Profile")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Text("User ID: \(AuthManager.shared.userId ?? "gizem-demo")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
    }
}
