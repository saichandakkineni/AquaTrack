import HealthKit
import SwiftData

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    
    private init() {}
    
    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(
            toShare: [waterType],
            read: [waterType]
        )
    }
    
    func saveWaterIntake(_ amount: Double) {
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving to HealthKit: \(error)")
            }
        }
    }
} 