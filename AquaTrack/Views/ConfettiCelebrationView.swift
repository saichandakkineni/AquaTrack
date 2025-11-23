import SwiftUI
import AudioToolbox

struct ConfettiCelebrationView: View {
    let message: String
    let subtitle: String?
    @Binding var isPresented: Bool
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showMessage = false
    
    init(message: String, subtitle: String? = nil, isPresented: Binding<Bool>) {
        self.message = message
        self.subtitle = subtitle
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                // Confetti particles
                ForEach(confettiParticles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                }
                
                // Celebration message banner
                VStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text(message)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.95))
                            .shadow(radius: 10)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                    .scaleEffect(showMessage ? 1.0 : 0.8)
                    .opacity(showMessage ? 1.0 : 0.0)
                }
            }
        }
        .allowsHitTesting(false) // Allow touches to pass through
        .onChange(of: isPresented) { oldValue, newValue in
            if newValue {
                // Only start celebration when explicitly shown
                startCelebration()
            } else {
                // Clean up when hidden
                confettiParticles = []
                showMessage = false
            }
        }
    }
    
    private func startCelebration() {
        // Play celebration sound
        AudioServicesPlaySystemSound(1016)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AudioServicesPlaySystemSound(1057)
        }
        
        // Create confetti particles
        let emojis = ["🎉", "🎊", "✨", "🌟", "💫", "⭐"]
        confettiParticles = (0..<50).map { _ in
            ConfettiParticle(
                emoji: emojis.randomElement() ?? "🎉",
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -20
                ),
                size: CGFloat.random(in: 20...40),
                velocity: CGPoint(
                    x: CGFloat.random(in: -50...50),
                    y: CGFloat.random(in: 200...400)
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -180...180)
            )
        }
        
        // Show message with animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMessage = true
        }
        
        // Animate confetti falling
        animateConfetti()
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showMessage = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
            }
        }
    }
    
    private func animateConfetti() {
        // Store particle IDs to safely access them later
        let particleIds = confettiParticles.map { $0.id }
        
        // Animate each particle falling
        for particleId in particleIds {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2.0...3.5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Find particle by ID instead of index to avoid crashes
                guard let index = confettiParticles.firstIndex(where: { $0.id == particleId }),
                      index < confettiParticles.count else {
                    return // Particle was removed, skip animation
                }
                
                withAnimation(.linear(duration: duration)) {
                    confettiParticles[index].position.y = UIScreen.main.bounds.height + 100
                    confettiParticles[index].position.x += confettiParticles[index].velocity.x * CGFloat(duration)
                    confettiParticles[index].rotation += confettiParticles[index].rotationSpeed * duration
                }
                
                // Fade out as it falls
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.6) {
                    // Check again before accessing
                    guard let fadeIndex = confettiParticles.firstIndex(where: { $0.id == particleId }),
                          fadeIndex < confettiParticles.count else {
                        return // Particle was removed, skip fade
                    }
                    
                    withAnimation(.easeOut(duration: duration * 0.4)) {
                        confettiParticles[fadeIndex].opacity = 0
                    }
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var emoji: String
    var position: CGPoint
    var size: CGFloat
    var velocity: CGPoint
    var rotation: Double
    var rotationSpeed: Double
    var opacity: Double = 1.0
}

