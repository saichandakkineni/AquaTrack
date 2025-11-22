import SwiftUI
import SwiftData
import Charts

struct HourlyBreakdownView: View {
    @Query(sort: \WaterIntake.timestamp, order: .reverse) private var allIntakes: [WaterIntake]
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    
    private var todayIntakes: [WaterIntake] {
        let calendar = Calendar.current
        return allIntakes.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    private var hourlyData: [(hour: Int, amount: Double)] {
        let calendar = Calendar.current
        var hourlyTotals: [Int: Double] = [:]
        
        // Initialize all 24 hours with 0
        for hour in 0..<24 {
            hourlyTotals[hour] = 0
        }
        
        // Sum intakes by hour
        for intake in todayIntakes {
            let hour = calendar.component(.hour, from: intake.timestamp)
            hourlyTotals[hour, default: 0] += intake.amount
        }
        
        // Convert to array and sort
        return hourlyTotals.map { (hour: $0.key, amount: $0.value) }
            .sorted { $0.hour < $1.hour }
    }
    
    private var currentUnit: WaterUnit {
        settings.first?.unit ?? .milliliters
    }
    
    private var maxHourlyAmount: Double {
        let maxAmount = hourlyData.map { $0.amount }.max() ?? 0
        return max(maxAmount, 1) // Ensure at least 1 to avoid division by zero
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if hourlyData.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No intake data for today")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Start tracking your water intake to see hourly breakdown")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Summary Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Summary")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Intake")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(UnitConverter.shared.convertAndFormat(
                                        todayIntakes.reduce(0) { $0 + $1.amount },
                                        from: .milliliters,
                                        to: currentUnit
                                    ))
                                    .font(.title2)
                                    .bold()
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Entries")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(todayIntakes.count)")
                                        .font(.title2)
                                        .bold()
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Hourly Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hourly Breakdown")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                Chart {
                                    ForEach(hourlyData, id: \.hour) { data in
                                        BarMark(
                                            x: .value("Hour", data.hour),
                                            y: .value("Amount", WaterUnit.convert(data.amount, from: .milliliters, to: currentUnit))
                                        )
                                        .foregroundStyle(Color.blue.gradient)
                                        .cornerRadius(4)
                                    }
                                }
                                .frame(height: 250)
                                .frame(minWidth: 600) // Ensure enough width for all hours
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let doubleValue = value.as(Double.self) {
                                                Text(currentUnit.format(doubleValue))
                                                    .font(.caption2)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: 2)) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                        AxisValueLabel {
                                            if let hourValue = value.as(Int.self) {
                                                Text(formatHourForChart(hourValue))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Hourly List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detailed View")
                                .font(.headline)
                            
                            ForEach(hourlyData, id: \.hour) { data in
                                if data.amount > 0 {
                                    HStack {
                                        Text(formatHour(data.hour))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .frame(width: 60, alignment: .leading)
                                        
                                        ProgressView(value: data.amount, total: max(maxHourlyAmount, 1))
                                            .tint(.blue)
                                        
                                        Text(UnitConverter.shared.convertAndFormat(
                                            data.amount,
                                            from: .milliliters,
                                            to: currentUnit
                                        ))
                                        .font(.subheadline)
                                        .bold()
                                        .frame(width: 80, alignment: .trailing)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            if hourlyData.allSatisfy({ $0.amount == 0 }) {
                                Text("No intake recorded yet today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Hourly Breakdown")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        // Create a date with the specified hour
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        components.second = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date).lowercased()
    }
    
    /// Formats hour for chart display - shows every 2 hours with better formatting
    private func formatHourForChart(_ hour: Int) -> String {
        let formatter = DateFormatter()
        // Use shorter format: "12a", "2p", etc.
        if hour == 0 {
            return "12a"
        } else if hour < 12 {
            return "\(hour)a"
        } else if hour == 12 {
            return "12p"
        } else {
            return "\(hour - 12)p"
        }
    }
}

#Preview {
    HourlyBreakdownView()
        .modelContainer(for: [WaterIntake.self, Settings.self])
}

