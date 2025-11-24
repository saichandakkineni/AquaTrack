import Foundation
import SwiftData

/// Tracks user usage patterns for smart suggestions
class UsageTracker {
    static let shared = UsageTracker()
    
    private init() {}
    
    /// Gets the most frequently used amount from intake history
    /// - Parameters:
    ///   - intakes: All water intake records
    ///   - limit: Number of recent days to consider (default: 30)
    /// - Returns: Most used amount, or nil if no data
    func getMostUsedAmount(intakes: [WaterIntake], limitDays: Int = 30) -> Double? {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -limitDays, to: Date()) ?? Date()
        
        // Filter recent intakes
        let recentIntakes = intakes.filter { $0.timestamp >= cutoffDate && $0.amount > 0 }
        
        guard !recentIntakes.isEmpty else { return nil }
        
        // Count occurrences of each amount (rounded to nearest 25ml for grouping)
        var amountCounts: [Double: Int] = [:]
        
        for intake in recentIntakes {
            let rounded = round(intake.amount / 25) * 25
            amountCounts[rounded, default: 0] += 1
        }
        
        // Return the most frequently used amount
        return amountCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Gets the last 3 unique amounts used
    /// - Parameter intakes: All water intake records
    /// - Returns: Array of last 3 unique amounts (most recent first)
    func getRecentAmounts(intakes: [WaterIntake]) -> [Double] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get today's intakes, sorted by most recent
        let todayIntakes = intakes
            .filter { calendar.isDateInToday($0.timestamp) && $0.amount > 0 }
            .sorted { $0.timestamp > $1.timestamp }
        
        // Extract unique amounts (most recent first)
        var seen: Set<Double> = []
        var recent: [Double] = []
        
        for intake in todayIntakes {
            let rounded = round(intake.amount / 25) * 25 // Round to nearest 25ml
            if !seen.contains(rounded) && rounded > 0 {
                seen.insert(rounded)
                recent.append(rounded)
                if recent.count >= 3 {
                    break
                }
            }
        }
        
        return recent
    }
    
    /// Gets suggested amount based on time of day and progress
    /// - Parameters:
    ///   - currentIntake: Current total intake for today
    ///   - dailyGoal: Daily goal amount
    ///   - hour: Current hour (0-23)
    /// - Returns: Suggested amount to add
    func getSuggestedAmount(currentIntake: Double, dailyGoal: Double, hour: Int) -> Double {
        let remaining = dailyGoal - currentIntake
        
        // If close to goal, suggest remaining amount (rounded)
        if remaining > 0 && remaining < 500 {
            return round(remaining / 25) * 25
        }
        
        // Time-based suggestions
        if hour >= 6 && hour < 12 {
            // Morning: suggest 250-500ml
            return 250
        } else if hour >= 12 && hour < 18 {
            // Afternoon: suggest 500ml
            return 500
        } else if hour >= 18 && hour < 22 {
            // Evening: suggest 250ml
            return 250
        } else {
            // Night: suggest smaller amounts
            return 100
        }
    }
    
    /// Gets primary quick add amounts (most used, adaptive)
    /// - Parameter intakes: All water intake records
    /// - Returns: Array of 3-4 most used amounts, or defaults if no data
    func getPrimaryAmounts(intakes: [WaterIntake]) -> [Double] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Filter recent intakes
        let recentIntakes = intakes.filter { $0.timestamp >= cutoffDate && $0.amount > 0 }
        
        guard !recentIntakes.isEmpty else {
            // Default amounts if no usage data
            return [250.0, 500.0, 750.0]
        }
        
        // Count occurrences of each amount (rounded to nearest 25ml)
        var amountCounts: [Double: Int] = [:]
        
        for intake in recentIntakes {
            let rounded = round(intake.amount / 25) * 25
            amountCounts[rounded, default: 0] += 1
        }
        
        // Get top 3-4 most used amounts
        let sortedAmounts = amountCounts.sorted { $0.value > $1.value }
        let topAmounts = Array(sortedAmounts.prefix(4).map { $0.key })
        
        // If we have at least 3, return them; otherwise pad with defaults
        if topAmounts.count >= 3 {
            return Array(topAmounts.prefix(4))
        } else {
            let defaults = [250.0, 500.0, 750.0]
            return Array(Set(topAmounts + defaults).sorted().prefix(4))
        }
    }
    
    /// Gets time-based suggestion message
    /// - Parameter hour: Current hour (0-23)
    /// - Returns: Suggestion message
    func getTimeBasedSuggestionMessage(hour: Int) -> String {
        if hour >= 6 && hour < 12 {
            return "Good morning! Start your day with hydration 💧"
        } else if hour >= 12 && hour < 18 {
            return "Afternoon boost! Stay hydrated ☀️"
        } else if hour >= 18 && hour < 22 {
            return "Evening hydration for better sleep 🌙"
        } else {
            return "Night time - small sips recommended 🌃"
        }
    }
}

