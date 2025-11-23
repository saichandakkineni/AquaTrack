import Foundation
import SwiftData

@Model
class Settings {
    var dailyGoal: Double // in milliliters (always stored in ml)
    var reminderEnabled: Bool
    var reminderInterval: Int // in minutes
    var preferredUnit: String // WaterUnit raw value
    var quietHoursEnabled: Bool
    var quietHoursStart: Int // Hour (0-23) when quiet hours start (e.g., 22 for 10 PM)
    var quietHoursEnd: Int // Hour (0-23) when quiet hours end (e.g., 7 for 7 AM)
    
    init(
        dailyGoal: Double = 2000,
        reminderEnabled: Bool = false,
        reminderInterval: Int = 60,
        preferredUnit: String = WaterUnit.milliliters.rawValue,
        quietHoursEnabled: Bool = true,
        quietHoursStart: Int = 22, // 10 PM
        quietHoursEnd: Int = 7     // 7 AM
    ) {
        self.dailyGoal = dailyGoal
        self.reminderEnabled = reminderEnabled
        self.reminderInterval = reminderInterval
        self.preferredUnit = preferredUnit
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
    
    /// Gets the preferred unit enum
    var unit: WaterUnit {
        get {
            WaterUnit(rawValue: preferredUnit) ?? .milliliters
        }
        set {
            preferredUnit = newValue.rawValue
        }
    }
} 