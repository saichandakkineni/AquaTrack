import UIKit
import SwiftData
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate {
    var container: ModelContainer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            let schema = Schema([
                WaterIntake.self,
                Settings.self,
                Achievement.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Sync HealthKit data on app launch
            syncHealthKitData()
            
            // Register for background tasks
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: "com.cmobautomation.AquaTrack.refresh",
                using: nil
            ) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
        } catch {
            print("Failed to create ModelContainer: \(error.localizedDescription)")
            // Try to create a new container - this might be a migration issue
            do {
                print("Attempting to create ModelContainer with explicit schema...")
                container = try ModelContainer(
                    for: WaterIntake.self, Settings.self, Achievement.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: false)
                )
            } catch {
                print("Failed to create ModelContainer on retry: \(error.localizedDescription)")
                // Container will be nil, and AquaTrackApp will handle it
            }
        }
        return true
    }
    
    // Handle entering background
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
        saveContext()
        Task {
            if let container = container {
                let context = ModelContext(container)
                await WaterIntake.updateSharedDefaults(context: context)
            } else {
                await WaterIntake.updateSharedDefaults()
            }
        }
    }
    
    // Handle returning to foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Sync HealthKit data when app enters foreground
        syncHealthKitData()
        
        // Refresh data if needed
        NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
    }
    
    // Handle app termination
    func applicationWillTerminate(_ application: UIApplication) {
        // Save any pending changes
        if let container = container {
            try? container.mainContext.save()
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.cmobautomation.AquaTrack.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Refresh your app's data
        Task {
            if let container = container {
                let context = ModelContext(container)
                await WaterIntake.updateSharedDefaults(context: context)
            } else {
                await WaterIntake.updateSharedDefaults()
            }
            task.setTaskCompleted(success: true)
        }
    }
    
    private func saveContext() {
        if let container = container {
            try? container.mainContext.save()
        }
    }
    
    /// Syncs water intake data from HealthKit
    private func syncHealthKitData() {
        guard let container = container else {
            print("⚠️ Cannot sync HealthKit: ModelContainer not available")
            return
        }
        
        let context = ModelContext(container)
        
        // Sync in background to avoid blocking app launch
        Task {
            HealthKitManager.shared.syncWaterIntakeFromHealthKit(context: context) { importedCount in
                if importedCount > 0 {
                    print("📥 Imported \(importedCount) water intake entries from HealthKit")
                }
            }
        }
    }
}

// Custom notification for app lifecycle
extension Notification.Name {
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
    static let showOnboarding = Notification.Name("showOnboarding")
} 