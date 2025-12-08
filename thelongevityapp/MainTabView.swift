//
//  MainTabView.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AIHomeView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("AI")
                }

            ScoreView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Score")
                }

            DiscoverView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Discover")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

enum CheckInStep {
    case sleep
    case steps
    case vigorous
    case stress
    case caffeine
    case screen
    case done
}

struct GuidedCheckInData {
    var sleepHours: Double = 7.0
    var steps: Int = 6000
    var vigorousMinutes: Int = 0
    var stressLevel: Int = 5
    var lateCaffeine: Bool = false
    var lateScreenUsage: Bool = false
}

struct AIHomeView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(isUser: false, text: "Longevity AI is ready. Let's optimize your healthspan.")
    ]
    @State private var isInCheckIn = false
    @State private var currentStep: CheckInStep?
    @State private var checkInData = GuidedCheckInData()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var ageState: BiologicalAgeState?
    @State private var todayEntry: DailyAgeEntry?
    @State private var isLoadingAgeState = false
    @State private var headerStatusText: String = "Let's optimize your healthspan."
    @State private var subStatusText: String?
    @State private var hasCompletedToday = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Header + primary action
                    VStack(spacing: 8) {
                        Text("Longevity AI is ready.")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        if isLoadingAgeState {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .padding(.top, 4)
                        } else {
                            Text(headerStatusText)
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)

                            if let subStatusText = subStatusText {
                                Text(subStatusText)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        if !hasCompletedToday {
                            Button(action: startGuidedCheckIn) {
                                Text(isInCheckIn ? "Continue Today's Check-In" : "Start Today's Check-In")
                                    .fontWeight(.semibold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .foregroundColor(.black)
                                    .cornerRadius(16)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Chat messages
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        Text(message.text)
                                            .padding(12)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                    } else {
                                        Text(message.text)
                                            .padding(12)
                                            .background(Color(.systemGray6).opacity(0.2))
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }

                    // Step-specific answer buttons
                    if isInCheckIn, let step = currentStep {
                        stepControls(for: step)
                            .padding()
                    } else {
                        Text("Ask Longevity AI anything… (free chat can be wired later).")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            refreshAgeState()
        }
    }

    // MARK: - Age State Management

    private func refreshAgeState() {
        isLoadingAgeState = true

        LongevityAPI.shared.fetchAgeState(userId: "gizem-demo") { result in
            DispatchQueue.main.async {
                self.isLoadingAgeState = false
                switch result {
                case .success(let response):
                    self.ageState = response.state
                    self.todayEntry = response.today
                    self.updateHeaderTexts(from: response)
                case .failure(let error):
                    print("Age state fetch error:", error)
                    self.headerStatusText = "Unable to load today's status."
                    self.subStatusText = "You can still complete a check-in."
                }
            }
        }
    }

    private func updateHeaderTexts(from response: AgeStateResponse) {
        let state = response.state
        let today = response.today

        if let today = today {
            self.hasCompletedToday = true

            if today.deltaYears < 0 {
                headerStatusText = "You're trending younger today. ✨"
                subStatusText = String(
                    format: "Biological age moved %.2f years younger. Rejuvenation streak: %d days.",
                    abs(today.deltaYears),
                    state.rejuvenationStreakDays
                )
            } else if today.deltaYears > 0 {
                headerStatusText = "Small aging debt today. Let's course-correct. 🌙"
                subStatusText = String(
                    format: "Aging debt: %.2f years. Gentle evening routine can reverse this over the next days.",
                    today.deltaYears
                )
            } else {
                headerStatusText = "You're holding your biological age steady today. ⚖️"
                subStatusText = "Consistency protects your long-term healthspan."
            }
        } else {
            self.hasCompletedToday = false
            headerStatusText = "We need today's check-in. 🌱"
            subStatusText = "Complete a 1-minute check-in to update your biological age."
        }
    }

    // MARK: - Guided flow

    private func startGuidedCheckIn() {
        if !isInCheckIn {
            isInCheckIn = true
            checkInData = GuidedCheckInData()
            messages.append(ChatMessage(isUser: false,
                                        text: "Let's do a 1-minute longevity check-in. I'll ask you a few quick questions about today."))
        }
        askNextStep(.sleep)
    }

    private func askNextStep(_ step: CheckInStep) {
        currentStep = step

        switch step {
        case .sleep:
            messages.append(ChatMessage(isUser: false,
                                        text: "1️⃣ How many hours did you sleep last night?"))
        case .steps:
            messages.append(ChatMessage(isUser: false,
                                        text: "2️⃣ Roughly how many steps did you take today?"))
        case .vigorous:
            messages.append(ChatMessage(isUser: false,
                                        text: "3️⃣ How many minutes of vigorous movement did you have? (workout, cycling, etc.)"))
        case .stress:
            messages.append(ChatMessage(isUser: false,
                                        text: "4️⃣ How was your stress level today?"))
        case .caffeine:
            messages.append(ChatMessage(isUser: false,
                                        text: "5️⃣ Did you have caffeine after 16:00?"))
        case .screen:
            messages.append(ChatMessage(isUser: false,
                                        text: "6️⃣ Were you on screens in the last hour before bed?"))
        case .done:
            submitDailyUpdate()
        }
    }

    @ViewBuilder
    private func stepControls(for step: CheckInStep) -> some View {
        VStack(spacing: 12) {
            if isSubmitting {
                ProgressView("Updating your longevity score…")
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    .foregroundColor(.white)
            } else {
                switch step {
                case .sleep:
                    HStack {
                        stepButton("≤ 5h", { answerSleep(5.0) })
                        stepButton("6–7h", { answerSleep(6.5) })
                        stepButton("7–8h", { answerSleep(7.5) })
                        stepButton("≥ 8h", { answerSleep(8.5) })
                    }
                case .steps:
                    VStack {
                        stepButton("0–3K", { answerSteps(2000) })
                        stepButton("3–7K", { answerSteps(5000) })
                        stepButton("7–10K", { answerSteps(8500) })
                        stepButton("10K+", { answerSteps(11000) })
                    }
                case .vigorous:
                    HStack {
                        stepButton("0 min", { answerVigorous(0) })
                        stepButton("10–20", { answerVigorous(15) })
                        stepButton("20–40", { answerVigorous(30) })
                        stepButton("40+", { answerVigorous(45) })
                    }
                case .stress:
                    HStack {
                        stepButton("Low", { answerStress(3) })
                        stepButton("Medium", { answerStress(5) })
                        stepButton("High", { answerStress(8) })
                    }
                case .caffeine:
                    HStack {
                        stepButton("No", { answerCaffeine(false) })
                        stepButton("Yes", { answerCaffeine(true) })
                    }
                case .screen:
                    HStack {
                        stepButton("No", { answerScreen(false) })
                        stepButton("Yes", { answerScreen(true) })
                    }
                case .done:
                    EmptyView()
                }
            }
        }
    }

    private func stepButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6).opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Step answers

    private func answerSleep(_ hours: Double) {
        checkInData.sleepHours = hours
        messages.append(ChatMessage(isUser: true,
                                    text: String(format: "%.1f hours", hours)))
        askNextStep(.steps)
    }

    private func answerSteps(_ steps: Int) {
        checkInData.steps = steps
        messages.append(ChatMessage(isUser: true,
                                    text: "\(steps) steps (approx)"))
        askNextStep(.vigorous)
    }

    private func answerVigorous(_ minutes: Int) {
        checkInData.vigorousMinutes = minutes
        messages.append(ChatMessage(isUser: true,
                                    text: "\(minutes) minutes"))
        askNextStep(.stress)
    }

    private func answerStress(_ level: Int) {
        checkInData.stressLevel = level
        messages.append(ChatMessage(isUser: true,
                                    text: "Stress level \(level)/10"))
        askNextStep(.caffeine)
    }

    private func answerCaffeine(_ hadLateCaffeine: Bool) {
        checkInData.lateCaffeine = hadLateCaffeine
        messages.append(ChatMessage(isUser: true,
                                    text: hadLateCaffeine ? "Yes, late caffeine" : "No late caffeine"))
        askNextStep(.screen)
    }

    private func answerScreen(_ usedScreen: Bool) {
        checkInData.lateScreenUsage = usedScreen
        messages.append(ChatMessage(isUser: true,
                                    text: usedScreen ? "On screens before bed" : "No screens before bed"))
        currentStep = .done
        submitDailyUpdate()
    }

    // MARK: - Submit to backend

    private func submitDailyUpdate() {
        isSubmitting = true
        errorMessage = nil

        let request = DailyUpdateRequest(
            userId: "gizem-demo",
            sleepHours: checkInData.sleepHours,
            steps: checkInData.steps,
            vigorousMinutes: checkInData.vigorousMinutes,
            stressLevel: checkInData.stressLevel,
            lateCaffeine: checkInData.lateCaffeine,
            lateScreenUsage: checkInData.lateScreenUsage
        )

        LongevityAPI.shared.submitDailyUpdate(request) { result in
            DispatchQueue.main.async {
                self.isSubmitting = false
                self.isInCheckIn = false

                switch result {
                case .success(let state):
                    let delta = state.agingDebtYears
                    var summary = "Check-in saved. "
                    if delta <= 0 {
                        summary += "You're not accumulating aging debt today. Great job staying on track. 🎉"
                    } else {
                        summary += String(format: "You have %.2f years of aging debt. Tiny course corrections over the next days can reverse this.", delta)
                    }

                    self.messages.append(ChatMessage(isUser: false, text: summary))
                    self.refreshAgeState()   // reload header + hasCompletedToday
                case .failure(let error):
                    self.errorMessage = "Could not update today's check-in."
                    print("Daily update error:", error)
                }
            }
        }
    }
}

struct ScoreView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var ageState: BiologicalAgeState?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Longevity Score Insights")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        if let state = ageState {
                            Text("AI is tracking your biological aging based on your daily inputs.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("We'll show your biological age and streak once data is loaded.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 16)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else if let state = ageState {
                        // Main score / age section
                        VStack(spacing: 24) {
                            // Big biological age display
                            Text(String(format: "%.1f", state.currentBiologicalAgeYears))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(.green)

                            Text("Biological Age (years)")
                                .foregroundColor(.gray)

                            HStack(spacing: 32) {
                                VStack {
                                    Text(String(format: "%.1f", state.chronologicalAgeYears))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Chronological")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                VStack {
                                    Text(String(format: "%.1f", state.baselineBiologicalAgeYears))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Baseline Bio Age")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Streak & aging debt
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Rejuvenation streak")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(state.rejuvenationStreakDays) day\(state.rejuvenationStreakDays == 1 ? "" : "s")")
                                        .foregroundColor(.white)
                                }

                                HStack {
                                    Text("Aging debt")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(String(format: "%.2f years", state.agingDebtYears))
                                        .foregroundColor(state.agingDebtYears > 0 ? .red : .green)
                                }

                                HStack {
                                    Text("Total rejuvenation days")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(state.totalRejuvenationDays)")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.15))
                            .cornerRadius(16)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Score", displayMode: .inline)
        }
        .onAppear {
            fetchAgeState()
        }
    }

    private func fetchAgeState() {
        isLoading = true
        errorMessage = nil

        LongevityAPI.shared.fetchAgeState(userId: "gizem-demo") { result in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.ageState = response.state
                }
            case .failure(let error):
                print("Age state error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct DiscoverView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Discover")
                    .font(.title.bold())

                Text("Here we will list longevity topics, articles, and curated content.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Discover")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Profile & Settings")
                    .font(.title.bold())

                Text("Here we will configure coach tone, response style and integrations.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

