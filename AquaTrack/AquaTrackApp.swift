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
                .onOpenURL { url in
                    // Handle widget quick add URLs
                    if url.scheme == "aquatrack" && url.host == "add",
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let amountString = components.queryItems?.first(where: { $0.name == "amount" })?.value,
                       let amount = Int(amountString) {
                        // Store pending water intake
                        if let sharedDefaults = UserDefaults(suiteName: "group.com.cmobautomation.AquaTrack") {
                            sharedDefaults.set(amount, forKey: "pendingWaterIntake")
                            sharedDefaults.synchronize()
                        }
                    }
                }
        }
        .modelContainer(appDelegate.container ?? createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        do {
            // Try using DatabaseManager for better error handling
            return try DatabaseManager.createContainer()
        } catch {
            // Log detailed error information
            print(String(repeating: "=", count: 50))
            print("ModelContainer Creation Error:")
            print("Error: \(error)")
            print("Error Description: \(error.localizedDescription)")
            print(String(repeating: "=", count: 50))
            
            // Check if it's a migration issue
            let errorString = "\(error)"
            if errorString.contains("migration") || errorString.contains("schema") || errorString.contains("version") {
                print("\n⚠️ Schema Migration Issue Detected")
                print("The database schema has changed. You may need to:")
                print("1. Delete the app from your device/simulator")
                print("2. Reinstall the app")
                print("3. Or the app will use in-memory storage (data won't persist)\n")
            }
            
            // Last resort: use in-memory storage
            do {
                print("Attempting to use in-memory storage as fallback...")
                return try ModelContainer(
                    for: WaterIntake.self, Settings.self, Achievement.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                // Only fatal error if even in-memory fails
                fatalError("""
                    Failed to create ModelContainer: \(error.localizedDescription)
                    
                    This is likely due to a schema migration issue.
                    
                    SOLUTION:
                    1. Delete the AquaTrack app from your device/simulator
                    2. Clean build folder in Xcode (Cmd+Shift+K)
                    3. Rebuild and run the app
                    
                    This will create a fresh database with the new schema.
                    """)
            }
        }
    }
}
