import UserNotifications
import SwiftData

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Schedules water intake reminder notifications
    /// - Parameter interval: Reminder interval in minutes
    func scheduleNotifications(interval: Int) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Validate interval
        guard interval > 0 else {
            print("Invalid notification interval: \(interval)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Hydrate! 💧"
        content.body = "Don't forget to track your water intake"
        content.sound = .default
        content.categoryIdentifier = "WATER_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(interval * 60),
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "waterReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Water reminder notifications scheduled for every \(interval) minutes")
            }
        }
    }
    
    /// Cancels all pending water reminder notifications
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 