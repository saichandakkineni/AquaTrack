//
//  ContentView.swift
//  AquaTrack
//
//  Created by SAICHAND AKKINENI on 2025-01-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \WaterIntake.timestamp, order: .reverse) private var allIntakes: [WaterIntake]
    @Query private var settings: [Settings]
    
    // Optimized: Computed property that filters only today's intakes
    // This is more efficient than filtering all intakes on every render
    private var todayIntakes: [WaterIntake] {
        let calendar = Calendar.current
        let today = Date()
        return allIntakes.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    var body: some View {
        TabView {
            DailyTrackingView(
                todayIntakes: todayIntakes,
                dailyGoal: settings.first?.dailyGoal ?? 2000
            )
            .tabItem {
                Label("Today", systemImage: "drop.fill")
            }
            
            HourlyBreakdownView()
                .tabItem {
                    Label("Hourly", systemImage: "clock.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
            
            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
                Task {
                    await WaterIntake.updateSharedDefaults(context: modelContext)
                }
            case .inactive:
                try? modelContext.save()
            case .background:
                try? modelContext.save()
                Task {
                    await WaterIntake.updateSharedDefaults(context: modelContext)
                }
            @unknown default:
                break
            }
        }
        .onAppear {
            if settings.isEmpty {
                let defaultSettings = Settings()
                modelContext.insert(defaultSettings)
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    ContentView()
}
