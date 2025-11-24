import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query private var intakes: [WaterIntake]
    @Query private var settings: [Settings]
    @Environment(\.calendar) var calendar
    
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }
    
    private var dailyGoal: Double {
        settings.first?.dailyGoal ?? 2000
    }
    
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
    
    private var monthlyData: [(date: Date, amount: Double)] {
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        // Group by week for monthly view
        var weeklyTotals: [Date: Double] = [:]
        let grouped = Dictionary(grouping: intakes.filter { $0.timestamp >= startDate }) { intake in
            calendar.startOfWeek(for: intake.timestamp)
        }
        
        for (weekStart, weekIntakes) in grouped {
            let total = weekIntakes.reduce(0) { $0 + $1.amount }
            weeklyTotals[weekStart] = total
        }
        
        return weeklyTotals.map { (date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private var currentPeriodData: [(date: Date, amount: Double)] {
        selectedPeriod == .week ? weeklyData : monthlyData
    }
    
    private var averageIntake: Double {
        let data = currentPeriodData.map { $0.amount }
        guard !data.isEmpty else { return 0 }
        return data.reduce(0, +) / Double(data.count)
    }
    
    private var previousPeriodAverage: Double {
        let days = selectedPeriod == .week ? 7 : 30
        let previousStart = calendar.date(byAdding: .day, value: -(days * 2), to: Date())!
        let previousEnd = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let previousIntakes = intakes.filter { intake in
            intake.timestamp >= previousStart && intake.timestamp < previousEnd
        }
        
        let grouped = Dictionary(grouping: previousIntakes) { intake in
            calendar.startOfDay(for: intake.timestamp)
        }
        
        let dailyTotals = grouped.map { $0.value.reduce(0) { $0 + $1.amount } }
        guard !dailyTotals.isEmpty else { return 0 }
        return dailyTotals.reduce(0, +) / Double(dailyTotals.count)
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
                    // Period Selector
                    Section {
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Stats Card
                    Section {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Average")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(averageIntake))ml")
                                    .font(.title2)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            if previousPeriodAverage > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("vs Previous")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        Image(systemName: averageIntake >= previousPeriodAverage ? "arrow.up" : "arrow.down")
                                            .foregroundColor(averageIntake >= previousPeriodAverage ? .green : .red)
                                        Text("\(Int(abs(averageIntake - previousPeriodAverage)))ml")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(averageIntake >= previousPeriodAverage ? .green : .red)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Chart Section
                    Section {
                        Chart(currentPeriodData, id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: selectedPeriod == .week ? .day : .weekOfYear),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            .cornerRadius(4)
                            
                            // Goal line
                            RuleMark(y: .value("Goal", dailyGoal))
                                .foregroundStyle(.red.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                if selectedPeriod == .week {
                                    AxisValueLabel(format: .dateTime.weekday())
                                } else {
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                    } header: {
                        Text(selectedPeriod == .week ? "Last 7 Days" : "Last 30 Days (by Week)")
                    } footer: {
                        Text("Tap a day below to see details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Daily History
                    Section {
                        ForEach(groupedByDay(), id: \.date) { day in
                            NavigationLink {
                                DayDetailView(date: day.date, intakes: intakes.filter { calendar.isDate($0.timestamp, inSameDayAs: day.date) })
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.headline)
                                        Text("\(Int(day.amount))ml")
                                            .foregroundStyle(.secondary)
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    // Progress indicator
                                    if day.amount >= dailyGoal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Circle()
                                            .fill(Color.blue.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
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
    
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
} 