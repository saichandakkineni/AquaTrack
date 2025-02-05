import UIKit
import SwiftData
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate {
    var container: ModelContainer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            container = try ModelContainer(
                for: WaterIntake.self, Settings.self,  // Add Settings to the container
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            
            // Register for background tasks
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: "com.cmobautomation.AquaTrack.refresh",
                using: nil
            ) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
        return true
    }
    
    // Handle entering background
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
        saveContext()
        Task {
            await WaterIntake.updateSharedDefaults()
        }
    }
    
    // Handle returning to foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
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
            await WaterIntake.updateSharedDefaults()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func saveContext() {
        if let container = container {
            try? container.mainContext.save()
        }
    }
}

// Custom notification for app lifecycle
extension Notification.Name {
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
} 