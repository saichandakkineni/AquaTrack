import SwiftUI
import HealthKit
import UIKit

struct HealthKitAuthView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isAuthorizing = false
    @State private var authorizationError: Error?
    @State private var isAuthorized: Bool = false
    @State private var isLoadingStatus = true
    @State private var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @State private var showingSettingsAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(isAuthorized ? .green : .blue)
                    
                    if isLoadingStatus {
                        ProgressView()
                            .padding()
                    } else if isAuthorized {
                        // Management View - Already Connected
                        VStack(spacing: 20) {
                            Text("Connected to Health")
                                .font(.title)
                                .bold()
                            
                            Text("AquaTrack is syncing your water intake data with the Health app.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Water intake data is being synced")
                                        .font(.subheadline)
                                }
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text("Data syncs automatically when you add water")
                                        .font(.subheadline)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            
                            Button(action: {
                                // Open Health app settings
                                if let settingsUrl = URL(string: "x-apple-health://") {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Open Health App Settings")
                                }
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            Text("To disconnect, go to Health app → Browse → Nutrition → Water → Data Sources & Access → AquaTrack → Delete All Data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        // Connection View - Not Connected
                        VStack(spacing: 20) {
                            Text("Connect to Health")
                                .font(.title)
                                .bold()
                            
                            if authorizationStatus == .sharingDenied {
                                // Previously denied - show instructions
                                VStack(spacing: 16) {
                                    Text("Health App access was previously denied.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                    
                                    Text("To enable Health App integration, please go to Settings and grant permission.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                    
                                    Button(action: {
                                        // Open iOS Settings for this app
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "gear")
                                            Text("Open Settings")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                    }
                                    
                                    Text("Then go to: Health → Data Access & Devices → AquaTrack → Turn on 'Water'")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            } else {
                                // Not yet requested or not determined
                                Text("AquaTrack can sync your water intake data with the Health app.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                
                                if let error = authorizationError {
                                    Text("Error: \(error.localizedDescription)")
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                
                                Button(action: {
                                    isAuthorizing = true
                                    authorizationError = nil
                                    Task {
                                        do {
                                            try await HealthKitManager.shared.requestAuthorization()
                                            // Check status after authorization
                                            await checkAuthorizationStatus()
                                        } catch {
                                            authorizationError = error
                                        }
                                        isAuthorizing = false
                                    }
                                }) {
                                    Text(isAuthorizing ? "Connecting..." : "Connect to Health")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                .disabled(isAuthorizing)
                            }
                            
                            Button("Not Now") {
                                dismiss()
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(isAuthorized ? "Health Integration" : "Connect to Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await checkAuthorizationStatus()
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() async {
        isLoadingStatus = true
        let status = HealthKitManager.shared.getDetailedAuthorizationStatus()
        let authorized = await HealthKitManager.shared.checkAuthorizationStatus()
        await MainActor.run {
            authorizationStatus = status
            isAuthorized = authorized
            isLoadingStatus = false
        }
    }
}

#Preview {
    HealthKitAuthView()
} 