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
    
    /// Reads water intake samples from HealthKit
    /// - Parameters:
    ///   - startDate: Start date for the query (default: 30 days ago)
    ///   - endDate: End date for the query (default: now)
    ///   - completion: Completion handler with array of (amount, timestamp) tuples
    func readWaterIntakeSamples(
        startDate: Date? = nil,
        endDate: Date = Date(),
        completion: @escaping ([(amount: Double, timestamp: Date)]) -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit not available")
            completion([])
            return
        }
        
        // Check authorization for reading
        // Note: authorizationStatus checks write permission, but if we have read permission
        // we can read. We'll attempt the query and handle errors if not authorized.
        
        // Default to last 30 days if no start date provided
        let start = startDate ?? Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: endDate,
            options: .strictStartDate
        )
        
        let query = HKSampleQuery(
            sampleType: waterType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error = error {
                print("❌ Error reading from HealthKit: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            // Get AquaTrack's bundle identifier to filter out our own samples
            let aquaTrackBundleId = Bundle.main.bundleIdentifier ?? "com.cmobautomation.AquaTrack"
            
            // Convert samples to (amount, timestamp) tuples, excluding AquaTrack's own samples
            let results = samples.compactMap { sample -> (amount: Double, timestamp: Date)? in
                // Skip samples created by AquaTrack itself (to avoid duplicates)
                if sample.sourceRevision.source.bundleIdentifier == aquaTrackBundleId {
                    return nil
                }
                
                // Convert to milliliters
                let amountInML = sample.quantity.doubleValue(for: .literUnit(with: .milli))
                
                // Only include positive amounts
                guard amountInML > 0 else {
                    return nil
                }
                
                return (amount: amountInML, timestamp: sample.startDate)
            }
            
            print("📥 Read \(results.count) water intake samples from HealthKit (excluding AquaTrack entries)")
            completion(results)
        }
        
        healthStore.execute(query)
    }
    
    /// Syncs water intake data from HealthKit to the app's database
    /// - Parameters:
    ///   - context: ModelContext to save imported data
    ///   - completion: Optional completion handler with count of imported samples
    func syncWaterIntakeFromHealthKit(
        context: ModelContext,
        completion: ((Int) -> Void)? = nil
    ) {
        // Check if authorized
        let authStatus = healthStore.authorizationStatus(for: waterType)
        guard authStatus == .sharingAuthorized else {
            print("⚠️ HealthKit not authorized, skipping sync")
            completion?(0)
            return
        }
        
        // Read samples from HealthKit (last 30 days)
        readWaterIntakeSamples { samples in
            guard !samples.isEmpty else {
                print("📥 No new water intake data found in HealthKit")
                completion?(0)
                return
            }
            
            // Fetch existing intakes to check for duplicates
            let descriptor = FetchDescriptor<WaterIntake>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            guard let existingIntakes = try? context.fetch(descriptor) else {
                print("❌ Error fetching existing intakes for duplicate check")
                completion?(0)
                return
            }
            
            // Create a set of string keys for existing intakes (timestamp rounded to minute + amount)
            // This allows quick duplicate detection
            let calendar = Calendar.current
            let existingKeys = Set(existingIntakes.map { intake -> String in
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: intake.timestamp)
                let roundedTimestamp = calendar.date(from: components) ?? intake.timestamp
                return "\(roundedTimestamp.timeIntervalSince1970)_\(intake.amount)"
            })
            
            var importedCount = 0
            
            // Import new samples that don't already exist
            for sample in samples {
                // Round timestamp to nearest minute for comparison
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: sample.timestamp)
                let roundedTimestamp = calendar.date(from: components) ?? sample.timestamp
                
                // Create a key for this sample
                let key = "\(roundedTimestamp.timeIntervalSince1970)_\(sample.amount)"
                
                // Check if this sample already exists (within 1 minute window and same amount)
                if !existingKeys.contains(key) {
                    // Create new WaterIntake entry
                    let intake = WaterIntake(amount: sample.amount, timestamp: sample.timestamp)
                    context.insert(intake)
                    importedCount += 1
                }
            }
            
            // Save the context
            do {
                try context.save()
                print("✅ Successfully imported \(importedCount) new water intake entries from HealthKit")
                
                // Update shared defaults for widgets
                Task {
                    await WaterIntake.updateSharedDefaults(context: context)
                }
                
                completion?(importedCount)
            } catch {
                print("❌ Error saving imported HealthKit data: \(error.localizedDescription)")
                completion?(0)
            }
        }
    }
} 