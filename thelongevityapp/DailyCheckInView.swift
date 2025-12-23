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
    @State private var todayScore: Int?
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
                       let debt = agingDebt,
                       let streak = rejuvenationStreak {

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Result")
                                .font(.title3.bold())

                            Text(String(format: "Biological Age: %.2f years", bioAge))
                                .font(.headline)

                            Text(String(format: "Aging Debt: %.2f years", debt))
                                .foregroundColor(debt > 0 ? .red : .green)

                            Text("Rejuvenation Streak: \(streak) day\(streak == 1 ? "" : "s")")
                                .foregroundColor(streak > 0 ? .green : .secondary)
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

        // Get today's date in ISO format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let request = DailyUpdateRequest(
            metrics: .init(
                date: today,
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
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                } else {
                    // Success - refresh all insights data
                    Task {
                        await ageStore.loadSummary()
                        await scoreViewModel.fetchSummary()
                    }
                    
                    // Update local state for display
                    self.currentBiologicalAge = ageStore.currentBiologicalAgeYears
                    self.agingDebt = ageStore.agingDebtYears
                    self.rejuvenationStreak = ageStore.rejuvenationStreakDays
                    self.hasResult = true
                    
                    // Push latest state into shared ScoreViewModel so Score tab updates immediately.
                    if let state = ageStore.state {
                        scoreViewModel.chronologicalAgeYears = state.chronologicalAgeYears // chronological age is fixed from backend
                        scoreViewModel.biologicalAgeYears = state.currentBiologicalAgeYears
                        scoreViewModel.agingDebtYears = state.agingDebtYears
                        scoreViewModel.rejuvenationStreakDays = state.rejuvenationStreakDays
                        scoreViewModel.accelerationStreakDays = state.accelerationStreakDays
                        scoreViewModel.totalRejuvenationDays = state.totalRejuvenationDays
                        scoreViewModel.totalAccelerationDays = state.totalAccelerationDays
                    }
                    
                    // Generate message based on current data
                    var message = "Check-in saved. "
                    
                    if let chrono = ageStore.profileChronologicalAgeYears,
                       let bio = ageStore.currentBiologicalAgeYears {
                        let diff = bio - chrono
                        
                        if diff < 0 {
                            message += String(format: "Rejuvenation: %.2f years. ", diff)
                            message += "Bugün gençleşme yönündesin"
                            if ageStore.rejuvenationStreakDays > 0 {
                                message += " (+ \(ageStore.rejuvenationStreakDays) day streak)"
                            }
                            message += ". "
                        } else if diff == 0 {
                            message += "Today: 0.00 years. Bugün stabil, biyolojik yaşın korunuyor. "
                        } else {
                            message += String(format: "Aging debt: +%.2f years. ", diff)
                            message += "Bugün hızlanma var, yarın 1–2 öneri ile düzeltebilirsin. "
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

