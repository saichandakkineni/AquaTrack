import Foundation
import SwiftData

/// Manages database operations and migrations
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private init() {}
    
    /// Creates a ModelContainer with proper error handling and migration support
    static func createContainer() throws -> ModelContainer {
        do {
            // First attempt: standard creation
            return try ModelContainer(for: WaterIntake.self, Settings.self, Achievement.self)
        } catch {
            print("Initial ModelContainer creation failed: \(error.localizedDescription)")
            
            // Second attempt: with explicit schema
            do {
                let schema = Schema([
                    WaterIntake.self,
                    Settings.self,
                    Achievement.self
                ])
                
                let config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                print("Schema-based creation failed: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// Attempts to reset the database by deleting old files
    /// Note: This should only be used as a last resort
    static func resetDatabase() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        
        guard let appSupportURL = urls.first else { return }
        
        // SwiftData stores its database in the app support directory
        let databaseURL = appSupportURL.appendingPathComponent("default.store")
        let databaseShmURL = appSupportURL.appendingPathComponent("default.store-shm")
        let databaseWalURL = appSupportURL.appendingPathComponent("default.store-wal")
        
        // Delete database files
        try? fileManager.removeItem(at: databaseURL)
        try? fileManager.removeItem(at: databaseShmURL)
        try? fileManager.removeItem(at: databaseWalURL)
        
        print("Database files deleted. App will need to be restarted.")
    }
}

