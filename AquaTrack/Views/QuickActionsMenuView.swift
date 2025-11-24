import SwiftUI

struct QuickActionsMenuView: View {
    let mostUsedAmount: Double?
    let recentAmounts: [Double]
    let suggestedAmount: Double
    let onAdd: (Double) -> Void
    let onDecrease: ((Double) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        mostUsedAmount: Double?,
        recentAmounts: [Double],
        suggestedAmount: Double,
        onAdd: @escaping (Double) -> Void,
        onDecrease: ((Double) -> Void)? = nil
    ) {
        self.mostUsedAmount = mostUsedAmount
        self.recentAmounts = recentAmounts
        self.suggestedAmount = suggestedAmount
        self.onAdd = onAdd
        self.onDecrease = onDecrease
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let mostUsed = mostUsedAmount {
                    Section("Most Used") {
                        Button {
                            onAdd(mostUsed)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("\(Int(mostUsed))ml")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section("Smart Suggestions") {
                    Button {
                        onAdd(suggestedAmount)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                            Text("\(Int(suggestedAmount))ml")
                                .font(.headline)
                            Spacer()
                            Text("Time-based")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if !recentAmounts.isEmpty {
                    Section("Recent Amounts") {
                        ForEach(recentAmounts, id: \.self) { amount in
                            Button {
                                onAdd(amount)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("\(Int(amount))ml")
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Small Amounts") {
                    ForEach([25.0, 50.0, 100.0], id: \.self) { amount in
                        Button {
                            onAdd(amount)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(Int(amount))ml")
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section("Standard Amounts") {
                    ForEach([250.0, 500.0, 750.0], id: \.self) { amount in
                        Button {
                            onAdd(amount)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(Int(amount))ml")
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if let onDecrease = onDecrease {
                    Section("Decrease Intake") {
                        ForEach([100.0, 250.0, 500.0], id: \.self) { amount in
                            Button(role: .destructive) {
                                onDecrease(amount)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                    Text("\(Int(amount))ml")
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

