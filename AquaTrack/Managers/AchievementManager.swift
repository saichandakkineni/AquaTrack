import Foundation
import SwiftData

/// Manages achievement tracking and unlocking
class AchievementManager {
    static let shared = AchievementManager()
    
    private init() {}
    
    /// Checks and unlocks achievements based on current progress
    /// - Parameters:
    ///   - context: ModelContext for saving achievements
    ///   - currentStreak: Current streak count
    ///   - goalCompletions: Total number of days goal was met
    ///   - perfectDays: Number of consecutive perfect days
    /// - Returns: Array of newly unlocked achievement IDs
    func checkAndUnlockAchievements(
        context: ModelContext,
        currentStreak: Int,
        goalCompletions: Int,
        perfectDays: Int
    ) -> [String] {
        var newlyUnlocked: [String] = []
        
        // Fetch existing achievements
        let descriptor = FetchDescriptor<Achievement>()
        let existingAchievements: [Achievement]
        do {
            existingAchievements = try context.fetch(descriptor)
        } catch {
            print("Error fetching achievements: \(error.localizedDescription)")
            return []
        }
        
        let existingIds = Set(existingAchievements.map { $0.id })
        
        // Check streak achievements
        for achievement in AchievementDefinition.allAchievements where achievement.category == .streak {
            if !existingIds.contains(achievement.id) && currentStreak >= achievement.requirement {
                unlockAchievement(achievement, context: context)
                newlyUnlocked.append(achievement.id)
            }
        }
        
        // Check goal completion achievements
        for achievement in AchievementDefinition.allAchievements where achievement.category == .goal {
            if !existingIds.contains(achievement.id) && goalCompletions >= achievement.requirement {
                unlockAchievement(achievement, context: context)
                newlyUnlocked.append(achievement.id)
            }
        }
        
        // Check consistency achievements
        for achievement in AchievementDefinition.allAchievements where achievement.category == .consistency {
            if !existingIds.contains(achievement.id) && perfectDays >= achievement.requirement {
                unlockAchievement(achievement, context: context)
                newlyUnlocked.append(achievement.id)
            }
        }
        
        return newlyUnlocked
    }
    
    /// Unlocks an achievement
    private func unlockAchievement(_ definition: AchievementDefinition, context: ModelContext) {
        let achievement = Achievement(
            id: definition.id,
            title: definition.title,
            description: definition.description,
            iconName: definition.iconName,
            earnedDate: Date(),
            category: definition.category
        )
        
        context.insert(achievement)
        
        do {
            try context.save()
            print("Achievement unlocked: \(definition.title)")
        } catch {
            print("Error saving achievement: \(error.localizedDescription)")
        }
    }
    
    /// Calculates total goal completions
    /// - Parameters:
    ///   - intakes: All water intake records
    ///   - dailyGoal: The daily goal in milliliters
    ///   - context: ModelContext
    /// - Returns: Total number of days goal was met
    func calculateGoalCompletions(intakes: [WaterIntake], dailyGoal: Double, context: ModelContext) -> Int {
        let calendar = Calendar.current
        
        // Get all unique dates with intake data
        var dailyTotals: [Date: Double] = [:]
        
        for intake in intakes {
            let day = calendar.startOfDay(for: intake.timestamp)
            dailyTotals[day, default: 0] += intake.amount
        }
        
        // Count days where goal was met
        var completions = 0
        for (_, total) in dailyTotals {
            if total >= dailyGoal {
                completions += 1
            }
        }
        
        return completions
    }
    
    /// Calculates consecutive perfect days (goal met)
    /// - Parameters:
    ///   - intakes: All water intake records
    ///   - dailyGoal: The daily goal in milliliters
    ///   - context: ModelContext
    /// - Returns: Number of consecutive perfect days
    func calculatePerfectDays(intakes: [WaterIntake], dailyGoal: Double, context: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Get all unique dates with intake data
        var dailyTotals: [Date: Double] = [:]
        
        for intake in intakes {
            let day = calendar.startOfDay(for: intake.timestamp)
            dailyTotals[day, default: 0] += intake.amount
        }
        
        // Count consecutive perfect days from today backwards
        var perfectDays = 0
        var currentDate = calendar.startOfDay(for: today)
        
        while true {
            guard let dayTotal = dailyTotals[currentDate] else {
                break
            }
            
            if dayTotal >= dailyGoal {
                perfectDays += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return perfectDays
    }
}

