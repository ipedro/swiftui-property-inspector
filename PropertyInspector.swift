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

// MARK: - Public API

public extension View {
    /// Inspects the view itself.
    func inspectSelf() -> some View {
        inspectProperty(self)
    }

     /**
     Adds a modifier for inspecting properties with dynamic debugging capabilities.

     This method allows developers to dynamically inspect values of properties within a SwiftUI view, useful for debugging and during development to ensure that view states are correctly managed.

     - Parameters:
       - values: A variadic list of properties whose values you want to inspect.
       - function: The function from which the inspector is called, generally used for debugging purposes. Defaults to the name of the calling function.
       - line: The line number in the source file from which the inspector is called, aiding in pinpointing where inspections are set. Defaults to the line number in the source file.
       - file: The name of the source file from which the inspector is called, useful for tracing the call in larger projects. Defaults to the filename.

     - Returns: A view modified to include property inspection capabilities, reflecting the current state of the provided properties.

     ## Usage Example

     ```swift
     Text("Current Count: \(count)").inspectProperty(count)
     ```

     This can be particularly useful when paired with logging or during step-by-step debugging to monitor how and when your view's state changes.

     - seeAlso: ``propertyInspectorHidden()``
     */
    func inspectProperty(_ values: Any..., function: String = #function, line: Int = #line, file: String = #file) -> some View {
        modifier(
            PropertyInspectingModifier(
                data: values,
                location: .init(
                    function: function,
                    file: file,
                    line: line
                )
            )
        )
    }

    /**
     Hides the view from property inspection.

     Use this method to unconditionally hide nodes from the property inspector, which can be useful in many ways.

     - Returns: A view that no longer shows its properties in the property inspector, effectively hiding them from debugging tools.

     ## Usage Example

     ```swift
     Text("Hello, World!").propertyInspectorHidden()
     ```

     This method can be used to safeguard sensitive information or simply to clean up the debugging output for views that no longer need inspection.

     - seeAlso: ``inspectProperty(_:function:line:file:)``
     */
    func propertyInspectorHidden() -> some View {
        environment(\.propertyInspectorHidden, true)
    }

    /**
     Applies a modifier to inspect properties with custom icons based on their data type.

     This method allows you to define custom icons for different data types displayed in the property inspector, enhancing the visual differentiation and user experience.

     - Parameter data: The type of data for which the icon is defined.
     - Parameter icon: A closure that returns the icon to use for the given data type.

     - Returns: A modified view with the custom icon configuration applied to relevant properties.

     ## Usage Example

     ```swift
     Text("Example Property")
         .propertyInspectorRowIcon(for: String.self) { _ in
             Image(systemName: "text.quote")
         }
     ```

     - seeAlso: ``propertyInspectorRowLabel(for:label:)``, ``propertyInspectorRowDetail(for:detail:)``
     */
    func propertyInspectorRowIcon<D, Icon: View>(for data: D.Type, @ViewBuilder icon: @escaping (D) -> Icon) -> some View {
        setPreference(RowIconPreferenceKey.self, body: icon)
    }

    /**
     Defines a label for properties based on their data type within the property inspector.

     Use this method to provide custom labels for different data types, which can help in categorizing and identifying properties more clearly in the UI.

     - Parameter data: The type of data for which the label is defined.
     - Parameter label: A closure that returns the label to use for the given data type.

     - Returns: A modified view with the custom label configuration applied to relevant properties.

     ## Usage Example

     ```swift
     Text("Example Property")
         .propertyInspectorRowLabel(for: Int.self) { value in
             Text("Integer: \(value)")
         }
     ```

     - seeAlso: ``propertyInspectorRowIcon(for:icon:)``, ``propertyInspectorRowDetail(for:detail:)``
     */
    func propertyInspectorRowLabel<D, Label: View>(for data: D.Type, @ViewBuilder label: @escaping (D) -> Label) -> some View {
        setPreference(RowLabelPreferenceKey.self, body: label)
    }

    /**
     Specifies detail views for properties based on their data type within the property inspector.

     This method enables the display of detailed information for properties, tailored to the specific needs of the data type.

     - Parameter data: The type of data for which the detail view is defined.
     - Parameter detail: A closure that returns the detail view for the given data type.

     - Returns: A modified view with the detail view configuration applied to relevant properties.

     ## Usage Example

     ```swift
     Text("Example Property")
         .propertyInspectorRowDetail(for: Date.self) { date in
             Text("Date: \(date, formatter: dateFormatter)")
         }
     ```

     - seeAlso: ``propertyInspectorRowIcon(for:icon:)``, ``propertyInspectorRowLabel(for:label:)``
     */
    func propertyInspectorRowDetail<D, Detail: View>(for data: D.Type, @ViewBuilder detail: @escaping (D) -> Detail) -> some View {
        setPreference(RowDetailPreferenceKey.self, body: detail)
    }
}

// MARK: - Public Initializers

@available(iOS 16.4, *)
public extension PropertyInspector {
    /**
     Initializes a `PropertyInspector` with a simple sheet style using [PlainListStyle](https://developer.apple.com/documentation/swiftui/plainliststyle) and a clear background.

     This initializer sets up a property inspector presented as a sheet with minimal styling. It's useful for cases where a straightforward list display is needed without additional styling complications.

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
             MyInspectableContent()
         }
     }
     ```

     - seeAlso: ``PropertyInspector/init(_:isPresented:listStyle:listRowBackground:label:)`` for more customized sheet styles.
    */
    init(
        _ title: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) where Style == SheetPropertyInspectorStyle<PlainListStyle, Color> {
        self.init(
            label: label(),
            style: SheetPropertyInspectorStyle(
                title: title,
                isPresented: isPresented,
                listStyle: .plain,
                listRowBackground: .clear
            )
        )
    }

    init<L: ListStyle>(
        _ title: String? = nil,
        isPresented: Binding<Bool>,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == SheetPropertyInspectorStyle<L, Color> {
        self.init(
            label: label(),
            style: SheetPropertyInspectorStyle(
                title: title,
                isPresented: isPresented,
                listStyle: listStyle,
                listRowBackground: listRowBackground
            )
        )
    }
}

public extension PropertyInspector {
    init<L: ListStyle>(
        _ title: String? = nil,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == ListPropertyInspectorStyle<L, Color> {
        self.init(
            label: label(),
            style: ListPropertyInspectorStyle(
                title: title,
                listStyle: listStyle,
                listRowBackground: listRowBackground,
                contentPadding: true
            )
        )
    }

    init<L: ListStyle, B: View>(
        _ title: String? = nil,
        listStyle: L,
        listRowBackground: B,
        @ViewBuilder label: () -> Label
    ) where Style == ListPropertyInspectorStyle<L, B> {
        self.init(
            label: label(),
            style: ListPropertyInspectorStyle(
                title: title,
                listStyle: listStyle,
                listRowBackground: listRowBackground,
                contentPadding: true
            )
        )
    }
}

public extension PropertyInspector {
    init(
        _ title: String? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == InlinePropertyInspectorStyle {
        self.init(
            label: label(),
            style: InlinePropertyInspectorStyle(title: title)
        )
    }
}

public struct PropertyInspector<Label: View, Style: PropertyInspectorStyle>: View {
    var label: Label

    var style: Style

    public var body: some View {
        // Do not change the following order:
        label
            // 1. content modifiers
            .modifier(style)
            // 2. data modifiers
            .modifier(Context())
    }

    struct Context: ViewModifier {
        @StateObject
        private var data = PropertyInspectorData()

        func body(content: Self.Content) -> some View {
            content
                .onPreferenceChange(PropertyPreferenceKey.self, perform: { newValue in
                    let uniqueProperties = newValue
                        .sorted()

                    if data.allObjects != uniqueProperties {
                        data.allObjects = uniqueProperties
                    }
                })
                .onPreferenceChange(RowDetailPreferenceKey.self, perform: { value in
                    data.rowDetails = value
                })
                .onPreferenceChange(RowIconPreferenceKey.self, perform: { value in
                    data.rowIcons = value
                })
                .onPreferenceChange(RowLabelPreferenceKey.self, perform: { value in
                    data.rowLabels = value
                })
                // 2. state injection
                .environmentObject(data)
        }
    }
}

public protocol PropertyInspectorStyle: ViewModifier {}

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
public struct SheetPropertyInspectorStyle<Style: ListStyle, RowBackground: View>: PropertyInspectorStyle {
    var title: String?

    @Binding
    var isPresented: Bool

    var listStyle: Style

    var listRowBackground: RowBackground?

    @EnvironmentObject
    private var data: PropertyInspectorData
    
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
                            listRowBackground: listRowBackground
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

        data.allObjects.enumerated().forEach { (offset, property) in
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

// MARK: - List Style

/**
 `ListPropertyInspectorStyle` provides a SwiftUI view modifier that applies a list-style presentation to property inspectors.

 This style organizes properties into a list, using specified list styles and row backgrounds, suitable for inspections within a non-modal, integrated list environment.

 - Parameters:
   - `listStyle`: The style of the list, conforming to `ListStyle`. Typical styles include `.plain`, `.grouped`, and `.insetGrouped`, depending on the desired visual effect.
   - `listRowBackground`: The view used as the background for each row in the list, conforming to `View`. This could be a simple `Color` or more complex custom views.
   - `title`: An optional title for the list; if not provided, defaults to `nil`.
   - `contentPadding`: A Boolean value that indicates whether the content should have padding. Defaults to `false`.

 - Returns: A view modifier that configures the appearance and behavior of a property inspector using the specified list style.

 ## Usage

 You don't instantiate `ListPropertyInspectorStyle` directly. Instead, use it when initializing your `PropertyInspector` to apply a list-style layout. Here's an example configuration:

 ```swift
 var body: some View {
     PropertyInspector(
         "Optional Title",
         listStyle: .plain, // optonal
         label: {
             // Your view components here
             MyListView()
         }
     )
 }
 ```
 ## Performance Considerations

 Utilizing complex views as `listRowBackground` may impact performance, especially with very long lists.

 - seeAlso: ``SheetPropertyInspectorStyle`` and ``InlinePropertyInspectorStyle``
*/
public struct ListPropertyInspectorStyle<Style: ListStyle, RowBackground: View>: PropertyInspectorStyle {
    var title: String?
    var listStyle: Style
    var listRowBackground: RowBackground?
    var contentPadding: Bool = false

    public func body(content: Content) -> some View {
        List {
            Section {
                PropertyInspectorRows().listRowBackground(listRowBackground)
            } header: {
                VStack(spacing: .zero) {
                    content
                        .environment(\.textCase, nil)
                        .padding(contentPadding ? .vertical : [])
                        .padding(contentPadding ? .vertical : [])

                    PropertyInspectorHeader(title: title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .listStyle(listStyle)
    }
}

// MARK: - Inline Style

/**
 `InlinePropertyInspectorStyle` provides a SwiftUI view modifier that applies an inline-style presentation to property inspectors.

 This style integrates property listings directly within the surrounding content, using a minimalistic approach suitable for inline detail presentation.

 - Parameters:
   - title: An optional title for the inline presentation; if not provided, defaults to `nil`.
   - listRowBackground: The view used as the background for each row, conforming to `View`. Typically a `Color` or transparent effects are used to blend seamlessly with the surrounding content.
   - contentPadding: A Boolean value that indicates whether the content should have padding. Defaults to `true`.

 - Returns: A view modifier that configures the appearance and behavior of a property inspector using the specified inline style.

 ## Usage

 `InlinePropertyInspectorStyle` should be used when you want to integrate property details directly within your UI without a distinct separation. Here's how to configure it:

 ```swift
 var body: some View {
     PropertyInspector(
         "Optional Title",
         listRowBackground: nil, // optional
         label: {
             // Inline content, typically detailed views or forms
             MyDetailView()
         }
     )
 }
 ```

 ## Performance Considerations

 Since ``InlinePropertyInspectorStyle`` is designed for minimalistic integration, it generally has low impact on performance.

 - seeAlso: ``SheetPropertyInspectorStyle`` and ``ListPropertyInspectorStyle``.
 */
public struct InlinePropertyInspectorStyle: PropertyInspectorStyle {
    var title: String?

    public func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            LazyVStack(alignment: .leading, spacing: 15) {
                PropertyInspectorRows().inspectSelf()
            }
            .padding()
        }
    }
}

// MARK: - Private Views

private struct PropertyInspectorHeader: View {
    var title: String?

    @EnvironmentObject
    private var data: PropertyInspectorData

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let title {
                Text(title).bold().font(.title2)
            }

            TextField(
                "Search \(data.properties.count) items",
                text: $data.searchQuery
            )
            .frame(maxWidth: .infinity)

            if #available(iOS 16.0, *) {
                Toggle(sources: data.allObjects, isOn: \.$isHighlighted) {
                    EmptyView()
                }
                .toggleStyle(PropertyInspectorToggleStyle(alignment: .firstTextBaseline))
            }
        }
        .environment(\.textCase, nil)
        .foregroundStyle(.primary)
        .tint(.primary)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 0,
                bottom: 8,
                trailing: 0
            )
        )
    }
}

private struct PropertyInspectorRows: View {
    @EnvironmentObject
    private var data: PropertyInspectorData

    private var emptyMessage: String {
        data.searchQuery.isEmpty ?
        "Empty" :
        "No results for '\(data.searchQuery)'"
    }

    var body: some View {
        if data.properties.isEmpty {
            Text(emptyMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .multilineTextAlignment(.center)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 200
                )
        }

        ForEach(data.properties, content: makeRow)
    }

    struct _ButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }

    private func makeRow(_ property: Property) -> some View {
        Row(
            id: property.id,
            hideIcon: data.rowIcons.isEmpty,
            isOn: property.$isHighlighted,
            icon: {
                if let icon = data.makeIcon(property) {
                    icon
                }
                else {
                    Image(systemName: "info.circle.fill")
                }
            },
            label: {
                if let label = data.makeLabel(property) {
                    label
                }
                else {
                    Text(verbatim: property.stringValue)
                }
            },
            detail: {
                if let detail = data.makeDetail(property) {
                    detail
                }
                else {
                    Text(verbatim: property.location.description)
                }
            }
        )
        .equatable()
    }

    struct Row<ID: Hashable, Icon: View, Label: View, Detail: View>: View, Equatable {
        var id: ID
        var hideIcon: Bool
        @Binding var isOn: Bool
        @ViewBuilder var icon: Icon
        @ViewBuilder var label: Label
        @ViewBuilder var detail: Detail

        private var leading: CGFloat? {
            hideIcon ? 0 : 25
        }

        var body: some View {
            Toggle(isOn: $isOn, label: content).toggleStyle(
                PropertyInspectorToggleStyle(alignment: .firstTextBaseline)
            )
            .foregroundStyle(.secondary)
            .symbolRenderingMode(.hierarchical)
        }

        private func content() -> some View {
            VStack(alignment: .leading) {
                iconAndLabel

                detail.font(.caption).padding(.leading, leading)
            }
            .allowsTightening(true)
            .contentShape(Rectangle())
            .multilineTextAlignment(.leading)
        }

        private var iconAndLabel: some View {
            HStack(alignment: .firstTextBaseline, spacing: .zero) {
                icon.opacity(hideIcon ? 0 : 1).frame(
                    width: leading,
                    alignment: .leading
                )

                label.foregroundStyle(.primary)
            }
            .font(.footnote.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id && lhs.isOn == rhs.isOn
        }
    }
}

#Preview(body: {
    PropertyInspector(listStyle: .plain) {
        VStack(content: {
            Text("Placeholder").inspectSelf()
            Button("Tap Me", action: {}).inspectSelf()
        })
        .propertyInspectorRowIcon(for: PropertyInspectorRows.self) { _ in
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

// MARK: - Private Styles

private struct PropertyInspectorToggleStyle: ToggleStyle {
    var alignment: VerticalAlignment = .center
    var animation: Animation? = .interactiveSpring

    func makeBody(configuration: Configuration) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: alignment) {
                configuration.label
                Spacer()
                Image(systemName: imageName(configuration)).font(.body)
            }
        }
    }

    private func imageName(_ configuration: Configuration) -> String {
        if #available(iOS 16.0, *), configuration.isMixed {
            return "minus.circle.fill"
        }
        if configuration.isOn {
            return "checkmark.circle.fill"
        }
        return "circle"
    }
}

// MARK: - Private View Extensions

private extension View {
    func setPreference<K: PreferenceKey>(_ key: K.Type, value: K.Value) -> some View {
        modifier(PreferenceKeyWritingModifier<K>(value: value))
    }

    func setPreference<K: PreferenceKey, D, C: View>(_ key: K.Type, @ViewBuilder body: @escaping (D) -> C) -> some View where K.Value == TypeRegistry {
        let id = ObjectIdentifier(D.self)

        let body = TypeRegistry.ViewBuilder(id: id) { value in
            if let castedValue = value as? D {
                return AnyView(body(castedValue))
            }
            return nil
        }

        return modifier(PreferenceKeyWritingModifier<K>(value: TypeRegistry([id: body])))
    }
}

// MARK: - View Modifiers
private struct PreferenceKeyWritingModifier<K: PreferenceKey>: ViewModifier {
    let value: K.Value

    func body(content: Content) -> some View {
        content.background(
            Spacer().preference(key: K.self, value: value)
        )
    }
}

private struct PropertyInspectingModifier: ViewModifier  {
    let data: [Any]
    let location: PropertyLocation

    @State
    private var isOn = false
    @State
    private var icons = [Int: ObjectIdentifier]()
    @State
    private var labels = [Int: ObjectIdentifier]()
    @State
    private var details = [Int: ObjectIdentifier]()

    @Environment(\.propertyInspectorHidden)
    private var disabled

    func body(content: Content) -> some View {
        content
            .setPreference(PropertyPreferenceKey.self, value: Set(properties))
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

    private var properties: [Property] {
        if disabled { return [] }

        return data.enumerated().map { (index, value) in
            let icon = Binding {
                icons[index]
            } set: { newValue in
                icons[index] = newValue
            }

            let label = Binding {
                labels[index]
            } set: { newValue in
                labels[index] = newValue
            }

            let detail = Binding {
                details[index]
            } set: { newValue in
                details[index] = newValue
            }

            return Property(
                value: value,
                isHighlighted: $isOn,
                icon: icon,
                label: label,
                detail: detail,
                location: location,
                index: index
            )
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

// MARK: - Preference Keys

private struct PropertyPreferenceKey: PreferenceKey {
    static var defaultValue: Set<Property> { [] }
    static func reduce(value: inout Set<Property>, nextValue: () -> Set<Property>) {
        value.formUnion(nextValue())
    }
}

private struct TitlePreferenceKey: PreferenceKey {
    static let defaultValue = LocalizedStringKey("Properties")
    static func reduce(value: inout LocalizedStringKey, nextValue: () -> LocalizedStringKey) {}
}

private struct RowDetailPreferenceKey: PreferenceKey {
    static let defaultValue = TypeRegistry()
    static func reduce(value: inout TypeRegistry, nextValue: () -> TypeRegistry) {
        value.merge(nextValue())
    }
}

private struct RowIconPreferenceKey: PreferenceKey {
    static let defaultValue = TypeRegistry()
    static func reduce(value: inout TypeRegistry, nextValue: () -> TypeRegistry) {
        value.merge(nextValue())
    }
}

private struct RowLabelPreferenceKey: PreferenceKey {
    static let defaultValue = TypeRegistry()
    static func reduce(value: inout TypeRegistry, nextValue: () -> TypeRegistry) {
        value.merge(nextValue())
    }
}

// MARK: - Environment Keys

private struct PropertyInspectorHiddenKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private extension EnvironmentValues {
    var propertyInspectorHidden: Bool {
        get { self[PropertyInspectorHiddenKey.self] }
        set { self[PropertyInspectorHiddenKey.self] = newValue }
    }
}

// MARK: - Models

private final class PropertyInspectorData: ObservableObject {
    @Published
    var allObjects = [Property]()

    @Published
    var searchQuery = ""

    @Published
    var rowIcons = TypeRegistry() {
        willSet {
            for property in allObjects where property.icon != nil {
                property.icon = nil
            }
        }
    }

    @Published
    var rowLabels = TypeRegistry() {
        willSet {
            for property in allObjects where property.label != nil {
                property.label = nil
            }
        }
    }

    @Published
    var rowDetails = TypeRegistry() {
        willSet {
            for property in allObjects where property.detail != nil {
                property.detail = nil
            }
        }
    }

    var properties: [Property] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return allObjects }
        return allObjects.filter {
            String(describing: $0).localizedCaseInsensitiveContains(query)
        }
    }

    func makeIcon(_ property: Property) -> AnyView? {
        makeBody(property, registry: rowIcons, cache: \.$icon)
    }

    func makeLabel(_ property: Property) -> AnyView? {
        makeBody(property, registry: rowLabels, cache: \.$label)
    }

    func makeDetail(_ property: Property) -> AnyView? {
        makeBody(property, registry: rowDetails, cache: \.$detail)
    }

    private func makeBody(
        _ property: Property,
        registry: TypeRegistry,
        cache keyPath: KeyPath<Property, Binding<ObjectIdentifier?>>
    ) -> AnyView? {
        //let start = Date()
        let cache = property[keyPath: keyPath]

        if let key = cache.wrappedValue {
            let view = registry[key]?.body(property.value)
            // print(#function, "[\(property.id)] 🔥 Retrieved from cache in \(start.timeIntervalSinceNow.formatted()) s")
            return view
        }

        for id in registry.identifiers {
            if let view = registry[id]?.body(property.value) {
                cache.wrappedValue = id
                // print(#function, "[\(property.id)] 👀 Looked up builder in \(start.timeIntervalSinceNow.formatted()) s")
                return view
            }
        }

        // print(#function, "[\(property.id)] 🐢 Coulnd't find custom builder. Search took \(start.timeIntervalSinceNow.formatted()) s")
        cache.wrappedValue = ObjectIdentifier(Any.self)
        return nil
    }
}

private struct TypeRegistry: Hashable {
    private var data: [ObjectIdentifier: ViewBuilder]

    var isEmpty: Bool { data.isEmpty }

    var identifiers: [ObjectIdentifier] { Array(data.keys) }

    subscript(id: ObjectIdentifier) -> ViewBuilder? {
        get { data[id] }
        set { data[id] = newValue }
    }

    init(_ data: [ObjectIdentifier : ViewBuilder] = [:]) {
        self.data = data
    }

    mutating func merge(_ other: TypeRegistry) {
        data.merge(other.data) { content, _ in
            content
        }
    }
}

extension TypeRegistry {
    struct ViewBuilder: Hashable, Identifiable {
        let id: ObjectIdentifier
        let body: (Any) -> AnyView?

        static func == (lhs: ViewBuilder, rhs: ViewBuilder) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

private struct Property: Identifiable, Comparable, CustomStringConvertible, Hashable {
    let id = UUID()

    let value: Any

    @Binding
    var isHighlighted: Bool

    @Binding
    var icon: ObjectIdentifier?

    @Binding
    var label: ObjectIdentifier?

    @Binding
    var detail: ObjectIdentifier?

    let location: PropertyLocation

    var description: String {
        sortString
    }

    var stringValueType: String {
        String(describing: type(of: value))
    }

    var stringValue: String {
        String(describing: value)
    }

    private let sortString: String

    init(
        value: Any,
        isHighlighted: Binding<Bool>,
        icon: Binding<ObjectIdentifier?>,
        label: Binding<ObjectIdentifier?>,
        detail: Binding<ObjectIdentifier?>,
        location: PropertyLocation,
        index: Int
    ) {
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
        self._icon = icon
        self._label = label
        self._detail = detail
        self.sortString = [
            location.id,
            String(index),
            String(describing: value)
        ].joined(separator: "_")
    }

    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id &&
        lhs.isHighlighted == rhs.isHighlighted
    }

    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private struct PropertyLocation: Identifiable, Comparable, CustomStringConvertible {
    let id: String

    let function: String

    let file: String

    let line: Int

    init(function: String, file: String, line: Int) {
        let fileName = URL(string: file)?.lastPathComponent ?? file

        self.id = "\(file):\(line):\(function)"
        self.description = "\(fileName):\(line)"
        self.function = function
        self.file = file
        self.line = line
    }

    let description: String

    static func < (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
    }

    static func == (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id == rhs.id
    }
}
