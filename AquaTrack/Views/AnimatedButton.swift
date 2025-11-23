import SwiftUI

struct AnimatedButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    let hapticStyle: HapticStyle
    
    @State private var isPressed = false
    
    enum HapticStyle {
        case light
        case medium
        case heavy
        case success
        case none
    }
    
    init(
        hapticStyle: HapticStyle = .light,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.label = label
        self.hapticStyle = hapticStyle
    }
    
    var body: some View {
        Button(action: {
            // Trigger haptic feedback
            triggerHaptic()
            
            // Execute action
            action()
        }) {
            label()
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    private func triggerHaptic() {
        switch hapticStyle {
        case .light:
            HapticManager.shared.lightImpact()
        case .medium:
            HapticManager.shared.mediumImpact()
        case .heavy:
            HapticManager.shared.heavyImpact()
        case .success:
            HapticManager.shared.success()
        case .none:
            break
        }
    }
}

