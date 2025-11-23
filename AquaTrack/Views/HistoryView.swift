import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query private var intakes: [WaterIntake]
    @Environment(\.calendar) var calendar
    
    private var weeklyData: [(date: Date, amount: Double)] {
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        return calendar.generateDates(
            inside: DateInterval(start: startDate, end: endDate),
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        ).map { date in
            let dayIntakes = intakes.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let totalAmount = dayIntakes.reduce(0) { $0 + $1.amount }
            return (date: date, amount: totalAmount)
        }
    }
    
    var body: some View {
        NavigationStack {
            if groupedByDay().isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.5))
                    
                    Text("No History Yet")
                        .font(.title2)
                        .bold()
                    
                    Text("Start tracking your water intake to see your hydration history and trends over time.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("💡 Tip: Track consistently to unlock achievements and build streaks!")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("History")
            } else {
                List {
                    Section {
                        Chart(weeklyData, id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel(format: .dateTime.weekday())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                    } header: {
                        Text("Last 7 Days")
                    } footer: {
                        Text("Tap a day below to see details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        ForEach(groupedByDay(), id: \.date) { day in
                            NavigationLink {
                                DayDetailView(date: day.date, intakes: intakes.filter { calendar.isDate($0.timestamp, inSameDayAs: day.date) })
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.headline)
                                    Text("\(Int(day.amount))ml")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Daily History")
                    }
                }
                .navigationTitle("History")
            }
        }
    }
    
    private func groupedByDay() -> [(date: Date, amount: Double)] {
        let grouped = Dictionary(grouping: intakes) { intake in
            calendar.startOfDay(for: intake.timestamp)
        }
        return grouped.map { (date: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.date > $1.date }
    }
}

private extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(7) // For one week
        
        var date = interval.start
        while date <= interval.end {
            if let nextDate = self.nextDate(after: date, matching: components, matchingPolicy: .nextTime) {
                if nextDate <= interval.end {
                    dates.append(nextDate)
                }
                date = self.date(byAdding: .day, value: 1, to: nextDate)!
            } else {
                break
            }
        }
        return dates
    }
} 