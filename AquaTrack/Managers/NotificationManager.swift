import UserNotifications
import SwiftData

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Schedules water intake reminder notifications with quiet hours support
    /// - Parameters:
    ///   - interval: Reminder interval in minutes
    ///   - quietHoursEnabled: Whether quiet hours are enabled
    ///   - quietHoursStart: Hour when quiet hours start (0-23)
    ///   - quietHoursEnd: Hour when quiet hours end (0-23)
    func scheduleNotifications(
        interval: Int,
        quietHoursEnabled: Bool = true,
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 7
    ) {
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
        
        if quietHoursEnabled {
            // Schedule multiple notifications throughout the day, skipping quiet hours
            scheduleNotificationsWithQuietHours(
                interval: interval,
                quietHoursStart: quietHoursStart,
                quietHoursEnd: quietHoursEnd,
                content: content
            )
        } else {
            // Schedule simple repeating notification
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
    }
    
    /// Schedules notifications with quiet hours support
    private func scheduleNotificationsWithQuietHours(
        interval: Int,
        quietHoursStart: Int,
        quietHoursEnd: Int,
        content: UNMutableNotificationContent
    ) {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate the next notification time
        var nextNotificationTime = now
        
        // Schedule notifications for the next 24 hours
        for _ in 0..<48 { // Schedule up to 48 notifications (2 days worth)
            // Add interval minutes
            guard let nextTime = calendar.date(byAdding: .minute, value: interval, to: nextNotificationTime) else {
                break
            }
            
            let hour = calendar.component(.hour, from: nextTime)
            
            // Check if we're in quiet hours
            let isQuietHours = isInQuietHours(hour: hour, start: quietHoursStart, end: quietHoursEnd)
            
            if !isQuietHours {
                // Schedule notification
                let timeInterval = nextTime.timeIntervalSince(now)
                
                // Only schedule if it's in the future and within reasonable time (next 7 days)
                if timeInterval > 0 && timeInterval < 7 * 24 * 60 * 60 {
                    let trigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: timeInterval,
                        repeats: false
                    )
                    
                    let request = UNNotificationRequest(
                        identifier: "waterReminder_\(Int(nextTime.timeIntervalSince1970))",
                        content: content,
                        trigger: trigger
                    )
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            nextNotificationTime = nextTime
        }
        
        print("Water reminder notifications scheduled with quiet hours (start: \(quietHoursStart):00, end: \(quietHoursEnd):00)")
    }
    
    /// Checks if a given hour is within quiet hours
    /// - Parameters:
    ///   - hour: Current hour (0-23)
    ///   - start: Quiet hours start hour (0-23)
    ///   - end: Quiet hours end hour (0-23)
    /// - Returns: True if hour is within quiet hours
    private func isInQuietHours(hour: Int, start: Int, end: Int) -> Bool {
        if start <= end {
            // Quiet hours don't cross midnight (e.g., 10 AM to 2 PM)
            return hour >= start && hour < end
        } else {
            // Quiet hours cross midnight (e.g., 10 PM to 7 AM)
            return hour >= start || hour < end
        }
    }
    
    /// Sends an achievement celebration notification
    /// - Parameter achievement: The achievement that was unlocked
    func sendAchievementNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Achievement Unlocked!"
        content.body = "\(achievement.title) - \(achievement.achievementDescription)"
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        
        // Send immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending achievement notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancels all pending water reminder notifications
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 