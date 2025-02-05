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
                        Text("\(Int(dailyGoal))ml per day")
                    } onIncrement: {
                        dailyGoal += 100
                        updateDailyGoal()
                    } onDecrement: {
                        if dailyGoal > 100 {
                            dailyGoal -= 100
                            updateDailyGoal()
                        }
                    }
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
            }
        }
    }
    
    private func scheduleNotifications() {
        NotificationManager.shared.scheduleNotifications(interval: reminderInterval)
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
                    scheduleNotifications()
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
            await WaterIntake.updateSharedDefaults()
        }
    }
} 