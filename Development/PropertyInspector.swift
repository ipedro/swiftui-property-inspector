import SwiftUI

/**
  A `PropertyInspector` struct provides a customizable interface for inspecting properties within a SwiftUI view.

  The `PropertyInspector` is designed to display detailed information about properties, ideal for debugging purposes, configuration settings, or presenting detailed data about objects in a clear and organized manner. It leverages generics to support various content and styling options, making it a versatile tool for building dynamic and informative user interfaces.

  ## Usage

  The `PropertyInspector` is typically initialized with a label and a style. The label defines the content that will be displayed, while the style dictates how this content is presented. Below is an example of how to instantiate and use a `PropertyInspector` with a custom style and label:

 ![SwiftUI PropertyInspector plain list style example](https://github.com/ipedro/swiftui-property-inspector/raw/main/Docs/swiftui-property-inspector-plain-list-example.gif)

 ```swift
 import PropertyInspector
 import SwiftUI

 var body: some View {
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
 }
 ```

 ```swift
 struct InspectableText<S: StringProtocol>: View {
     var content: S

     var body: some View {
         Text(content).inspectProperty(content)
     }
 }
 ```

 ```swift
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
 ```

 - seeAlso: ``inspectProperty(_:shape:function:line:file:)-5quvs``, ``propertyInspectorHidden()``, and ``inspectSelf(shape:function:line:file:)``
  */
public struct PropertyInspector<Label: View, Style: _PropertyInspectorStyle>: View {
    var label: Label
    var style: Style
    var context = Context()

    public var body: some View {
        // Do not change the following order:
        label
            // 1. content
            .modifier(style)
            // 2. data context
            .modifier(context)
    }
}

public extension PropertyInspector {
    /**
      Initializes property inspector presented as a sheet with minimal styling.

      This initializer sets up a property inspector presented as a sheet using [PlainListStyle](https://developer.apple.com/documentation/swiftui/plainliststyle) and a clear background. It's useful for cases where a straightforward list display is needed without additional styling complications.

      - Parameters:
        - title: An optional title for the sheet; if not provided, defaults to `nil`.
        - isPresented: A binding to a Boolean value that controls the presentation state of the sheet.
        - label: A closure that returns the content to be displayed within the sheet.

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
    @available(iOS 16.4, macOS 13.3, *)
    init(
        _ title: LocalizedStringKey? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) where Style == _SheetPropertyInspector<PlainListStyle, Color> {
        self.label = label()
        style = _SheetPropertyInspector(
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
    @available(iOS 16.4, macOS 13.3, *)
    init<L: ListStyle>(
        _ title: LocalizedStringKey? = nil,
        isPresented: Binding<Bool>,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == _SheetPropertyInspector<L, Color> {
        self.label = label()
        style = _SheetPropertyInspector(
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
    init<L: ListStyle>(
        _ title: LocalizedStringKey? = nil,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == _ListPropertyInspector<L, Color> {
        self.label = label()
        style = _ListPropertyInspector(
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
    init<L: ListStyle, B: View>(
        _ title: LocalizedStringKey? = nil,
        listStyle: L,
        listRowBackground: B,
        @ViewBuilder label: () -> Label
    ) where Style == _ListPropertyInspector<L, B> {
        self.label = label()
        style = _ListPropertyInspector(
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

     - seeAlso: ``init(_:isPresented:listStyle:listRowBackground:label:)`` for modal presentation styles, or  ``init(_:listStyle:listRowBackground:label:)-1gshp`` for list-based styles with more extensive customization options.
     */
    init(@ViewBuilder label: () -> Label) where Style == _InlinePropertyInspector {
        self.label = label()
        style = _InlinePropertyInspector()
    }
}
