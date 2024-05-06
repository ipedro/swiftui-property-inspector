//  Copyright (c) 2024 Pedro Almeida
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import SwiftUI

struct PropertyToggleStyle: ToggleStyle {
    var alignment: VerticalAlignment = .center
    var animation: Animation? = .snappy(duration: 0.3)
    var impact: UIImpactFeedbackGenerator = .init(style: .light)
    var impactIntensity: CGFloat = 1.0

    func makeBody(configuration: Configuration) -> some View {
        Button {
            impact.impactOccurred(intensity: impactIntensity)
            withAnimation(animation) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(alignment: alignment) {
                configuration.label

                Spacer()
                
                Image(systemName: imageName(configuration._state))
                    .font(.headline)
                    .tint(.accentColor)
                    .ios17_interpolateSymbolEffect(value: configuration._state)
            }
            .animation(animation, value: configuration._state)
        }
    }

    private func imageName(_ state: Configuration._State) -> String {
        switch state {
        case .mixed: "checkmark.circle"
        case .on:    "checkmark.circle.fill"
        case .off:   "circle"
        }
    }
}

private extension View {
    @ViewBuilder
    func ios17_interpolateSymbolEffect<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            self.contentTransition(.interpolate).symbolEffect(
                .bounce.byLayer.down,
                options: .speed(1.5),
                value: value
            )
        } else if #available(iOS 16.0, *) {
            // Fallback on earlier versions
            self.contentTransition(.interpolate)
        } else {
            self
        }
    }
}

extension ToggleStyleConfiguration {
    enum _State {
        case off, mixed, on
    }

    var _state: _State {
        if #available(iOS 16.0, *), isMixed { return .mixed }
        if isOn { return .on }
        return .off
    }
}
