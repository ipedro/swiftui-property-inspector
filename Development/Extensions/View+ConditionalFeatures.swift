import SwiftUI

extension View {
    @ViewBuilder
    func ios16_scrollBounceBehaviorBasedOnSize() -> some View {
        if #available(iOS 16.4, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

    @ViewBuilder
    func ios16_hideScrollIndicators(_ hide: Bool = true) -> some View {
        if #available(iOS 16.0, *) {
            scrollIndicators(hide ? .hidden : .automatic)
        } else {
            self
        }
    }

    @ViewBuilder
    func ios17_interpolateSymbolEffect() -> some View {
        if #available(iOS 17.0, *) {
            contentTransition(.symbolEffect(.automatic, options: .speed(2)))
        } else if #available(iOS 16.0, *) {
            contentTransition(.interpolate)
        } else {
            self
        }
    }
}
