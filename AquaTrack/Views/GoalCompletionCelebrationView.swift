import SwiftUI
import AudioToolbox

struct GoalCompletionCelebrationView: View {
    let currentStreak: Int
    @Binding var isPresented: Bool
    @State private var showParticles = false
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Celebration content
            VStack(spacing: 30) {
                // Party popper emoji with animation
                ZStack {
                    // Multiple party poppers
                    ForEach(0..<12, id: \.self) { index in
                        let angle = Double(index) * 2 * .pi / 12
                        let radius: CGFloat = 200
                        Text("🎉")
                            .font(.system(size: 50))
                            .offset(
                                x: showParticles ? cos(angle) * radius : 0,
                                y: showParticles ? sin(angle) * radius : 0
                            )
                            .opacity(showParticles ? 0.2 : 1.0)
                            .scaleEffect(showParticles ? 0.2 : 1.2)
                    }
                    
                    // Additional confetti effect
                    ForEach(0..<6, id: \.self) { index in
                        let angle = Double(index) * 2 * .pi / 6 + .pi / 6
                        let radius: CGFloat = 180
                        Text("✨")
                            .font(.system(size: 40))
                            .offset(
                                x: showParticles ? cos(angle) * radius : 0,
                                y: showParticles ? sin(angle) * radius : 0
                            )
                            .opacity(showParticles ? 0.2 : 1.0)
                            .scaleEffect(showParticles ? 0.1 : 1.0)
                    }
                    
                    // Center goal icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                        .shadow(color: .green.opacity(0.8), radius: 20)
                }
                .frame(height: 250)
                
                VStack(spacing: 12) {
                    Text("Daily Goal Achieved!")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("Great job staying hydrated!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    if currentStreak > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(currentStreak) day streak!")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(25)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(20)
        }
        .onAppear {
            print("🎉 GoalCompletionCelebrationView appeared!")
            startCelebration()
        }
    }
    
    private func startCelebration() {
        print("🎊 Starting goal celebration animation and sound!")
        
        // Play celebration sound immediately
        playCelebrationSound()
        print("🔊 Celebration sound played")
        
        // Start rotation animation immediately
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Start icon scale animation immediately - bounce in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.2
        }
        
        // Then scale back to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
        
        // Small delay to ensure view is fully rendered before starting particle animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("🎈 Starting particle animation")
            
            // Animate party poppers with burst effect
            withAnimation(.spring(response: 0.6, dampingFraction: 0.3)) {
                showParticles = true
            }
        }
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print("⏰ Auto-dismissing goal celebration")
            dismiss()
        }
    }
    
    private func playCelebrationSound() {
        // Play multiple celebration sounds for a more festive effect
        AudioServicesPlaySystemSound(1016) // Success sound
        // Add a slight delay and play another sound for more impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AudioServicesPlaySystemSound(1057) // Another celebration sound
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

