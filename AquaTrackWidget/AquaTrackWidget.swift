import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WaterEntry {
        WaterEntry(date: Date(), intake: 0, goal: 2000)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> ()) {
        let entry = WaterEntry(date: Date(), intake: 1500, goal: 2000)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        // Get data from shared container
        let sharedDefaults = UserDefaults(suiteName: "group.com.cmobautomation.AquaTrack")
        let intake = sharedDefaults?.double(forKey: "todayIntake") ?? 0
        let goal = sharedDefaults?.double(forKey: "dailyGoal") ?? 2000
        
        let entry = WaterEntry(date: currentDate, intake: intake, goal: goal)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct WaterEntry: TimelineEntry {
    let date: Date
    let intake: Double
    let goal: Double
}

struct AquaTrackWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            CircularProgressView(entry: entry)
        case .systemMedium:
            HStack {
                CircularProgressView(entry: entry)
                VStack(alignment: .leading) {
                    Text("Today's Progress")
                        .font(.headline)
                    ProgressView(value: entry.intake, total: entry.goal)
                        .tint(.blue)
                    Text("\(Int(entry.intake))ml of \(Int(entry.goal))ml")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        case .systemLarge:
            VStack {
                CircularProgressView(entry: entry)
                    .frame(height: 200)
                DailyProgressChart(entry: entry)
            }
            .padding()
        case .accessoryCircular:
            ZStack {
                Gauge(value: entry.intake, in: 0...entry.goal) {
                    Image(systemName: "drop.fill")
                } currentValueLabel: {
                    Text("\(Int(entry.intake / entry.goal * 100))%")
                }
                .gaugeStyle(.accessoryCircular)
            }
        default:
            CircularProgressView(entry: entry)
        }
    }
}

struct CircularProgressView: View {
    let entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: min(entry.intake / entry.goal, 1.0))
                .stroke(Color.blue, style: StrokeStyle(
                    lineWidth: 10,
                    lineCap: .round
                ))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: entry.intake)
            
            VStack {
                Text("\(Int(entry.intake))ml")
                    .font(.system(size: 20, weight: .bold))
                Text("of \(Int(entry.goal))ml")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DailyProgressChart: View {
    let entry: Provider.Entry
    
    var body: some View {
        Chart {
            BarMark(
                x: .value("Time", entry.date),
                y: .value("Intake", entry.intake)
            )
            .foregroundStyle(.blue.gradient)
            
            RuleMark(
                y: .value("Goal", entry.goal)
            )
            .foregroundStyle(.red)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .annotation(position: .leading) {
                Text("Goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 150)
    }
}

@main
struct AquaTrackWidget: Widget {
    let kind: String = "AquaTrackWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AquaTrackWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Water Intake")
        .description("Track your daily water intake")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular
        ])
    }
} 