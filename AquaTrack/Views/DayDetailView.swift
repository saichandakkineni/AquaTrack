import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let intakes: [WaterIntake]
    
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [Settings]
    
    private var dailyGoal: Double {
        settings.first?.dailyGoal ?? 2000
    }
    
    private var totalAmount: Double {
        intakes.reduce(0) { $0 + $1.amount }
    }
    
    private var currentUnit: WaterUnit {
        settings.first?.unit ?? .milliliters
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let converted = WaterUnit.convert(amount, from: .milliliters, to: currentUnit)
        return "\(currentUnit.format(converted)) \(currentUnit.displayName)"
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Intake")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatAmount(totalAmount))
                            .font(.title)
                            .bold()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatAmount(dailyGoal))
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Entries") {
                if intakes.isEmpty {
                    Text("No entries for this day")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(intakes.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { intake in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatAmount(intake.amount))
                                    .font(.headline)
                                Text(intake.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if intake.amount > 0 {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(date.formatted(date: .long, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}

