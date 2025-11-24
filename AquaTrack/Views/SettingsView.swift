import SwiftUI
import SwiftData
import UserNotifications
import UIKit

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
    @State private var showingPermissionDeniedAlert = false
    @State private var healthKitAuthorized: Bool = false
    @State private var checkingHealthKitStatus: Bool = false
    
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
                                checkAndRequestNotificationPermission()
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
                
                Section("About") {
                    Button(action: {
                        // Reset onboarding for testing
                        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                        // Post notification to trigger onboarding
                        NotificationCenter.default.post(name: .showOnboarding, object: nil)
                    }) {
                        HStack {
                            Text("Show Welcome Screen Again")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section("Health Integration") {
                    if checkingHealthKitStatus {
                        HStack {
                            Text("Checking connection status...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    } else if healthKitAuthorized {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Health App")
                                    .font(.body)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            Button("Manage") {
                                showingHealthKitAuth = true
                            }
                        }
                    } else {
                        Button("Connect to Health App") {
                            showingHealthKitAuth = true
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingHealthKitAuth) {
                HealthKitAuthView()
            }
            .onChange(of: showingHealthKitAuth) { _, isShowing in
                // When sheet is dismissed, refresh HealthKit status
                if !isShowing {
                    checkHealthKitStatus()
                }
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionDeniedAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) {
                    reminderEnabled = false
                }
            } message: {
                Text("Please enable notifications in Settings to receive water intake reminders.")
            }
            .onAppear {
                // Initialize all state from current settings
                dailyGoal = currentSettings.dailyGoal
                reminderInterval = currentSettings.reminderInterval
                selectedUnit = currentSettings.unit
                quietHoursEnabled = currentSettings.quietHoursEnabled
                quietHoursStart = currentSettings.quietHoursStart
                quietHoursEnd = currentSettings.quietHoursEnd
                
                // Check notification permission status and sync with toggle
                checkNotificationPermissionStatus()
                
                // Check HealthKit authorization status
                checkHealthKitStatus()
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
    
    private func checkNotificationPermissionStatus() {
        // Check current permission status and sync toggle state
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                // Only update if there's a mismatch - don't override user's current toggle if they just turned it off
                if self.currentSettings.reminderEnabled != isAuthorized {
                    self.reminderEnabled = isAuthorized
                    self.currentSettings.reminderEnabled = isAuthorized
                    try? self.modelContext.save()
                    
                    if isAuthorized {
                        // Permission is granted, schedule notifications
                        self.scheduleNotifications()
                    }
                } else {
                    // Sync the state variable
                    self.reminderEnabled = self.currentSettings.reminderEnabled
                }
            }
        }
    }
    
    private func checkAndRequestNotificationPermission() {
        // Always try to request permission first - iOS will show the dialog if permission hasn't been determined
        // If permission was previously denied, iOS won't show the dialog, so we'll check status after
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // Permission granted, enable reminders
                    self.updateReminderSettings(enabled: true)
                    NotificationManager.shared.scheduleNotifications(
                        interval: self.reminderInterval,
                        quietHoursEnabled: self.quietHoursEnabled,
                        quietHoursStart: self.quietHoursStart,
                        quietHoursEnd: self.quietHoursEnd
                    )
                } else {
                    // Permission not granted - check if it's because it was previously denied
                    // If so, we need to direct user to Settings
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        DispatchQueue.main.async {
                            if settings.authorizationStatus == .denied {
                                // Permission was previously denied, need to go to Settings
                                self.reminderEnabled = false
                                self.showingPermissionDeniedAlert = true
                            } else {
                                // User just denied it now, or some other error
                                self.reminderEnabled = false
                            }
                        }
                    }
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
    
    private func checkHealthKitStatus() {
        checkingHealthKitStatus = true
        HealthKitManager.shared.getAuthorizationStatus { isAuthorized in
            DispatchQueue.main.async {
                self.healthKitAuthorized = isAuthorized
                self.checkingHealthKitStatus = false
            }
        }
    }
} 