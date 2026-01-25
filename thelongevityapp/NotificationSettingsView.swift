//
//  NotificationSettingsView.swift
//  thelongevityapp
//
//  Notification settings screen with toggles and time/day pickers
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    
    @State private var showPermissionExplainer: Bool = false
    @State private var showPermissionDeniedAlert: Bool = false
    @State private var pendingToggle: NotificationToggleType? = nil
    
    enum NotificationToggleType {
        case daily
        case weekly
        case endOfDay
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.16, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Daily Check-in Reminder
                        notificationCard(
                            title: "Daily check-in reminder",
                            helper: "A gentle daily reminder to stay consistent.",
                            isEnabled: notificationManager.isDailyReminderEnabled,
                            onToggle: { newValue in
                                handleToggle(type: .daily, newValue: newValue)
                            }
                        ) {
                            if notificationManager.isDailyReminderEnabled {
                                timePickerSection(
                                    title: "Time",
                                    time: $notificationManager.dailyReminderTime
                                )
                            }
                        }
                        
                        // Weekly Reflection
                        notificationCard(
                            title: "Weekly reflection",
                            helper: "A weekly summary to keep you on track.",
                            isEnabled: notificationManager.isWeeklyReflectionEnabled,
                            onToggle: { newValue in
                                handleToggle(type: .weekly, newValue: newValue)
                            }
                        ) {
                            if notificationManager.isWeeklyReflectionEnabled {
                                VStack(spacing: 16) {
                                    dayPickerSection(
                                        title: "Day",
                                        day: $notificationManager.weeklyReflectionDay
                                    )
                                    
                                    timePickerSection(
                                        title: "Time",
                                        time: $notificationManager.weeklyReflectionTime
                                    )
                                }
                            }
                        }
                        
                        // End-of-day Nudge (Optional)
                        notificationCard(
                            title: "End-of-day nudge",
                            helper: "Only if you haven't checked in today.",
                            isEnabled: notificationManager.isEndOfDayNudgeEnabled,
                            onToggle: { newValue in
                                handleToggle(type: .endOfDay, newValue: newValue)
                            }
                        )
                        
                        // Permission Status
                        if notificationManager.authorizationStatus == .denied {
                            permissionDeniedCard
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryGreen)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                notificationManager.checkAuthorizationStatus()
            }
            .sheet(isPresented: $showPermissionExplainer) {
                PermissionExplainerView(
                    onAllow: {
                        requestPermission()
                    },
                    onNotNow: {
                        // Revert toggle
                        revertToggle()
                    }
                )
            }
            .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
                Button(languageManager.localized("Open Settings")) {
                    notificationManager.openSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(languageManager.localized("Notifications are off for The Longevity App. You can enable them in Settings."))
            }
        }
    }
    
    // MARK: - Notification Card
    @ViewBuilder
    private func notificationCard(
        title: String,
        helper: String,
        isEnabled: Bool,
        onToggle: @escaping (Bool) -> Void,
        @ViewBuilder content: @escaping () -> some View = { EmptyView() }
    ) -> some View {
        MinimalCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(helper)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { isEnabled },
                        set: onToggle
                    ))
                    .tint(Color.primaryGreen)
                }
                
                if isEnabled {
                    content()
                        .padding(.top, 8)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Time Picker Section
    @ViewBuilder
    private func timePickerSection(title: String, time: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            TimePickerView(time: time)
        }
    }
    
    // MARK: - Day Picker Section
    @ViewBuilder
    private func dayPickerSection(title: String, day: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Picker(title, selection: day) {
                ForEach(1...7, id: \.self) { index in
                    Text(NotificationManager.weekdayName(for: index))
                        .tag(index)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.primaryGreen)
            .onChange(of: day.wrappedValue) { _, _ in
                onTimeChange()
            }
        }
    }
    
    // MARK: - Permission Denied Card
    private var permissionDeniedCard: some View {
        MinimalCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(languageManager.localized("Notifications are off"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(languageManager.localized("Enable notifications in Settings to receive reminders."))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                }
                
                Button {
                    notificationManager.openSettings()
                } label: {
                    Text(languageManager.localized("Open Settings"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.primaryGreen)
                        )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Toggle Handling
    private func handleToggle(type: NotificationToggleType, newValue: Bool) {
        // Check if permission is already granted
        if notificationManager.authorizationStatus == .authorized {
            // Permission granted, update toggle directly
            updateToggle(type: type, newValue: newValue)
            scheduleNotifications()
        } else if notificationManager.authorizationStatus == .denied {
            // Permission denied, show alert
            showPermissionDeniedAlert = true
            // Revert toggle
            revertToggle()
        } else {
            // Permission not determined, show explainer first
            pendingToggle = type
            showPermissionExplainer = true
        }
    }
    
    private func updateToggle(type: NotificationToggleType, newValue: Bool) {
        switch type {
        case .daily:
            notificationManager.isDailyReminderEnabled = newValue
        case .weekly:
            notificationManager.isWeeklyReflectionEnabled = newValue
        case .endOfDay:
            notificationManager.isEndOfDayNudgeEnabled = newValue
        }
    }
    
    private func revertToggle() {
        guard let type = pendingToggle else { return }
        updateToggle(type: type, newValue: false)
        pendingToggle = nil
    }
    
    private func requestPermission() {
        Task {
            let granted = await notificationManager.requestAuthorization()
            await MainActor.run {
                notificationManager.checkAuthorizationStatus()
                
                if granted {
                    // Permission granted, apply pending toggle
                    if let type = pendingToggle {
                        updateToggle(type: type, newValue: true)
                        scheduleNotifications()
                    }
                } else {
                    // Permission denied, revert toggle
                    revertToggle()
                }
                
                pendingToggle = nil
            }
        }
    }
    
    private func scheduleNotifications() {
        // Schedule notifications when preferences change
        notificationManager.scheduleAllNotifications()
    }
    
    // Schedule notifications when time/day changes
    private func onTimeChange() {
        scheduleNotifications()
    }
}

// MARK: - Permission Explainer View
struct PermissionExplainerView: View {
    let onAllow: () -> Void
    let onNotNow: () -> Void
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 48))
                    .foregroundColor(Color.primaryGreen)
                
                VStack(spacing: 12) {
                    Text(languageManager.localized("Turn on reminders?"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(languageManager.localized("We'll send gentle reminders to help you keep your rhythm."))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 12) {
                    Button {
                        onAllow()
                    } label: {
                        Text(languageManager.localized("Allow reminders"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.primaryGreen)
                            )
                    }
                    
                    Button {
                        onNotNow()
                    } label: {
                        Text(languageManager.localized("Not now"))
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(32)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Time Picker View
struct TimePickerView: View {
    @Binding var time: String
    
    @State private var selectedHour: Int = 21
    @State private var selectedMinute: Int = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Hour picker
            Picker("Hour", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d", hour))
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            .onChange(of: selectedHour) { _, _ in
                updateTimeString()
            }
            
            Text(":")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            // Minute picker
            Picker("Minute", selection: $selectedMinute) {
                ForEach([0, 15, 30, 45], id: \.self) { minute in
                    Text(String(format: "%02d", minute))
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            .onChange(of: selectedMinute) { _, _ in
                updateTimeString()
            }
        }
        .frame(height: 120)
        .onAppear {
            parseTimeString()
        }
    }
    
    private func parseTimeString() {
        let components = time.split(separator: ":")
        if components.count == 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            selectedHour = hour
            selectedMinute = minute
        }
    }
    
    private func updateTimeString() {
        time = String(format: "%02d:%02d", selectedHour, selectedMinute)
        // Trigger notification rescheduling when time changes
        NotificationManager.shared.scheduleAllNotifications()
    }
}

