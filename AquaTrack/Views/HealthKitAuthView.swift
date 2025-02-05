import SwiftUI
import HealthKit

struct HealthKitAuthView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isAuthorizing = false
    @State private var authorizationError: Error?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Connect to Health")
                    .font(.title)
                    .bold()
                
                Text("AquaTrack can sync your water intake data with the Health app.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if let error = authorizationError {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    isAuthorizing = true
                    Task {
                        do {
                            try await HealthKitManager.shared.requestAuthorization()
                            dismiss()
                        } catch {
                            authorizationError = error
                        }
                        isAuthorizing = false
                    }
                }) {
                    Text("Connect to Health")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isAuthorizing)
                
                Button("Not Now") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    HealthKitAuthView()
} 