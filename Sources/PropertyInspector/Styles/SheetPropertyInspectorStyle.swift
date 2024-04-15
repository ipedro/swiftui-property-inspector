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

// MARK: - Sheet Style

public enum PropertyInspectorHighlightBehavior: String, CaseIterable {
    case manual = "Manual"
    case automatic = "Show / Hide Automatically"
    case hideOnDismiss = "Hide Automatically"
}

// MARK: - Sheet Style

/**
 `SheetPropertyInspectorStyle` provides a SwiftUI view modifier that applies a sheet-style presentation to property inspectors.

 This style organizes properties within a customizable list, using specified list styles and row backgrounds, making it ideal for detailed inspections in a modal sheet format.

 - Parameters:
   - `isPresented`: A binding to a Boolean value that indicates whether the property inspector sheet is presented.
   - `listStyle`: The style of the list used within the sheet, conforming to `ListStyle`.
   - `listRowBackground`: The view used as the background for each row in the list, conforming to `View`.
   - `title`: An optional title for the sheet; if not provided, defaults to `nil`.

 - Returns: A view modifier that configures the appearance and behavior of a property inspector using the specified sheet style.

 ## Usage

 You don't instantiate `SheetPropertyInspectorStyle` directly, instead use one of the convenience initializers in ``PropertyInspector``. 
 Here’s how you might configure and present a property inspector with a sheet style:

 ```swift
 @State private var isPresented = false

 var body: some View {
     PropertyInspector(
         "Optional Title",
         isPresented: $isPresented,
         listStyle: .plain, // optional
         label: {
             // your app, flows, screens, components, your choice
             MyFeatureScreen()
         }
     )
 }
 ```

 ## Performance Considerations
 Utilizing complex views as `listRowBackground` may impact performance, especially with larger lists.

 - Note: Requires iOS 16.4 or newer due to specific SwiftUI features utilized.

 - seeAlso: ``ListPropertyInspectorStyle`` and ``InlinePropertyInspectorStyle``.
 */
@available(iOS 16.4, *)
public struct SheetPropertyInspectorStyle<Style: ListStyle, RowBackground: View>: _PropertyInspectorStyle {
    var title: String?

    @Binding
    var isPresented: Bool

    var listStyle: Style

    var listRowBackground: RowBackground?

    @EnvironmentObject
    private var data: Context
    
    @AppStorage("HighlightBehavior")
    private var highlight = PropertyInspectorHighlightBehavior.manual

    @State
    private var contentHeight: Double = .zero

    public func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                Spacer().frame(height: isPresented ? contentHeight : .zero)
            }
            .toolbar {
                SheetToolbarContent(
                    isPresented: $isPresented,
                    highlight: $highlight
                )
            }
            .animation(
                .interpolatingSpring,
                value: isPresented
            )
            .modifier(
                SheetPresentationModifier(
                    isPresented: $isPresented,
                    height: $contentHeight,
                    label: EmptyView().modifier(
                        ListPropertyInspectorStyle(
                            title: title,
                            listStyle: listStyle,
                            listRowBackground: listRowBackground,
                            contentPadding: false
                        )
                    )
                )
            )
            .onChange(of: isPresented) { newValue in
                DispatchQueue.main.async {
                    updateHighlightIfNeeded(newValue)
                }
            }
    }

    private func updateHighlightIfNeeded(_ isPresented: Bool) {
        let newValue: Bool

        switch highlight {
        case .automatic: newValue = isPresented
        case .hideOnDismiss where !isPresented: newValue = false
        default: return
        }

        data.allObjects.forEach { property in
            property.isHighlighted = newValue
        }
    }
}

@available(iOS 16.4, *)
private struct SheetPresentationModifier<Label: View>: ViewModifier {
    @Binding
    var isPresented: Bool

    @Binding
    var height: Double

    var label: Label

    @State
    private var selection: PresentationDetent = SheetPresentationModifier.detents[1]

    private static var detents: [PresentationDetent] { [
        .fraction(0.25),
        .fraction(0.45),
        .fraction(0.65),
        .large
    ] }

    func body(content: Content) -> some View {
        content.overlay {
            Spacer().sheet(isPresented: $isPresented) {
                label
                    .scrollContentBackground(.hidden)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationContentInteraction(.scrolls)
                    .presentationCornerRadius(20)
                    .presentationBackground(Material.thinMaterial)
                    .presentationDetents(Set(SheetPresentationModifier.detents), selection: $selection)
                    .background(GeometryReader { proxy in
                        Color.clear.onChange(of: proxy.size.height) { newValue in
                            let newInset = ceil(newValue)
                            if height != newInset {
                                height = newInset
                            }
                        }
                    })
            }
        }
    }
}

private struct SheetToolbarContent: View {
    @Binding
    var isPresented: Bool

    @Binding
    var highlight: PropertyInspectorHighlightBehavior

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            isPresented.toggle()
        } label: {
            Image(systemName: "\(isPresented ? "xmark" : "magnifyingglass").circle.fill")
                .rotationEffect(.radians(isPresented ? -.pi : .zero))
                .font(.title3)
                .padding()
                .contextMenu(menuItems: menuItems)
        }
        .symbolRenderingMode(.hierarchical)
    }

    @ViewBuilder
    private func menuItems() -> some View {
        let title = "Highlight Behavior"
        Text(title)
        Divider()
        Picker(title, selection: $highlight) {
            ForEach(PropertyInspectorHighlightBehavior.allCases, id: \.hashValue) { behavior in
                Button(behavior.rawValue) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    highlight = behavior
                }
                .tag(behavior)
            }
        }
    }
}
