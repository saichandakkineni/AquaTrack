import Foundation
import SwiftData

@Model
class WaterIntake {
    var amount: Double // in milliliters
    var timestamp: Date
    
    init(amount: Double, timestamp: Date = Date()) {
        self.amount = amount
        self.timestamp = timestamp
        // Update shared UserDefaults for widget
        Task {
            await Self.updateSharedDefaults()
        }
    }
    
    static func updateSharedDefaults() async {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.cmobautomation.AquaTrack") else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            // Create a new container for the widget context
            let container = try ModelContainer(
                for: WaterIntake.self, Settings.self,  // Add Settings to the container
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            let context = ModelContext(container)
            
            let descriptor = FetchDescriptor<WaterIntake>(
                predicate: #Predicate<WaterIntake> { intake in
                    intake.timestamp >= startOfDay && intake.timestamp < endOfDay
                }
            )
            
            // Fetch today's intakes and settings
            let todayIntakes = try context.fetch(descriptor)
            let totalIntake = todayIntakes.reduce(0) { $0 + $1.amount }
            
            // Fetch current settings
            let settingsDescriptor = FetchDescriptor<Settings>()
            let settings = try context.fetch(settingsDescriptor)
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