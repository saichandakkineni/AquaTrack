import Foundation
import SwiftData

/// Manages streak tracking and calculation
class StreakManager {
    static let shared = StreakManager()
    
    private init() {}
    
    /// Calculates the current streak based on daily goal completions
    /// - Parameters:
    ///   - intakes: All water intake records
    ///   - dailyGoal: The daily goal in milliliters
    ///   - context: ModelContext for fetching data
    /// - Returns: Current streak count (number of consecutive days meeting goal)
    func calculateCurrentStreak(intakes: [WaterIntake], dailyGoal: Double, context: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Get all unique dates with intake data
        var dailyTotals: [Date: Double] = [:]
        
        for intake in intakes {
            let day = calendar.startOfDay(for: intake.timestamp)
            dailyTotals[day, default: 0] += intake.amount
        }
        
        // Check consecutive days from today backwards
        var streak = 0
        var currentDate = calendar.startOfDay(for: today)
        
        while true {
            guard let dayTotal = dailyTotals[currentDate] else {
                // No data for this day - streak ends
                break
            }
            
            if dayTotal >= dailyGoal {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // Goal not met - streak ends
                break
            }
        }
        
        return streak
    }
    
    /// Calculates the longest streak ever achieved
    /// - Parameters:
    ///   - intakes: All water intake records
    ///   - dailyGoal: The daily goal in milliliters
    ///   - context: ModelContext for fetching data
    /// - Returns: Longest streak count
    func calculateLongestStreak(intakes: [WaterIntake], dailyGoal: Double, context: ModelContext) -> Int {
        let calendar = Calendar.current
        
        // Get all unique dates with intake data, sorted
        var dailyTotals: [Date: Double] = [:]
        
        for intake in intakes {
            let day = calendar.startOfDay(for: intake.timestamp)
            dailyTotals[day, default: 0] += intake.amount
        }
        
        let sortedDates = dailyTotals.keys.sorted()
        
        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for date in sortedDates {
            guard let dayTotal = dailyTotals[date] else { continue }
            
            if dayTotal >= dailyGoal {
                // Check if this is consecutive with previous date
                if let prev = previousDate {
                    let dayDifference = calendar.dateComponents([.day], from: prev, to: date).day
                    if dayDifference == 1 {
                        // Consecutive day
                        currentStreak += 1
                    } else {
                        // Not consecutive - new streak starting
                        currentStreak = 1
                    }
                } else {
                    // First date - streak starts at 1
                    currentStreak = 1
                }
                
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // Goal not met - reset streak
                currentStreak = 0
            }
            
            previousDate = date
        }
        
        return longestStreak
    }
    
    /// Checks if today's goal is met
    /// - Parameters:
    ///   - intakes: Today's water intake records
    ///   - dailyGoal: The daily goal in milliliters
    /// - Returns: True if goal is met
    func isGoalMetToday(intakes: [WaterIntake], dailyGoal: Double) -> Bool {
        let total = intakes.reduce(0) { $0 + $1.amount }
        return total >= dailyGoal
    }
}

