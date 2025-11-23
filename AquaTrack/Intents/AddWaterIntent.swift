import Foundation
import AppIntents

@available(iOS 16.0, *)
struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Water Intake"
    static var description = IntentDescription("Add a specific amount of water to your daily intake.")
    
    @Parameter(title: "Amount (ml)", description: "Amount of water in milliliters")
    var amount: Int
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // This will be handled by the app when it opens
        // Store the intent in UserDefaults for the app to read
        if let sharedDefaults = UserDefaults(suiteName: "group.com.cmobautomation.AquaTrack") {
            sharedDefaults.set(amount, forKey: "pendingWaterIntake")
            sharedDefaults.synchronize()
        }
        
        return .result()
    }
}

@available(iOS 16.0, *)
struct QuickAddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Water"
    static var description = IntentDescription("Quickly add 250ml of water to your daily intake.")
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.cmobautomation.AquaTrack") {
            sharedDefaults.set(250, forKey: "pendingWaterIntake")
            sharedDefaults.synchronize()
        }
        
        return .result()
    }
}

