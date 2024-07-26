import SwiftUI

struct PropertyHiglighter: ViewModifier  {
    @Binding var isOn: Bool

    func body(content: Content) -> some View {
        content
            .zIndex(isOn ? 999 : 0)
            .overlay {
                if isOn {
                    Rectangle()
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

    private var insertion: AnyTransition {
        .opacity
        .combined(with: .scale(scale: .random(in: 2 ... 2.5)))
        .animation(insertionAnimation)
    }

    private var removal: AnyTransition {
        .opacity
        .combined(with: .scale(scale: .random(in: 1.1 ... 1.4)))
        .animation(removalAnimation)
    }

    private var removalAnimation: Animation {
        .smooth(duration: .random(in: 0.1...0.35))
        .delay(.random(in: 0 ... 0.15))
    }

    private var insertionAnimation: Animation {
        .snappy(
            duration: .random(in: 0.2 ... 0.5),
            extraBounce: .random(in: 0 ... 0.1))
        .delay(.random(in: 0 ... 0.3))
    }
}
