import SwiftUI
import SwiftData

struct DailyTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    let todayIntakes: [WaterIntake]
    let dailyGoal: Double
    
    @Query private var settings: [Settings]
    @Query(sort: \WaterIntake.timestamp, order: .reverse) private var allIntakes: [WaterIntake]
    
    private let smallAmounts = [25.0, 50.0, 100.0]
    private let standardAmounts = [250.0, 500.0, 750.0]
    @State private var customAmount: Double = 0
    @State private var showingCustomInput = false
    @State private var showingInsufficientIntakeAlert = false
    @State private var attemptedDecreaseAmount: Double = 0
    @State private var lastActionIntake: WaterIntake?
    @State private var showingUndoAlert = false
    @State private var showingUndoSuccess = false
    @State private var currentStreak: Int = 0
    @State private var unlockedAchievement: Achievement?
    @State private var showingAchievementCelebration = false
    @State private var showingGoalCelebration = false
    @State private var hasShownGoalCelebrationToday = false
    @State private var showingConfetti = false
    @State private var confettiMessage = ""
    @State private var confettiSubtitle: String? = nil
    @State private var showingMaxAmountExceededAlert = false
    @State private var attemptedAddAmount: Double = 0
    @State private var showingQuickActionsMenu = false
    
    private let maxDailyIntake: Double = 10000 // 10 liters maximum per day
    
    private var currentUnit: WaterUnit {
        settings.first?.unit ?? .milliliters
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                // Progress Circle with swipe gesture
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress >= 1.0 ? Color.green : Color.blue,
                            style: StrokeStyle(
                                lineWidth: 20,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                        .overlay {
                            // Pulse effect when goal is reached
                            if progress >= 1.0 {
                                Circle()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 20)
                                    .scaleEffect(1.1)
                                    .opacity(0.5)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true),
                                        value: progress
                                    )
                            }
                        }
                    
                    VStack(spacing: 6) {
                        // Main intake display with animation
                        Text(formatAmount(totalIntake))
                            .font(.system(size: 36, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: totalIntake)
                        
                        // Progress percentage
                        Text("\(progressPercentage)%")
                            .font(.caption)
                            .foregroundColor(progress >= 1.0 ? .green : .blue)
                            .bold()
                        
                        // Remaining to goal (prominently displayed)
                        if remainingToGoal > 0 {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "drop.fill")
                                        .font(.caption2)
                                    Text("\(formatAmount(remainingToGoal)) to goal")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Progress insight: On track indicator
                                if let insight = getProgressInsight() {
                                    Text(insight)
                                        .font(.caption2)
                                        .foregroundColor(insight.contains("On track") ? .green : .orange)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Goal achieved!")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .bold()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        if currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(currentStreak) day streak")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .aspectRatio(1, contentMode: .fit)
                .padding()
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            // Swipe up = quick add most common amount
                            if value.translation.height < -50 {
                                let mostUsed = UsageTracker.shared.getMostUsedAmount(intakes: Array(allIntakes)) ?? 250
                                addWater(amount: mostUsed)
                                HapticManager.shared.mediumImpact()
                            }
                        }
                )
                .onLongPressGesture {
                    // Long press = show quick actions menu
                    showQuickActionsMenu()
                }
                
                // Small Amount Buttons
                VStack(spacing: 10) {
                    Text("Quick Add - Small")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(smallAmounts, id: \.self) { amount in
                            AnimatedButton(hapticStyle: .light) {
                                addWater(amount: amount)
                            } label: {
                                Text("+\(Int(amount))ml")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(smallAmounts, id: \.self) { amount in
                            AnimatedButton(hapticStyle: .light) {
                                decreaseWater(amount: amount)
                            } label: {
                                Text("-\(Int(amount))ml")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Standard Amount Buttons
                VStack(spacing: 10) {
                    Text("Quick Add - Standard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(standardAmounts, id: \.self) { amount in
                            AnimatedButton(hapticStyle: .medium) {
                                addWater(amount: amount)
                            } label: {
                                Text("+\(Int(amount))ml")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(standardAmounts, id: \.self) { amount in
                            AnimatedButton(hapticStyle: .medium) {
                                decreaseWater(amount: amount)
                            } label: {
                                Text("-\(Int(amount))ml")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Smart Quick Actions Section
                if let mostUsed = UsageTracker.shared.getMostUsedAmount(intakes: Array(allIntakes)) {
                    VStack(spacing: 10) {
                        Text("Quick Add - Most Used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        AnimatedButton(hapticStyle: .medium) {
                            addWater(amount: mostUsed)
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("+\(Int(mostUsed))ml")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                // Recent Amounts Section
                let recentAmounts = UsageTracker.shared.getRecentAmounts(intakes: Array(allIntakes))
                if !recentAmounts.isEmpty && recentAmounts.count > 1 {
                    VStack(spacing: 10) {
                        Text("Recent Amounts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(recentAmounts.prefix(3), id: \.self) { amount in
                                AnimatedButton(hapticStyle: .light) {
                                    addWater(amount: amount)
                                } label: {
                                    Text("+\(Int(amount))ml")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.7))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
                
                AnimatedButton(hapticStyle: .light) {
                    showingCustomInput = true
                } label: {
                    Text("Custom Amount")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .padding(.horizontal)
                
                // Add bottom padding for landscape mode
                Spacer()
                    .frame(height: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Today's Intake")
        .sheet(isPresented: $showingCustomInput) {
            CustomAmountView { amount in
                addWater(amount: amount)
            }
        }
        .alert("Insufficient Intake", isPresented: $showingInsufficientIntakeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You don't have \(Int(attemptedDecreaseAmount))ml of water intake yet. Your current intake is \(Int(totalIntake))ml.")
        }
        .alert("Undo Last Action", isPresented: $showingUndoAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to undo. The last action may have already been undone or is no longer available.")
        }
        .alert("Action Undone", isPresented: $showingUndoSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The last water intake action has been successfully undone.")
        }
        .alert("Maximum Intake Exceeded", isPresented: $showingMaxAmountExceededAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            let currentTotal = totalIntake
            let remaining = maxDailyIntake - currentTotal
            if attemptedAddAmount > maxDailyIntake {
                Text("The amount \(Int(attemptedAddAmount))ml exceeds the maximum single intake of \(Int(maxDailyIntake))ml (10 liters). Please enter a smaller amount.")
            } else {
                Text("Adding \(Int(attemptedAddAmount))ml would exceed the daily maximum of \(Int(maxDailyIntake))ml (10 liters). You can still add up to \(Int(remaining))ml today.")
            }
        }
                .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        undoLastAction()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(lastActionIntake == nil)
                }
                
                // Test celebration button removed - use natural achievements instead
            }
        .onAppear {
            updateStreak()
            // Reset goal celebration flag for new day
            let calendar = Calendar.current
            if let lastReset = UserDefaults.standard.object(forKey: "lastGoalCelebrationReset") as? Date,
               !calendar.isDateInToday(lastReset) {
                hasShownGoalCelebrationToday = false
                UserDefaults.standard.set(Date(), forKey: "lastGoalCelebrationReset")
            } else if UserDefaults.standard.object(forKey: "lastGoalCelebrationReset") == nil {
                UserDefaults.standard.set(Date(), forKey: "lastGoalCelebrationReset")
            }
            
            // Handle pending water intake from widget/shortcuts
            if let sharedDefaults = UserDefaults(suiteName: "group.com.cmobautomation.AquaTrack"),
               let pendingAmount = sharedDefaults.object(forKey: "pendingWaterIntake") as? Int,
               pendingAmount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    addWater(amount: Double(pendingAmount))
                    sharedDefaults.removeObject(forKey: "pendingWaterIntake")
                    sharedDefaults.synchronize()
                }
            }
        }
        .overlay {
            // Confetti celebration overlay
            ConfettiCelebrationView(
                message: confettiMessage,
                subtitle: confettiSubtitle,
                isPresented: $showingConfetti
            )
        }
        .sheet(isPresented: $showingQuickActionsMenu) {
            QuickActionsMenuView(
                mostUsedAmount: UsageTracker.shared.getMostUsedAmount(intakes: Array(allIntakes)),
                recentAmounts: UsageTracker.shared.getRecentAmounts(intakes: Array(allIntakes)),
                suggestedAmount: UsageTracker.shared.getSuggestedAmount(
                    currentIntake: totalIntake,
                    dailyGoal: dailyGoal,
                    hour: Calendar.current.component(.hour, from: Date())
                ),
                onAdd: { amount in
                    addWater(amount: amount)
                    showingQuickActionsMenu = false
                }
            )
        }
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let converted = WaterUnit.convert(amount, from: .milliliters, to: currentUnit)
        return "\(currentUnit.format(converted)) \(currentUnit.displayName)"
    }
    
    private func updateStreak() {
        // Calculate streak synchronously since we already have the data
        let streak = StreakManager.shared.calculateCurrentStreak(
            intakes: Array(allIntakes),
            dailyGoal: dailyGoal,
            context: modelContext
        )
        currentStreak = streak
    }
    
    private var totalIntake: Double {
        todayIntakes.reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(totalIntake / dailyGoal, 1.0)
    }
    
    private var remainingToGoal: Double {
        max(0, dailyGoal - totalIntake)
    }
    
    private var progressPercentage: Int {
        Int(progress * 100)
    }
    
    /// Shows quick actions menu
    private func showQuickActionsMenu() {
        HapticManager.shared.mediumImpact()
        showingQuickActionsMenu = true
    }
    
    /// Gets progress insight based on current time and intake
    private func getProgressInsight() -> String? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let progressPercent = progress * 100
        
        // Calculate expected progress based on time of day
        let expectedProgress: Double
        if hour < 6 {
            expectedProgress = 0.0
        } else if hour < 12 {
            expectedProgress = Double(hour - 6) / 18.0 * 100.0 // Morning: 0-33%
        } else if hour < 18 {
            expectedProgress = 33.0 + Double(hour - 12) / 18.0 * 34.0 // Afternoon: 33-67%
        } else {
            expectedProgress = 67.0 + Double(hour - 18) / 18.0 * 33.0 // Evening: 67-100%
        }
        
        let difference = progressPercent - expectedProgress
        
        if difference > 10 {
            return "🎯 On track! Keep it up!"
        } else if difference < -15 {
            return "⏰ Catching up needed"
        } else if difference < -5 {
            return "💧 Slightly behind"
        }
        
        return nil
    }
    
    private func addWater(amount: Double) {
        // Check if amount is valid
        guard amount > 0 && amount.isFinite else {
            print("Invalid water amount: \(amount)")
            return
        }
        
        // Check if single amount exceeds maximum
        guard amount <= maxDailyIntake else {
            attemptedAddAmount = amount
            showingMaxAmountExceededAlert = true
            print("Single amount exceeds maximum: \(amount)ml")
            return
        }
        
        // Calculate totals BEFORE adding the new intake
        let previousTotal = totalIntake
        let newTotalAfterAdd = previousTotal + amount
        
        // Check if adding this amount would exceed daily maximum
        if newTotalAfterAdd > maxDailyIntake {
            attemptedAddAmount = amount
            showingMaxAmountExceededAlert = true
            print("Daily intake would exceed maximum: \(newTotalAfterAdd)ml > \(maxDailyIntake)ml")
            return
        }
        
        // Check if goal will be reached
        let goalJustReached = previousTotal < dailyGoal && newTotalAfterAdd >= dailyGoal
        
        print("💧 Adding water: \(amount)ml")
        print("📊 Previous total: \(previousTotal)ml, New total: \(newTotalAfterAdd)ml, Goal: \(dailyGoal)ml")
        print("🎯 Goal just reached: \(goalJustReached)")
        
        let intake = WaterIntake(amount: amount)
        modelContext.insert(intake)
        
        // Store for undo functionality
        lastActionIntake = intake
        
        do {
            try modelContext.save()
            
            Task {
                await WaterIntake.updateSharedDefaults(context: modelContext)
                
                // Always check achievements after adding water
                await checkAndUnlockAchievements()
                
                // If goal was just reached, show celebration and check achievements again
                if goalJustReached {
                    if !hasShownGoalCelebrationToday {
                        print("🎯 Daily goal reached! Showing celebration...")
                        print("📈 Previous: \(previousTotal)ml < Goal: \(dailyGoal)ml")
                        print("📈 New: \(newTotalAfterAdd)ml >= Goal: \(dailyGoal)ml")
                        
                        await MainActor.run {
                            // Trigger success haptic
                            HapticManager.shared.success()
                            
                            // Show confetti celebration
                            hasShownGoalCelebrationToday = true
                            confettiMessage = "Daily Goal Achieved! 🎉"
                            confettiSubtitle = currentStreak > 0 ? "\(currentStreak) day streak!" : "Great job staying hydrated!"
                            showingConfetti = true
                            print("✅ Confetti celebration triggered")
                        }
                        
                        // Check achievements again to catch goal-based achievements
                        await checkAndUnlockAchievements()
                    } else {
                        print("⚠️ Goal reached but celebration already shown (will reset if intake drops below goal)")
                    }
                } else {
                    // If intake is below goal, reset the flag so celebration can show again
                    if newTotalAfterAdd < dailyGoal && hasShownGoalCelebrationToday {
                        await MainActor.run {
                            hasShownGoalCelebrationToday = false
                            print("🔄 Intake below goal, resetting celebration flag for next completion")
                        }
                    }
                }
                
                await MainActor.run {
                    // Update streak after achievements are checked
                    let streak = StreakManager.shared.calculateCurrentStreak(
                        intakes: Array(allIntakes),
                        dailyGoal: dailyGoal,
                        context: modelContext
                    )
                    currentStreak = streak
                }
            }
        } catch {
            print("Error saving water intake: \(error.localizedDescription)")
            lastActionIntake = nil
        }
    }
    
    private func decreaseWater(amount: Double) {
        // Additional safety check
        guard amount > 0 && amount.isFinite && amount <= 10000 else {
            print("Invalid water amount for decrease: \(amount)")
            return
        }
        
        if totalIntake >= amount {
            // Calculate new total after decrease
            let previousTotal = totalIntake
            let newTotalAfterDecrease = previousTotal - amount
            
            // Reset celebration flag if intake drops below goal
            if previousTotal >= dailyGoal && newTotalAfterDecrease < dailyGoal {
                hasShownGoalCelebrationToday = false
                print("🔄 Intake dropped below goal, resetting celebration flag")
            }
            
            let intake = WaterIntake(amount: -amount)
            modelContext.insert(intake)
            
            // Store for undo functionality
            lastActionIntake = intake
            
            do {
                try modelContext.save()
                Task {
                    await WaterIntake.updateSharedDefaults(context: modelContext)
                    await checkAndUnlockAchievements()
                    await MainActor.run {
                        // Update streak after achievements are checked
                        let streak = StreakManager.shared.calculateCurrentStreak(
                            intakes: Array(allIntakes),
                            dailyGoal: dailyGoal,
                            context: modelContext
                        )
                        currentStreak = streak
                    }
                }
            } catch {
                print("Error saving water intake decrease: \(error.localizedDescription)")
                lastActionIntake = nil
            }
        } else {
            // Show alert when trying to decrease more than available
            attemptedDecreaseAmount = amount
            showingInsufficientIntakeAlert = true
        }
    }
    
    /// Undoes the last action (add or decrease)
    private func undoLastAction() {
        guard let intakeToRemove = lastActionIntake else {
            showingUndoAlert = true
            return
        }
        
        // Find the most recent intake that matches the amount and is within a small time window
        // This handles the case where we can't use complex predicates
        let calendar = Calendar.current
        let targetTime = intakeToRemove.timestamp
        let targetAmount = intakeToRemove.amount
        
        // Fetch recent intakes (last hour) and find a match
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<WaterIntake>(
            predicate: #Predicate<WaterIntake> { intake in
                intake.timestamp >= oneHourAgo && intake.amount == targetAmount
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let recentIntakes = try modelContext.fetch(descriptor)
            // Find the closest match by timestamp
            if let matchingIntake = recentIntakes.first(where: { intake in
                abs(intake.timestamp.timeIntervalSince(targetTime)) < 60 && intake.amount == targetAmount
            }) {
                // Calculate totals before undoing
                let previousTotal = totalIntake
                let newTotalAfterUndo = previousTotal - matchingIntake.amount
                
                // Reset celebration flag if intake drops below goal after undo
                if previousTotal >= dailyGoal && newTotalAfterUndo < dailyGoal {
                    hasShownGoalCelebrationToday = false
                    print("🔄 Undo caused intake to drop below goal, resetting celebration flag")
                }
                
                modelContext.delete(matchingIntake)
                try modelContext.save()
                
                lastActionIntake = nil
                showingUndoSuccess = true
                
                Task {
                    await WaterIntake.updateSharedDefaults(context: modelContext)
                    await checkAndUnlockAchievements()
                    await MainActor.run {
                        // Update streak after achievements are checked
                        let streak = StreakManager.shared.calculateCurrentStreak(
                            intakes: Array(allIntakes),
                            dailyGoal: dailyGoal,
                            context: modelContext
                        )
                        currentStreak = streak
                    }
                }
            } else {
                // Intake not found - might have been deleted already
                showingUndoAlert = true
                lastActionIntake = nil
            }
        } catch {
            print("Error undoing last action: \(error.localizedDescription)")
            showingUndoAlert = true
        }
    }
    
    
    /// Checks and unlocks achievements after water intake changes
    private func checkAndUnlockAchievements() async {
        let allIntakes = try? modelContext.fetch(FetchDescriptor<WaterIntake>())
        guard let intakes = allIntakes else { return }
        
        let streakManager = StreakManager.shared
        let achievementManager = AchievementManager.shared
        
        let currentStreak = streakManager.calculateCurrentStreak(
            intakes: intakes,
            dailyGoal: dailyGoal,
            context: modelContext
        )
        
        let goalCompletions = achievementManager.calculateGoalCompletions(
            intakes: intakes,
            dailyGoal: dailyGoal,
            context: modelContext
        )
        
        let perfectDays = achievementManager.calculatePerfectDays(
            intakes: intakes,
            dailyGoal: dailyGoal,
            context: modelContext
        )
        
        let newAchievements = achievementManager.checkAndUnlockAchievements(
            context: modelContext,
            currentStreak: currentStreak,
            goalCompletions: goalCompletions,
            perfectDays: perfectDays
        )
        
        if !newAchievements.isEmpty {
            print("🎉 \(newAchievements.count) new achievement(s) unlocked!")
            
            // Show celebration for the first unlocked achievement
            if let firstAchievement = newAchievements.first {
                print("🎊 Showing celebration for: \(firstAchievement.title)")
                
                await MainActor.run {
                    unlockedAchievement = firstAchievement
                    showingAchievementCelebration = true
                    print("✅ Celebration state set - view should appear now")
                    
                    // Also send a notification
                    NotificationManager.shared.sendAchievementNotification(firstAchievement)
                }
            }
        } else {
            print("ℹ️ No new achievements unlocked (current streak: \(currentStreak), goal completions: \(goalCompletions), perfect days: \(perfectDays))")
        }
    }
}

struct CustomAmountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rawInput: String = ""
    @State private var errorMessage: String?
    let onAdd: (Double) -> Void
    
    // Reasonable limits for water intake
    private let minAmount: Double = 1
    private let maxAmount: Double = 10000 // 10 liters maximum
    
    // Computed binding that filters input
    private var amountText: Binding<String> {
        Binding(
            get: { rawInput },
            set: { newValue in
                // Filter out non-numeric characters (except one decimal point)
                var filtered = newValue.filter { $0.isNumber || $0 == "." }
                
                // Ensure only one decimal point
                let components = filtered.split(separator: ".")
                if components.count > 2 {
                    filtered = String(components[0]) + "." + components.dropFirst().joined(separator: "")
                }
                
                // Limit to reasonable length (max 6 digits before decimal, 2 after)
                if filtered.count > 8 {
                    filtered = String(filtered.prefix(8))
                }
                
                rawInput = filtered
                validateInput(filtered)
            }
        )
    }
    
    private var isValidAmount: Bool {
        guard let amount = parseAmount(rawInput) else { return false }
        return amount >= minAmount && amount <= maxAmount
    }
    
    private var parsedAmount: Double? {
        parseAmount(rawInput)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount (ml)", text: amountText)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if let amount = parsedAmount, isValidAmount {
                        Text("\(Int(amount))ml will be added")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Enter amount between \(Int(minAmount))ml and \(Int(maxAmount))ml")
                } footer: {
                    Text("Maximum recommended daily intake is typically 3-4 liters (3000-4000ml)")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let amount = parsedAmount, isValidAmount {
                            onAdd(amount)
                            dismiss()
                        }
                    }
                    .disabled(!isValidAmount)
                }
            }
        }
    }
    
    /// Parses the input string to a Double, handling edge cases
    private func parseAmount(_ text: String) -> Double? {
        // Remove any whitespace
        let cleaned = text.trimmingCharacters(in: .whitespaces)
        
        // Return nil for empty strings
        guard !cleaned.isEmpty else { return nil }
        
        // Try to parse as Double
        guard let value = Double(cleaned) else { return nil }
        
        // Check for valid number (not NaN or infinity)
        guard value.isFinite else { return nil }
        
        return value
    }
    
    /// Validates the input and sets error message if invalid
    private func validateInput(_ text: String) {
        errorMessage = nil
        
        guard !text.isEmpty else {
            return
        }
        
        guard let amount = parseAmount(text) else {
            errorMessage = "Please enter a valid number"
            return
        }
        
        if amount < minAmount {
            errorMessage = "Amount must be at least \(Int(minAmount))ml"
        } else if amount > maxAmount {
            errorMessage = "Amount cannot exceed \(Int(maxAmount))ml (10 liters)"
        }
    }
} 