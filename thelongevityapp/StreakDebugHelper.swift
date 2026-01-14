//
//  StreakDebugHelper.swift
//  thelongevityapp
//
//  Debug utilities for streak and dayKey verification
//

import Foundation
import SwiftUI

struct StreakDebugHelper {
    // Compute local dayKey using Calendar in TimeZone.current
    static func getLocalDayKey(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return "INVALID"
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
    
    // Get yesterday's dayKey
    static func getYesterdayDayKey() -> String {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return "INVALID"
        }
        return getLocalDayKey(date: yesterday)
    }
    
    // Get timezone identifier
    static func getCurrentTimezone() -> String {
        return TimeZone.current.identifier
    }
    
    // Format date for display
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - Debug Overlay View
struct StreakDebugOverlay: View {
    @AppStorage("showStreakDebug") private var showDebug: Bool = false
    
    let lastCheckinAt: Date?
    let lastCheckinDayKey: String?
    let currentStreak: Int
    
    var body: some View {
        if showDebug {
            VStack(alignment: .leading, spacing: 8) {
                Text("🔍 Streak Debug")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    debugRow("Current DayKey", StreakDebugHelper.getLocalDayKey())
                    debugRow("Yesterday DayKey", StreakDebugHelper.getYesterdayDayKey())
                    debugRow("Timezone", StreakDebugHelper.getCurrentTimezone())
                    debugRow("Current Streak", "\(currentStreak)")
                    
                    if let lastCheckinAt = lastCheckinAt {
                        debugRow("Last Check-in At", StreakDebugHelper.formatDate(lastCheckinAt))
                    } else {
                        debugRow("Last Check-in At", "Never")
                    }
                    
                    if let lastCheckinDayKey = lastCheckinDayKey {
                        debugRow("Last Check-in DayKey", lastCheckinDayKey)
                    } else {
                        debugRow("Last Check-in DayKey", "None")
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .font(.system(size: 11, weight: .regular, design: .monospaced))
        }
    }
    
    @ViewBuilder
    private func debugRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Debug Toggle (for Settings)
struct StreakDebugToggle: View {
    @AppStorage("showStreakDebug") private var showDebug: Bool = false
    
    var body: some View {
        Toggle("Show Streak Debug Overlay", isOn: $showDebug)
            .tint(Color.primaryGreen)
    }
}

