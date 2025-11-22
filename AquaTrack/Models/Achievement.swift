import Foundation
import SwiftData

/// Represents an achievement earned by the user
@Model
class Achievement {
    var id: String // Unique identifier (e.g., "streak_7", "goal_100")
    var title: String
    var achievementDescription: String // Renamed from 'description' to avoid conflict with SwiftData's description property
    var iconName: String
    var earnedDate: Date
    var category: AchievementCategory
    
    init(id: String, title: String, description: String, iconName: String, earnedDate: Date = Date(), category: AchievementCategory) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.iconName = iconName
        self.earnedDate = earnedDate
        self.category = category
    }
}

enum AchievementCategory: String, Codable {
    case streak
    case goal
    case milestone
    case consistency
}

/// Achievement definitions
struct AchievementDefinition {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: Int // e.g., 7 days for streak, 100 for goal completions
    
    static let allAchievements: [AchievementDefinition] = [
        // Streak achievements
        AchievementDefinition(id: "streak_3", title: "Getting Started", description: "3 day streak", iconName: "flame.fill", category: .streak, requirement: 3),
        AchievementDefinition(id: "streak_7", title: "Week Warrior", description: "7 day streak", iconName: "flame.fill", category: .streak, requirement: 7),
        AchievementDefinition(id: "streak_14", title: "Two Week Champion", description: "14 day streak", iconName: "flame.fill", category: .streak, requirement: 14),
        AchievementDefinition(id: "streak_30", title: "Monthly Master", description: "30 day streak", iconName: "flame.fill", category: .streak, requirement: 30),
        AchievementDefinition(id: "streak_100", title: "Century Club", description: "100 day streak", iconName: "flame.fill", category: .streak, requirement: 100),
        
        // Goal completion achievements
        AchievementDefinition(id: "goal_10", title: "Goal Getter", description: "10 goals completed", iconName: "target", category: .goal, requirement: 10),
        AchievementDefinition(id: "goal_50", title: "Half Century", description: "50 goals completed", iconName: "target", category: .goal, requirement: 50),
        AchievementDefinition(id: "goal_100", title: "Century Goals", description: "100 goals completed", iconName: "target", category: .goal, requirement: 100),
        
        // Consistency achievements
        AchievementDefinition(id: "consistency_7", title: "Consistent Week", description: "7 perfect days in a row", iconName: "checkmark.circle.fill", category: .consistency, requirement: 7),
        AchievementDefinition(id: "consistency_30", title: "Perfect Month", description: "30 perfect days", iconName: "checkmark.circle.fill", category: .consistency, requirement: 30),
    ]
}

