import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "drop.fill",
            title: "Track Your Hydration",
            description: "Easily log your daily water intake and stay on top of your hydration goals with a beautiful, intuitive interface.",
            color: .blue
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Visualize Your Progress",
            description: "See your hydration patterns with hourly breakdowns, weekly trends, and detailed history charts.",
            color: .green
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Earn Achievements",
            description: "Stay motivated with streaks, goal completions, and unlockable achievements as you build healthy habits.",
            color: .orange
        ),
        OnboardingPage(
            icon: "bell.fill",
            title: "Smart Reminders",
            description: "Get personalized reminders to drink water throughout the day, with quiet hours to respect your sleep.",
            color: .purple
        ),
        OnboardingPage(
            icon: "heart.text.square.fill",
            title: "Health App Integration",
            description: "Seamlessly sync your water intake data with Apple Health and import data from other hydration apps.",
            color: .pink
        ),
        OnboardingPage(
            icon: "square.grid.2x2.fill",
            title: "Widgets & Shortcuts",
            description: "Quickly add water from your home screen with widgets, or use Siri Shortcuts for hands-free logging.",
            color: .cyan
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.1),
                    pages[currentPage].color.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Page indicator and buttons
                VStack(spacing: 20) {
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 12 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(25)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack {
                                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                if currentPage < pages.count - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(pages[currentPage].color)
                            .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            isPresented = false
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon with animation
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Image(systemName: page.icon)
                    .font(.system(size: 70))
                    .foregroundColor(page.color)
            }
            .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            // Description
            Text(page.description)
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
                .lineSpacing(4)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

