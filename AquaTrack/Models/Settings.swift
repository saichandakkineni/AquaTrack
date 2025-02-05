import Foundation
import SwiftData

@Model
class Settings {
    var dailyGoal: Double // in milliliters
    var reminderEnabled: Bool
    var reminderInterval: Int // in minutes
    
    init(dailyGoal: Double = 2000, reminderEnabled: Bool = false, reminderInterval: Int = 60) {
        self.dailyGoal = dailyGoal
        self.reminderEnabled = reminderEnabled
        self.reminderInterval = reminderInterval
    }
} 