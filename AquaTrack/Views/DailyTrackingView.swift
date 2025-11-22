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
    
    private var currentUnit: WaterUnit {
        settings.first?.unit ?? .milliliters
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blue, style: StrokeStyle(
                            lineWidth: 20,
                            lineCap: .round
                        ))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring, value: progress)
                    
                    VStack(spacing: 4) {
                        Text(formatAmount(totalIntake))
                            .font(.system(size: 36, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text("of \(formatAmount(dailyGoal))")
                            .foregroundStyle(.secondary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        if currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(currentStreak) day streak")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .aspectRatio(1, contentMode: .fit)
                .padding()
                
                // Small Amount Buttons
                VStack(spacing: 10) {
                    Text("Quick Add - Small")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(smallAmounts, id: \.self) { amount in
                            Button {
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
                            Button {
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
                            Button {
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
                            Button {
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
                
                Button {
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    undoLastAction()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(lastActionIntake == nil)
            }
        }
        .onAppear {
            updateStreak()
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
    
    private func addWater(amount: Double) {
        // Additional safety check to prevent invalid amounts
        guard amount > 0 && amount.isFinite && amount <= 10000 else {
            print("Invalid water amount: \(amount)")
            return
        }
        
        let intake = WaterIntake(amount: amount)
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
            // Could show a celebration view here
            print("New achievements unlocked: \(newAchievements)")
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