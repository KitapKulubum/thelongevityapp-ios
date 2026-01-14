//
//  NotificationManager.swift
//  thelongevityapp
//
//  Local notifications manager for gentle reminders
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // Notification preferences
    @AppStorage("isDailyReminderEnabled") var isDailyReminderEnabled: Bool = false
    @AppStorage("dailyReminderTime") var dailyReminderTime: String = "21:00"
    @AppStorage("isWeeklyReflectionEnabled") var isWeeklyReflectionEnabled: Bool = false
    @AppStorage("weeklyReflectionDay") var weeklyReflectionDay: Int = 1 // Sunday = 1
    @AppStorage("weeklyReflectionTime") var weeklyReflectionTime: String = "18:00"
    @AppStorage("isEndOfDayNudgeEnabled") var isEndOfDayNudgeEnabled: Bool = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Management
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("[NotificationManager] Failed to request authorization: \(error)")
            return false
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleAllNotifications() {
        // Remove all existing notifications first
        notificationCenter.removeAllPendingNotificationRequests()
        
        guard authorizationStatus == .authorized else {
            print("[NotificationManager] Not authorized, skipping notification scheduling")
            return
        }
        
        if isDailyReminderEnabled {
            scheduleDailyReminder()
        }
        
        if isWeeklyReflectionEnabled {
            scheduleWeeklyReflection()
        }
        
        if isEndOfDayNudgeEnabled {
            scheduleEndOfDayNudge()
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "How was your day? A quick check-in can make a difference."
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"
        
        // Parse time (format: "HH:mm")
        let timeComponents = dailyReminderTime.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            print("[NotificationManager] Invalid daily reminder time format")
            return
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_checkin_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("[NotificationManager] Failed to schedule daily reminder: \(error)")
            } else {
                print("[NotificationManager] Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    private func scheduleWeeklyReflection() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Reflection"
        content.body = "Your week in longevity is ready."
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REFLECTION"
        
        // Parse time (format: "HH:mm")
        let timeComponents = weeklyReflectionTime.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            print("[NotificationManager] Invalid weekly reflection time format")
            return
        }
        
        // weeklyReflectionDay: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        var dateComponents = DateComponents()
        dateComponents.weekday = weeklyReflectionDay
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_reflection",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                print("[NotificationManager] Failed to schedule weekly reflection: \(error)")
            } else {
                guard let self = self else { return }
                let weekdayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                print("[NotificationManager] Weekly reflection scheduled for \(weekdayNames[self.weeklyReflectionDay]) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    private func scheduleEndOfDayNudge() {
        // Schedule for 22:00 (10 PM) - end of day
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "Still time for today's check-in."
        content.sound = .default
        content.categoryIdentifier = "END_OF_DAY_NUDGE"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "end_of_day_nudge",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("[NotificationManager] Failed to schedule end-of-day nudge: \(error)")
            } else {
                print("[NotificationManager] End-of-day nudge scheduled for 22:00")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - Weekday Helper
extension NotificationManager {
    static let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    static func weekdayName(for index: Int) -> String {
        guard index >= 1 && index <= 7 else { return "Sunday" }
        return weekdayNames[index - 1]
    }
    
    static func weekdayIndex(for name: String) -> Int {
        return weekdayNames.firstIndex(of: name) ?? 0 + 1
    }
}

