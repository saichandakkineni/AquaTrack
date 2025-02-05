import ActivityKit
import WidgetKit
import SwiftUI

struct WaterIntakeAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentIntake: Double
        var dailyGoal: Double
    }
}

struct WaterIntakeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WaterIntakeAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(Int(context.state.currentIntake))ml", systemImage: "drop.fill")
                        .foregroundStyle(.blue)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Label("Goal: \(Int(context.state.dailyGoal))ml", systemImage: "target")
                }
                
                DynamicIslandExpandedRegion(.center) {
                    ProgressView(value: context.state.currentIntake, total: context.state.dailyGoal)
                        .tint(.blue)
                }
            } compactLeading: {
                Label("\(Int(context.state.currentIntake))ml", systemImage: "drop.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text("\(Int(context.state.currentIntake / context.state.dailyGoal * 100))%")
            } minimal: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WaterIntakeAttributes>
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("Water Intake Progress")
                    .font(.headline)
            }
            
            ProgressView(value: context.state.currentIntake, total: context.state.dailyGoal)
                .tint(.blue)
            
            HStack {
                Text("\(Int(context.state.currentIntake))ml")
                Spacer()
                Text("Goal: \(Int(context.state.dailyGoal))ml")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
    }
} 