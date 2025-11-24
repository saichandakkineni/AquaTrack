import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query(sort: \Achievement.earnedDate, order: .reverse) private var earnedAchievements: [Achievement]
    @Query private var settings: [Settings]
    @Query(sort: \WaterIntake.timestamp, order: .reverse) private var allIntakes: [WaterIntake]
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentStreak: Int = 0
    @State private var longestStreak: Int = 0
    @State private var goalCompletions: Int = 0
    @State private var showingAchievementDetail: Achievement?
    @State private var unlockedAchievement: Achievement?
    @State private var showingAchievementCelebration = false
    
    private var dailyGoal: Double {
        settings.first?.dailyGoal ?? 2000
    }
    
    private var allAchievementDefinitions: [AchievementDefinition] {
        AchievementDefinition.allAchievements
    }
    
    private var earnedAchievementIds: Set<String> {
        Set(earnedAchievements.map { $0.id })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Card
                    VStack(spacing: 16) {
                        Text("Your Progress")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Current Streak",
                                value: "\(currentStreak)",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Longest Streak",
                                value: "\(longestStreak)",
                                icon: "star.fill",
                                color: .yellow
                            )
                            
                            StatCard(
                                title: "Goals Met",
                                value: "\(goalCompletions)",
                                icon: "target",
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Achievements Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Achievements")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(allAchievementDefinitions, id: \.id) { definition in
                                let progress = getAchievementProgress(for: definition)
                                AchievementCard(
                                    definition: definition,
                                    isEarned: earnedAchievementIds.contains(definition.id),
                                    earnedDate: earnedAchievements.first { $0.id == definition.id }?.earnedDate,
                                    currentProgress: progress
                                )
                                .onTapGesture {
                                    if earnedAchievementIds.contains(definition.id) {
                                        showingAchievementDetail = earnedAchievements.first { $0.id == definition.id }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                updateStats()
            }
            .sheet(item: $showingAchievementDetail) { achievement in
                AchievementDetailView(achievement: achievement)
            }
            .fullScreenCover(isPresented: $showingAchievementCelebration) {
                if let achievement = unlockedAchievement {
                    AchievementCelebrationView(achievement: achievement, isPresented: $showingAchievementCelebration)
                }
            }
        }
    }
    
    private func updateStats() {
        Task {
            let streakManager = StreakManager.shared
            let achievementManager = AchievementManager.shared
            
            currentStreak = streakManager.calculateCurrentStreak(
                intakes: Array(allIntakes),
                dailyGoal: dailyGoal,
                context: modelContext
            )
            
            longestStreak = streakManager.calculateLongestStreak(
                intakes: Array(allIntakes),
                dailyGoal: dailyGoal,
                context: modelContext
            )
            
            goalCompletions = achievementManager.calculateGoalCompletions(
                intakes: Array(allIntakes),
                dailyGoal: dailyGoal,
                context: modelContext
            )
            
            // Check for new achievements
            let perfectDays = achievementManager.calculatePerfectDays(
                intakes: Array(allIntakes),
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
                print("🎉 \(newAchievements.count) new achievement(s) unlocked in AchievementsView!")
                
                // Show celebration for the first unlocked achievement
                if let firstAchievement = newAchievements.first {
                    print("🎊 Showing celebration for: \(firstAchievement.title)")
                    
                    await MainActor.run {
                        unlockedAchievement = firstAchievement
                        showingAchievementCelebration = true
                        print("✅ Celebration state set in AchievementsView - view should appear now")
                        
                        // Also send a notification
                        NotificationManager.shared.sendAchievementNotification(firstAchievement)
                    }
                }
            }
        }
    }
    
    /// Gets progress for an achievement
    private func getAchievementProgress(for definition: AchievementDefinition) -> (current: Int, total: Int)? {
        let achievementManager = AchievementManager.shared
        
        switch definition.category {
        case .streak:
            return (current: currentStreak, total: definition.requirement)
        case .goal:
            return (current: goalCompletions, total: definition.requirement)
        case .consistency:
            let perfectDays = achievementManager.calculatePerfectDays(
                intakes: Array(allIntakes),
                dailyGoal: dailyGoal,
                context: modelContext
            )
            return (current: perfectDays, total: definition.requirement)
        case .milestone:
            return nil
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AchievementCard: View {
    let definition: AchievementDefinition
    let isEarned: Bool
    let earnedDate: Date?
    let currentProgress: (current: Int, total: Int)?
    
    init(definition: AchievementDefinition, isEarned: Bool, earnedDate: Date?, currentProgress: (current: Int, total: Int)? = nil) {
        self.definition = definition
        self.isEarned = isEarned
        self.earnedDate = earnedDate
        self.currentProgress = currentProgress
    }
    
    private var progress: Double {
        guard let progress = currentProgress, !isEarned else { return 0 }
        return min(Double(progress.current) / Double(progress.total), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Group {
                if isEarned {
                    Image(systemName: definition.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                        .symbolEffect(.bounce, value: isEarned)
                } else {
                    Image(systemName: definition.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            
            Text(definition.title)
                .font(.caption)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(isEarned ? .primary : .secondary)
            
            if isEarned, let date = earnedDate {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if let progress = currentProgress, !isEarned {
                // Progress indicator
                VStack(spacing: 4) {
                    ProgressView(value: self.progress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                    
                    Text("\(progress.current)/\(progress.total)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .padding()
        .background(isEarned ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEarned ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: achievement.iconName)
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.title)
                        .bold()
                    
                    Text(achievement.achievementDescription)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Earned on:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(achievement.earnedDate, style: .date)
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [Achievement.self, WaterIntake.self, Settings.self])
}

