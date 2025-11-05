import SwiftUI

struct PropertyHiglighter<S: Shape>: ViewModifier {
    @Binding var isOn: Bool
    var shape: S

    func body(content: Content) -> some View {
        // 🎨 Random animation values for dynamic visual variety
        // Generated in body() because SwiftUI views (structs) are init'd/destroyed frequently
        // but body is only recomputed when dependencies change, making this more efficient
        // Creates staggered effect when multiple properties highlight simultaneously
        let insertionScale = Double.random(in: 2...2.5)
        let removalScale = Double.random(in: 1.1...1.4)
        let removalDuration = Double.random(in: 0.1...0.35)
        let removalDelay = Double.random(in: 0...0.15)
        let insertionDuration = Double.random(in: 0.2...0.5)
        let insertionBounce = Double.random(in: 0...0.1)
        let insertionDelay = Double.random(in: 0...0.3)
        
        let insertionAnimation = Animation.snappy(
            duration: insertionDuration,
            extraBounce: insertionBounce
        ).delay(insertionDelay)
        
        let removalAnimation = Animation.smooth(duration: removalDuration)
            .delay(removalDelay)
        
        let insertion = AnyTransition.opacity
            .combined(with: .scale(scale: insertionScale))
            .animation(insertionAnimation)
        
        let removal = AnyTransition.opacity
            .combined(with: .scale(scale: removalScale))
            .animation(removalAnimation)
        
        return content
            .zIndex(isOn ? 999 : 0)
            .overlay {
                if isOn {
                    shape
                        .stroke(lineWidth: 1.5)
                        .fill(.cyan.opacity(isOn ? 1 : 0))
                        .transition(
                            .asymmetric(
                                insertion: insertion,
                                removal: removal
                            )
                        )
                }
            }
    }
}
