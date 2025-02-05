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
    @Query private var intakes: [WaterIntake]
    @Query private var settings: [Settings]
    
    var body: some View {
        TabView {
            DailyTrackingView(
                todayIntakes: todayIntakes,
                dailyGoal: settings.first?.dailyGoal ?? 2000
            )
            .tabItem {
                Label("Today", systemImage: "drop.fill")
            }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
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
                    await WaterIntake.updateSharedDefaults()
                }
            case .inactive:
                try? modelContext.save()
            case .background:
                try? modelContext.save()
                Task {
                    await WaterIntake.updateSharedDefaults()
                }
            @unknown default:
                break
            }
        }
        .onAppear {
            if settings.isEmpty {
                let defaultSettings = Settings()
                modelContext.insert(defaultSettings)
            }
        }
    }
    
    private var todayIntakes: [WaterIntake] {
        intakes.filter { Calendar.current.isDateInToday($0.timestamp) }
    }
}

#Preview {
    ContentView()
}
