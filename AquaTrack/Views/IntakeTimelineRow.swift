import SwiftUI

struct IntakeTimelineRow: View {
    let intake: WaterIntake
    let onDelete: () -> Void
    let formatAmount: (Double) -> String
    
    @State private var offset: CGFloat = 0
    @State private var isDeleting = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: intake.timestamp)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack {
                Circle()
                    .fill(intake.amount > 0 ? Color.blue : Color.red)
                    .frame(width: 8, height: 8)
                if intake.amount < 0 {
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            
            // Content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatAmount(abs(intake.amount)))
                        .font(.headline)
                        .foregroundColor(intake.amount > 0 ? .primary : .red)
                    
                    Text(timeString)
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
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.width < 0 {
                        offset = value.translation.width
                    }
                }
                .onEnded { value in
                    if value.translation.width < -100 {
                        // Swipe to delete
                        withAnimation(.spring()) {
                            offset = -UIScreen.main.bounds.width
                            isDeleting = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
        )
    }
}

