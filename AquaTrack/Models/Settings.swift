import Foundation
import SwiftData

@Model
class Settings {
    var dailyGoal: Double // in milliliters (always stored in ml)
    var reminderEnabled: Bool
    var reminderInterval: Int // in minutes
    var preferredUnit: String // WaterUnit raw value
    
    init(dailyGoal: Double = 2000, reminderEnabled: Bool = false, reminderInterval: Int = 60, preferredUnit: String = WaterUnit.milliliters.rawValue) {
        self.dailyGoal = dailyGoal
        self.reminderEnabled = reminderEnabled
        self.reminderInterval = reminderInterval
        self.preferredUnit = preferredUnit
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