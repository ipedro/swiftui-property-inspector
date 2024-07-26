import PropertyInspector
import SwiftUI

#Preview(body: {
    PropertyInspector(listStyle: .plain) {
        VStack(content: {
            InspectableText(content: "Placeholder Text")
            InspectableButton(style: .bordered)
        })
        .propertyInspectorRowLabel(for: Int.self, label: { data in
            Text("Tap count: \(data)")
        })
        .propertyInspectorRowIcon(for: Int.self, icon: { data in
            Image(systemName: "\(data).circle.fill")
        })
        .propertyInspectorRowIcon(for: String.self, icon: { _ in
            Image(systemName: "text.quote")
        })
        .propertyInspectorRowIcon(for: (any PrimitiveButtonStyle).self, icon: { _ in
            Image(systemName: "button.vertical.right.press.fill")
        })
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
        // inspecting multiple values with a single function call links their highlight behavior.
        .inspectProperty(style, tapCount)
        .buttonStyle(style)
    }
}
