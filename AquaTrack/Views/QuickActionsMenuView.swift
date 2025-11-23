import SwiftUI

struct QuickActionsMenuView: View {
    let mostUsedAmount: Double?
    let recentAmounts: [Double]
    let suggestedAmount: Double
    let onAdd: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if let mostUsed = mostUsedAmount {
                    Section("Most Used") {
                        Button {
                            onAdd(mostUsed)
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
                
                Section("Suggested") {
                    Button {
                        onAdd(suggestedAmount)
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                            Text("\(Int(suggestedAmount))ml")
                                .font(.headline)
                            Spacer()
                            Text("Based on time & progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if !recentAmounts.isEmpty {
                    Section("Recent") {
                        ForEach(recentAmounts, id: \.self) { amount in
                            Button {
                                onAdd(amount)
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
                
                Section("Quick Add") {
                    ForEach([100.0, 250.0, 500.0, 750.0], id: \.self) { amount in
                        Button {
                            onAdd(amount)
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
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

