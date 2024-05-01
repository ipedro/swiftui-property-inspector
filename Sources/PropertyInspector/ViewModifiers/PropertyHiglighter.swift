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
