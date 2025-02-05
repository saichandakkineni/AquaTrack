import SwiftUI
import SwiftData

struct DailyTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    let todayIntakes: [WaterIntake]
    let dailyGoal: Double
    
    private let smallAmounts = [25.0, 50.0, 100.0]
    private let standardAmounts = [250.0, 500.0, 750.0]
    @State private var customAmount: Double = 0
    @State private var showingCustomInput = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blue, style: StrokeStyle(
                            lineWidth: 20,
                            lineCap: .round
                        ))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring, value: progress)
                    
                    VStack {
                        Text("\(Int(totalIntake))ml")
                            .font(.system(size: 36, weight: .bold))
                        Text("of \(Int(dailyGoal))ml")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 200)
                .padding()
                
                // Small Amount Buttons
                VStack(spacing: 10) {
                    Text("Quick Add - Small")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        ForEach(smallAmounts, id: \.self) { amount in
                            Button {
                                addWater(amount: amount)
                            } label: {
                                Text("+\(Int(amount))ml")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    HStack {
                        ForEach(smallAmounts, id: \.self) { amount in
                            Button {
                                decreaseWater(amount: amount)
                            } label: {
                                Text("-\(Int(amount))ml")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Standard Amount Buttons
                VStack(spacing: 10) {
                    Text("Quick Add - Standard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        ForEach(standardAmounts, id: \.self) { amount in
                            Button {
                                addWater(amount: amount)
                            } label: {
                                Text("+\(Int(amount))ml")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    HStack {
                        ForEach(standardAmounts, id: \.self) { amount in
                            Button {
                                decreaseWater(amount: amount)
                            } label: {
                                Text("-\(Int(amount))ml")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Button {
                    showingCustomInput = true
                } label: {
                    Text("Custom Amount")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Today's Intake")
            .sheet(isPresented: $showingCustomInput) {
                CustomAmountView { amount in
                    addWater(amount: amount)
                }
            }
        }
    }
    
    private var totalIntake: Double {
        todayIntakes.reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        min(totalIntake / dailyGoal, 1.0)
    }
    
    private func addWater(amount: Double) {
        let intake = WaterIntake(amount: amount)
        modelContext.insert(intake)
    }
    
    private func decreaseWater(amount: Double) {
        if totalIntake >= amount {
            let intake = WaterIntake(amount: -amount)
            modelContext.insert(intake)
            try? modelContext.save()
            Task {
                await WaterIntake.updateSharedDefaults()
            }
        }
    }
}

struct CustomAmountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount: Double = 0
    let onAdd: (Double) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount (ml)", value: $amount, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(amount)
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
} 