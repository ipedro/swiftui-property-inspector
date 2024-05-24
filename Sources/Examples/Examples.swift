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

import PropertyInspector
import SwiftUI

#Preview(body: {
    PropertyInspector(listStyle: .plain) {
        VStack(content: {
            InspectableText(content: "Placeholder Text")
            InspectableButton(style: .bordered)
        })
        .propertyInspectorRowIcon(for: Any.self) { _ in
            Image(systemName: "list.bullet")
        }
        .propertyInspectorRowIcon(for: String.self) { _ in
            Image(systemName: "text.quote")
        }
        .propertyInspectorRowIcon(for: (any PrimitiveButtonStyle).self) { _ in
            Image(systemName: "button.vertical.right.press.fill")
        }
    }
})

struct InspectableText<S: StringProtocol>: View {
    var content: S

    var body: some View {
        Text(content).inspectProperty(content)
    }
}

struct InspectableButton<S: PrimitiveButtonStyle>: View {
    var style: S
    @State private var tapCount = 0

    var body: some View {
        Button("Tap Me") {
            tapCount += 1
        }
        .inspectProperty(style, "Tap Count: \(tapCount)")
        .buttonStyle(style)
    }
}
