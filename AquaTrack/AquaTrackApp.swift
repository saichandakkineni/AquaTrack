//
//  AquaTrackApp.swift
//  AquaTrack
//
//  Created by SAICHAND AKKINENI on 2025-01-27.
//

import SwiftUI
import SwiftData

@main
struct AquaTrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(appDelegate.container ?? {
            do {
                return try ModelContainer(for: WaterIntake.self, Settings.self)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }())
    }
}
