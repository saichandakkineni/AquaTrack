import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @State private var showingHealthKitAuth = false
    @State private var dailyGoal: Double = 2000
    @State private var reminderEnabled: Bool = false
    @State private var reminderInterval: Int = 60
    @State private var selectedUnit: WaterUnit = .milliliters
    @State private var quietHoursEnabled: Bool = true
    @State private var quietHoursStart: Int = 22 // 10 PM
    @State private var quietHoursEnd: Int = 7    // 7 AM
    
    private var currentSettings: Settings {
        if let first = settings.first {
            return first
        }
        let newSettings = Settings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goal") {
                    Stepper {
                        Text("\(formatDailyGoal()) per day")
                    } onIncrement: {
                        // dailyGoal is always stored in ml, so just add 100ml
                        dailyGoal += 100
                        updateDailyGoal()
                    } onDecrement: {
                        // dailyGoal is always stored in ml, so just subtract 100ml
                        // Minimum goal is 100ml
                        if dailyGoal > 100 {
                            dailyGoal -= 100
                            updateDailyGoal()
                        }
                    }
                }
                
                Section("Units") {
                    Picker("Display Unit", selection: $selectedUnit) {
                        ForEach(WaterUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .onChange(of: selectedUnit) { _, newValue in
                        currentSettings.unit = newValue
                        try? modelContext.save()
                    }
                    
                    Text("All values will be displayed in \(selectedUnit.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Reminders") {
                    Toggle("Enable Reminders", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                updateReminderSettings(enabled: false)
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                    
                    if reminderEnabled {
                        Picker("Reminder Interval", selection: $reminderInterval) {
                            Text("30 minutes").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                            Text("4 hours").tag(240)
                        }
                        .onChange(of: reminderInterval) { _, newValue in
                            currentSettings.reminderInterval = newValue
                            try? modelContext.save()
                            scheduleNotifications()
                        }
                        
                        Toggle("Quiet Hours", isOn: $quietHoursEnabled)
                            .onChange(of: quietHoursEnabled) { _, newValue in
                                currentSettings.quietHoursEnabled = newValue
                                try? modelContext.save()
                                scheduleNotifications()
                            }
                        
                        if quietHoursEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Start")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Picker("", selection: $quietHoursStart) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(formatHour(hour)).tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .onChange(of: quietHoursStart) { _, newValue in
                                        currentSettings.quietHoursStart = newValue
                                        try? modelContext.save()
                                        scheduleNotifications()
                                    }
                                }
                                
                                HStack {
                                    Text("End")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Picker("", selection: $quietHoursEnd) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(formatHour(hour)).tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .onChange(of: quietHoursEnd) { _, newValue in
                                        currentSettings.quietHoursEnd = newValue
                                        try? modelContext.save()
                                        scheduleNotifications()
                                    }
                                }
                                
                                Text("No notifications will be sent during quiet hours")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Health Integration") {
                    Button("Connect to Health App") {
                        showingHealthKitAuth = true
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingHealthKitAuth) {
                HealthKitAuthView()
            }
            .onAppear {
                // Initialize all state from current settings
                dailyGoal = currentSettings.dailyGoal
                reminderEnabled = currentSettings.reminderEnabled
                reminderInterval = currentSettings.reminderInterval
                selectedUnit = currentSettings.unit
                quietHoursEnabled = currentSettings.quietHoursEnabled
                quietHoursStart = currentSettings.quietHoursStart
                quietHoursEnd = currentSettings.quietHoursEnd
            }
        }
    }
    
    private func scheduleNotifications() {
        NotificationManager.shared.scheduleNotifications(
            interval: reminderInterval,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd
        )
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date).lowercased()
    }
    
    private func updateReminderSettings(enabled: Bool) {
        currentSettings.reminderEnabled = enabled
        reminderEnabled = enabled
        try? modelContext.save()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    updateReminderSettings(enabled: true)
                    // Schedule with current quiet hours settings
                    NotificationManager.shared.scheduleNotifications(
                        interval: reminderInterval,
                        quietHoursEnabled: quietHoursEnabled,
                        quietHoursStart: quietHoursStart,
                        quietHoursEnd: quietHoursEnd
                    )
                } else {
                    updateReminderSettings(enabled: false)
                }
            }
        }
    }
    
    private func updateDailyGoal() {
        currentSettings.dailyGoal = dailyGoal
        try? modelContext.save()
        Task {
            await WaterIntake.updateSharedDefaults(context: modelContext)
        }
    }
    
    private func formatDailyGoal() -> String {
        let goalInSelectedUnit = WaterUnit.convert(dailyGoal, from: .milliliters, to: selectedUnit)
        return "\(selectedUnit.format(goalInSelectedUnit)) \(selectedUnit.displayName)"
    }
} 