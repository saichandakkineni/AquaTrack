import HealthKit
import SwiftData

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    
    private init() {}
    
    /// Checks if HealthKit authorization has been granted for water intake
    func checkAuthorizationStatus() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        // authorizationStatus is synchronous
        let authStatus = healthStore.authorizationStatus(for: waterType)
        return authStatus == .sharingAuthorized
    }
    
    /// Gets the current authorization status synchronously (for UI checks)
    func getAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        // Check authorization status for sharing (writing) data
        let authStatus = healthStore.authorizationStatus(for: waterType)
        let isAuthorized = authStatus == .sharingAuthorized
        completion(isAuthorized)
    }
    
    /// Gets the detailed authorization status
    func getDetailedAuthorizationStatus() -> HKAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .notDetermined
        }
        return healthStore.authorizationStatus(for: waterType)
    }
    
    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(
            toShare: [waterType],
            read: [waterType]
        )
    }
    
    func saveWaterIntake(_ amount: Double) {
        // Only save positive amounts to HealthKit
        guard amount > 0 else {
            print("⚠️ Skipping HealthKit save: amount is not positive (\(amount)ml)")
            return
        }
        
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("❌ Error saving to HealthKit: \(error.localizedDescription)")
            } else if success {
                print("✅ Successfully saved \(amount)ml to HealthKit")
            }
        }
    }
} 