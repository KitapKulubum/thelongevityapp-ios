//
//  DailyCheckInView.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI

struct DailyCheckInView: View {
    @EnvironmentObject private var ageStore: AgeStore
    @EnvironmentObject private var scoreViewModel: ScoreViewModel
    @State private var sleepHours: Double = 7.0
    @State private var stepsText: String = ""
    @State private var vigorousMinutesText: String = ""
    @State private var stressLevel: Double = 5.0
    @State private var lateCaffeine: Bool = false
    @State private var lateScreenUsage: Bool = false
    @State private var bedtimeHour: Double = 22.0
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasResult = false
    @State private var currentBiologicalAge: Double?
    @State private var agingDebt: Double?
    @State private var rejuvenationStreak: Int?
    @State private var todayScore: Double?
    @State private var todayDeltaYears: Double?

    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Text("Today's Longevity Check-In")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        VStack(spacing: 24) {
                            // Sleep Hours
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sleep Hours")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text("4.0")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: $sleepHours, in: 4.0...10.0, step: 0.5)
                                        .tint(Color(red: 0.2, green: 0.5, blue: 0.35))
                                    
                                    Text("10.0")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(sleepHours, specifier: "%.1f") hours")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.96))
                            )
                            
                            // Steps
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Steps")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                TextField("Enter steps", text: $stepsText)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(white: 0.85), lineWidth: 1)
                                            )
                                    )
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.96))
                            )
                            
                            // Vigorous Minutes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vigorous Minutes")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                TextField("Enter minutes", text: $vigorousMinutesText)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(white: 0.85), lineWidth: 1)
                                            )
                                    )
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.96))
                            )
                            
                            // Stress Level
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Stress Level")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text("1")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: $stressLevel, in: 1...10, step: 1)
                                        .tint(Color(red: 0.2, green: 0.5, blue: 0.35))
                                    
                                    Text("10")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(Int(stressLevel))")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.96))
                            )
                            
                            // Late Caffeine
                            HStack {
                                Text("Late Caffeine")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $lateCaffeine)
                                    .tint(Color(red: 0.2, green: 0.5, blue: 0.35))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.96))
                            )
                            
                            // Late Screen Usage
                            HStack {
                                Text("Late Screen Usage")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $lateScreenUsage)
                                    .tint(Color(red: 0.2, green: 0.5, blue: 0.35))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.96))
                            )
                            
                            // Bedtime Hour
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bedtime Hour")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text("20:00")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: $bedtimeHour, in: 20.0...24.0, step: 0.5)
                                        .tint(Color(red: 0.2, green: 0.5, blue: 0.35))
                                    
                                    Text("24:00")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(formatHour(bedtimeHour))")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.96))
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // kart
                        
                        
                        // Save Button
                        Button(action: {
                            submit()
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save & See My Biological Age")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.5, blue: 0.35),
                                        Color(red: 0.15, green: 0.4, blue: 0.3)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.35).opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    if hasResult,
                       let bioAge = currentBiologicalAge,
                       let debt = agingDebt {

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Result")
                                .font(.title3.bold())

                            Text(String(format: "Biological Age: %.2f years", bioAge))
                                .font(.headline)

                            Text(String(format: "Aging Debt: %.2f years", debt))
                                .foregroundColor({
                                    // Apply same color logic as MainTabView
                                    // debt is already the difference (biologicalAge - chronologicalAge)
                                    if debt < -0.5 {
                                        return .primaryGreen // Positive rejuvenation
                                    } else if abs(debt) <= 0.5 {
                                        return Color(white: 0.6) // Neutral gray
                                    } else {
                                        return .orange // Amber/orange (attention, not red)
                                    }
                                }())

                            // Rejuvenation Streak (from backend - date-based, consecutive)
                            if let streak = rejuvenationStreak, streak > 0 {
                                HStack(spacing: 8) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text("\(streak) day\(streak == 1 ? "" : "s") rejuvenation streak")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.primaryGreen.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.top, 16)
                    }

                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Longevity Check-In"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func formatHour(_ hour: Double) -> String {
        let intHour = Int(hour)
        let minutes = Int((hour - Double(intHour)) * 60)
        return String(format: "%02d:%02d", intHour, minutes)
    }
    
    private func submit() {
        // simple validation for numeric fields
        guard let steps = Int(stepsText), let vigorous = Int(vigorousMinutesText) else {
            alertMessage = "Please enter valid numbers for steps and vigorous minutes."
            showAlert = true
            return
        }

        isSaving = true

        // Note: date field removed - backend computes it based on user's timezone
        // Backend uses user's timezone (sent via profile) to determine the correct day boundary
        let request = DailyUpdateRequest(
            metrics: .init(
                date: "", // Empty string - backend will compute based on timezone
                sleepHours: sleepHours,
                steps: steps,
                vigorousMinutes: vigorous,
                processedFoodScore: 3, // Default moderate processed food score
                alcoholUnits: 0, // Default no alcohol
                stressLevel: Int(stressLevel),
                lateCaffeine: lateCaffeine,
                screenLate: lateScreenUsage,
                bedtimeHour: bedtimeHour
            )
        )

        Task {
            await ageStore.submitDailyUpdate(request)
            
            await MainActor.run {
                self.isSaving = false
                
                if let error = ageStore.lastError {
                    // Handle 409 Conflict (same day check-in attempt)
                    // Backend returns 409 when user tries to check-in on the same day twice
                    if let nsError = error as NSError?,
                       nsError.code == 409 {
                        self.alertMessage = "You have already completed today's check-in. Please try again tomorrow."
                        self.showAlert = true
                    } else {
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                    }
                } else {
                    // Success - update ScoreViewModel immediately with latest state from AgeStore
                    // AgeStore has already been updated by submitDailyUpdate() with backend response
                    // This ensures streak is displayed correctly right away
                    if let state = ageStore.state {
                        scoreViewModel.chronologicalAgeYears = state.chronologicalAgeYears
                        scoreViewModel.biologicalAgeYears = state.currentBiologicalAgeYears ?? state.chronologicalAgeYears
                        scoreViewModel.agingDebtYears = state.agingDebtYears
                        scoreViewModel.rejuvenationStreakDays = state.rejuvenationStreakDays
                        scoreViewModel.totalRejuvenationDays = state.totalRejuvenationDays
                    }
                    
                    // Update local state for display
                    // Note: All streak values come from backend - date-based and consecutive
                    // Frontend does NOT calculate streaks, only displays them
                    self.currentBiologicalAge = ageStore.currentBiologicalAgeYears
                    self.agingDebt = ageStore.agingDebtYears
                    self.rejuvenationStreak = ageStore.rejuvenationStreakDays
                    self.hasResult = true
                    
                    // Refresh summary to ensure all data is in sync (but streak is already updated above)
                    Task {
                        await ageStore.loadSummary()
                        await scoreViewModel.fetchSummary()
                    }
                    
                    // Generate message based on current data
                    var message = "Check-in saved. "
                    
                    // Use todayDeltaYears from summary if available, otherwise calculate from ages
                    if let todayDelta = scoreViewModel.todayDeltaYears {
                        let absDelta = abs(todayDelta)
                        if todayDelta < 0 {
                            message += String(format: "Rejuvenation: %.2f years. ", absDelta)
                            message += "You're trending younger today. "
                        } else if todayDelta > 0 {
                            message += String(format: "Aging debt: %.2f years. ", absDelta)
                            message += "You're accelerating today. You can improve this tomorrow with 1–2 adjustments. "
                        } else {
                            message += "Today: 0.00 years. You're stable today, your biological age is maintained. "
                        }
                    } else if let chrono = ageStore.profileChronologicalAgeYears,
                       let bio = ageStore.currentBiologicalAgeYears {
                        let diff = bio - chrono
                        let absDiff = abs(diff)
                        
                        if diff < 0 {
                            message += String(format: "Rejuvenation: %.2f years. ", absDiff)
                            message += "You're trending younger today. "
                        } else if diff == 0 {
                            message += "Today: 0.00 years. You're stable today, your biological age is maintained. "
                        } else {
                            message += String(format: "Aging debt: %.2f years. ", absDiff)
                            message += "You're accelerating today. You can improve this tomorrow with 1–2 adjustments. "
                        }
                    } else {
                        message += "Your biological age is updated."
                    }
                    
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
}

#Preview {
    DailyCheckInView()
        .environmentObject(AgeStore())
        .environmentObject(ScoreViewModel())
}

