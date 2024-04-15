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

/**
 A `PropertyInspector` struct provides a customizable interface for inspecting properties within a SwiftUI view.

 The `PropertyInspector` is designed to display detailed information about properties, ideal for debugging purposes, configuration settings, or presenting detailed data about objects in a clear and organized manner. It leverages generics to support various content and styling options, making it a versatile tool for building dynamic and informative user interfaces.

 ## Usage

 The `PropertyInspector` is typically initialized with a label and a style. The label defines the content that will be displayed, while the style dictates how this content is presented. Below is an example of how to instantiate and use a `PropertyInspector` with a custom style and label:

 ```swift
 struct ContentView: View {
     var body: some View {
         PropertyInspector("User Details", label: {
             VStack(alignment: .leading) {
                 Text("Username: user123")
                 Text("Status: Active")
             }
         })
     }
 }
 ```

 - Note: The `PropertyInspector` is a generic struct that requires specifying a view type for its label and a style type. It does not manage state internally but relies on the surrounding environment to provide and manage the data it displays.

 - seeAlso: ``inspectProperty(_:function:line:file:)``, ``propertyInspectorHidden()``, and ``inspectSelf()``
 */
public struct PropertyInspector<Label: View, Style: _PropertyInspectorStyle>: View {
    /**
     Initializes property inspector presented as a sheet with minimal styling.

     This initializer sets up a property inspector presented as a sheet using [PlainListStyle](https://developer.apple.com/documentation/swiftui/plainliststyle) and a clear background. It's useful for cases where a straightforward list display is needed without additional styling complications.

     - Parameters:
       - title: An optional title for the sheet; if not provided, defaults to `nil`.
       - isPresented: A binding to a Boolean value that controls the presentation state of the sheet.
       - label: A closure that returns the content to be displayed within the sheet.

     - Returns: An instance of `PropertyInspector` configured to display as a sheet with plain list style and translucent background material.

     ## Usage Example

     ```swift
     @State 
     private var isPresented = false

     var body: some View {
         PropertyInspector("Settings", isPresented: $isPresented) {
             MyView() // Replace with your content
         }
     }
     ```

     - seeAlso: ``PropertyInspector/init(_:isPresented:listStyle:listRowBackground:label:)`` for more customized sheet styles.
    */
    @available(iOS 16.4, *)
    public init(
        _ title: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) where Style == SheetPropertyInspectorStyle<PlainListStyle, Color> {
        self.label = label()
        self.style = SheetPropertyInspectorStyle(
            title: title,
            isPresented: isPresented,
            listStyle: .plain,
            listRowBackground: .clear
        )
    }

    /**
     Initializes a `PropertyInspector` with a configurable sheet style based on specified list and background settings.

     This initializer allows for a flexible configuration of the sheet presentation of a property inspector, providing the ability to customize the list style and the background color of list rows. It's designed to be used when you need to match the inspector's styling closely with your app's design language.

     - Parameters:
       - title: An optional title for the sheet; if not provided, defaults to `nil`.
       - isPresented: A binding to a Boolean value that controls the presentation state of the sheet. This value should be managed by the view that triggers the inspector to show or hide.
       - listStyle: The style of the list used within the sheet, conforming to `ListStyle`. This parameter allows you to use any list style available in SwiftUI, such as `.plain`, `.grouped`, `.insetGrouped`, etc.
       - listRowBackground: An optional color to use for the background of each row in the list. Defaults to `nil`, which will not apply any background color unless specified.
       - label: A closure that returns the content to be displayed within the sheet. This view builder allows for dynamic content creation, enabling the use of custom views as content.

     ## Usage Example

     ```swift
     @State private var isPresented = false

     var body: some View {
         PropertyInspector(
             "Detailed Settings",
             isPresented: $isPresented,
             listStyle: .insetGrouped) {
                 MyView() // Replace with your content
             }
         }
     }
     ```
     - seeAlso: ``init(_:isPresented:label:)`` for a simpler, default styling setup, or ``init(_:isPresented:listStyle:listRowBackground:label:)`` for variations with more specific list styles.
     */
    @available(iOS 16.4, *)
    public init<L: ListStyle>(
        _ title: String? = nil,
        isPresented: Binding<Bool>,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == SheetPropertyInspectorStyle<L, Color> {
        self.label = label()
        self.style = SheetPropertyInspectorStyle(
            title: title,
            isPresented: isPresented,
            listStyle: listStyle,
            listRowBackground: listRowBackground
        )
    }

    /**
     Initializes a `PropertyInspector` with a customizable list style, suitable for detailed and integrated list presentations.

     This initializer allows for the customization of the list's appearance within a `PropertyInspector`, making it ideal for applications where the inspector needs to be seamlessly integrated within a broader UI context, or where specific styling of list items is required.

     - Parameters:
       - title: An optional title for the list; if not provided, defaults to `nil`. This title is displayed at the top of the list and can be used to provide context or headings to the user.
       - listStyle: The style of the list used within the inspector, conforming to `ListStyle`. This parameter allows for significant visual customization of the list, supporting all styles provided by SwiftUI, such as `.plain`, `.grouped`, `.insetGrouped`, etc.
       - listRowBackground: An optional color to use for the background of each row in the list. If `nil`, the default background color for the list style is used.
       - label: A closure that returns the content to be displayed within the list. This is typically where you would compose the view elements that make up the content of the inspector.

     ## Usage Example

     ```swift
     var body: some View {
         PropertyInspector("User Preferences", listStyle: .grouped) {
             MyView() // Replace with your content
         }
     }
     ```

     - seeAlso: ``init(_:isPresented:listStyle:listRowBackground:label:)`` for a version of this initializer that supports modal presentation with `isPresented` binding.
     */
    public init<L: ListStyle>(
        _ title: String? = nil,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == ListPropertyInspectorStyle<L, Color> {
        self.label = label()
        self.style = ListPropertyInspectorStyle(
            title: title,
            listStyle: listStyle,
            listRowBackground: listRowBackground,
            contentPadding: true
        )
    }

    /**
     Initializes a `PropertyInspector` with a customizable list style, suitable for detailed and integrated list presentations.

     This initializer allows for the customization of the list's appearance within a `PropertyInspector`, making it ideal for applications where the inspector needs to be seamlessly integrated within a broader UI context, or where specific styling of list items is required.

     - Parameters:
       - title: An optional title for the list; if not provided, defaults to `nil`. This title is displayed at the top of the list and can be used to provide context or headings to the user.
       - listStyle: The style of the list used within the inspector, conforming to `ListStyle`. This parameter allows for significant visual customization of the list, supporting all styles provided by SwiftUI, such as `.plain`, `.grouped`, `.insetGrouped`, etc.
       - listRowBackground: An optional view to use for the background of each row in the list. If `nil`, the default background view for the list style is used.
       - label: A closure that returns the content to be displayed within the list. This is typically where you would compose the view elements that make up the content of the inspector.

     ## Usage Example

     ```swift
     var body: some View {
         PropertyInspector("User Preferences", listStyle: .grouped) {
             MyView() // Replace with your content
         }
     }
     ```

     - seeAlso: ``init(_:isPresented:listStyle:listRowBackground:label:)`` for a version of this initializer that supports modal presentation with `isPresented` binding.
     */
    public init<L: ListStyle, B: View>(
        _ title: String? = nil,
        listStyle: L,
        listRowBackground: B,
        @ViewBuilder label: () -> Label
    ) where Style == ListPropertyInspectorStyle<L, B> {
        self.label = label()
        self.style = ListPropertyInspectorStyle(
            title: title,
            listStyle: listStyle,
            listRowBackground: listRowBackground,
            contentPadding: true
        )
    }

    /**
     Initializes a `PropertyInspector` with an inline presentation style.

     This initializer is designed for cases where property inspection needs to be seamlessly integrated within the flow of existing content, rather than displayed as a separate list or modal. It is particularly useful in contexts where minimal disruption to the user interface is desired.

     - Parameters:
       - title: An optional title for the inline inspector; if not provided, defaults to `nil`. This title can be used to provide a heading or context for the inspected properties.
       - label: A closure that returns the content to be displayed directly in line with other UI elements. This allows for dynamic creation of content based on current state or other conditions.

     ## Usage Example

     ```swift
     var body: some View {
         VStack {
             Text("Settings")
             PropertyInspector("User Preferences") {
                 Toggle("Enable Notifications", isOn: $notificationsEnabled)
             }
             Text("Other Options")
         }
     }
     ```

     - seeAlso: ``init(_:isPresented:listStyle:listRowBackground:label:)`` for modal presentation styles, or  ``init(_:listStyle:listRowBackground:label:)`` for list-based styles with more extensive customization options.
     */
    public init(
        _ title: String? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == InlinePropertyInspectorStyle {
        self.label = label()
        self.style = InlinePropertyInspectorStyle(title: title)
    }

    var label: Label

    var style: Style

    public var body: some View {
        // Do not change the following order:
        label
            // 1. content modifiers
            .modifier(style)
            // 2. data modifiers
            .modifier(ContextModifier())
    }
}

/**
 Customizes the appearance and behavior of `PropertyInspector` components. This protocol adheres to `ViewModifier`, enabling it to modify the view of a `PropertyInspector` to match specific design requirements.
 */
public protocol _PropertyInspectorStyle: ViewModifier {}

#Preview(body: {
    PropertyInspector(listStyle: .plain) {
        VStack(content: {
            Text("Placeholder").inspectSelf()
            Button("Tap Me", action: {}).inspectSelf()
        })
        .propertyInspectorRowIcon(for: Rows.self) { _ in
            Image(systemName: "list.bullet")
        }
        .propertyInspectorRowIcon(for: Text.self) { _ in
            Image(systemName: "text.quote")
        }
        .propertyInspectorRowIcon(for: Button<Text>.self) { _ in
            Image(systemName: "button.vertical.right.press.fill")
        }
    }
})