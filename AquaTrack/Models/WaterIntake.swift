import Foundation
import SwiftData

@Model
class WaterIntake {
    var amount: Double // in milliliters
    var timestamp: Date
    
    init(amount: Double, timestamp: Date = Date()) {
        self.amount = amount
        self.timestamp = timestamp
    }
    
    /// Updates shared UserDefaults for widget synchronization
    /// - Parameter context: Optional ModelContext. If nil, creates a new container (for widget use cases)
    static func updateSharedDefaults(context: ModelContext? = nil) async {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.cmobautomation.AquaTrack") else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let contextToUse: ModelContext
            if let providedContext = context {
                contextToUse = providedContext
            } else {
                // Fallback: Create a new container for widget context
                let container = try ModelContainer(
                    for: WaterIntake.self, Settings.self, Achievement.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: false)
                )
                contextToUse = ModelContext(container)
            }
            
            let descriptor = FetchDescriptor<WaterIntake>(
                predicate: #Predicate<WaterIntake> { intake in
                    intake.timestamp >= startOfDay && intake.timestamp < endOfDay
                }
            )
            
            // Fetch today's intakes
            let todayIntakes = try contextToUse.fetch(descriptor)
            let totalIntake = todayIntakes.reduce(0) { $0 + $1.amount }
            
            // Fetch current settings
            let settingsDescriptor = FetchDescriptor<Settings>()
            let settings = try contextToUse.fetch(settingsDescriptor)
            let dailyGoal = settings.first?.dailyGoal ?? 2000
            
            // Update both values in shared defaults
            sharedDefaults.set(totalIntake, forKey: "todayIntake")
            sharedDefaults.set(dailyGoal, forKey: "dailyGoal")
            sharedDefaults.synchronize()
        } catch {
            print("Error updating shared defaults: \(error)")
        }
    }
} 