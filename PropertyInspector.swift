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

/// `PropertyInspector` provides a SwiftUI view that presents a customizable inspector pane
/// for properties, allowing users to dynamically explore and interact with property values.
/// It supports customizable title, content, icons, labels, and detailed views for each property.
///
/// - Parameters:
///   - Content: The type of the main content view.
///
/// Usage example:
/// ```
/// @State private var isInspectorPresented: Bool = false
///
/// var body: some View {
///     PropertyInspector(isPresented: $isInspectorPresented) {
///         // Inspectable content
///         ...
///     }
/// }
/// ```
///
/// The `PropertyInspector` leverages SwiftUI's preference system to collect property information
/// from descendant views into a consolidated list, which is then presented in an inspector pane
/// when the `isPresented` binding is toggled to `true`.
@available(iOS 16.4, *)
public struct PropertyInspector<Content: View>: View {
    private var content: Content

    @Binding
    private var isPresented: Bool

    @StateObject
    private var data = PropertyInspectorDataStore()

    /// `PropertyInspector` provides a dynamic and customizable view for inspecting properties within a SwiftUI application.
    ///
    /// By integrating `PropertyInspector` into your SwiftUI views, you can add a powerful tool for developers and designers to introspect runtime values of properties, aiding in debugging and UI design processes. This inspector leverages SwiftUI's preference key system, view modifiers, and environment values to collect, display, and filter inspectable properties.
    ///
    /// Usage:
    ///
    /// Wrap any SwiftUI view where you want to enable property inspection:
    /// ```swift
    /// @State private var isInspectorPresented = false
    ///
    /// var body: some View {
    ///     PropertyInspector("My Inspector", isPresented: $isInspectorPresented) {
    ///         // Your view content here
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A `Binding<Bool>` that controls the presentation of the inspector. Toggling this value shows or hides the inspector.
    ///   - content: A closure returning the content of the view to be inspected.
    ///
    public init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.content = content()
    }

    private var bottomInset: CGFloat {
        isPresented ? UIScreen.main.bounds.midY : 0
    }

    public var body: some View {
        content
            .onPreferenceChange(PropertyInspectorValueKey.self) { data.items = Set($0).sorted() }
            .onPreferenceChange(PropertyInspectorTitleKey.self) { data.title = $0 }
            .onPreferenceChange(PropertyInspectorIconViewBuilderKey.self) { data.icons = $0  }
            .onPreferenceChange(PropertyInspectorLabelViewBuilderKey.self) { data.labels = $0 }
            .onPreferenceChange(PropertyInspectorDetailViewBuilderKey.self) { data.details = $0 }
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: bottomInset)
            }
            .toolbar {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: isPresented ? "xmark.circle" : "magnifyingglass.circle")
                        .rotationEffect(.degrees(isPresented ? 180 : 0))
                }
            }
            .animation(.snappy, value: isPresented)
            .overlay {
                Spacer().sheet(isPresented: $isPresented) {
                    PropertyInspectorList()
                        .environmentObject(data)
                }
            }
    }
}

final class PropertyInspectorDataStore: ObservableObject {
    @Published var title = PropertyInspectorTitleKey.defaultValue
    @Published var items = [PropertyInspectorItem]()
    @Published var icons = PropertyInspectorViewBuilderDictionary()
    @Published var labels = PropertyInspectorViewBuilderDictionary()
    @Published var details = PropertyInspectorViewBuilderDictionary()
}

public extension View {
    /// Attaches an inspectable property to the view, which can be introspected by the `PropertyInspector`.
    ///
    /// Use `inspectProperty` to mark values within your view hierarchy as inspectable. These values are then available within the `PropertyInspector` UI, allowing you to debug and inspect values at runtime.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello, world!")
    ///     .inspectProperty("Hello, world!", function: "Text(_:)")
    /// ```
    ///
    /// - Parameters:
    ///   - values: An array of `Any` representing the values to be inspected.
    ///   - function: A `String` representing the name of the function or context in which the property is being inspected. Defaults to the caller function name.
    ///   - line: An `Int` representing the line number in the source file at which the property is being inspected. Defaults to the caller line number.
    ///   - file: A `String` representing the path of the source file in which the property is being inspected. Defaults to the caller file path.
    ///
    /// - Returns: A view modified to include the specified properties in the inspection.
    func inspectProperty(
        _ values: Any...,
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        modifier(
            PropertyInspectorViewModifier(
                values: values,
                location: .init(
                    function: function,
                    file: file,
                    line: line
                )
            )
        )
    }

    /// Modifies the view to enable or disable the property inspector.
    ///
    /// - Parameter disabled: A Boolean value that determines whether the inspector is disabled for this view.
    /// - Returns: A view modified to have the inspector enabled or disabled.
    func inspectorDisabled(_ disabled: Bool = true) -> some View {
        environment(\.inspectorDisabled, disabled)
    }

    /// Registers a custom icon view for a specific type to be used in the Property Inspector's UI.
    ///
    /// This function allows you to provide a custom icon representation for a given type when displayed in the property inspector. The icon view is constructed using the provided value of the specified type.
    ///
    /// Usage Example:
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Hello, World!")
    ///             .inspectorRowIcon(for: String.self) { stringValue in
    ///                 Image(systemName: "text.quote")
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The type of value for which the custom icon view is provided.
    ///   - icon: A closure that takes an instance of the specified type and returns a view to be used as an icon.
    /// - Returns: A view modified to include a custom icon view for a specific type in the property inspector.
    func inspectorRowIcon<Value, Icon: View>(
        for type: Value.Type,
        @ViewBuilder icon: @escaping (Value) -> Icon
    ) -> some View {
        modifier(
            PropertyInspectorViewBuilderModifier(
                key: PropertyInspectorIconViewBuilderKey.self,
                label: icon
            )
        )
    }

    func inspectorTitle(_ title: String) -> some View {
        modifier(
            PropertyInspectorTitleModifier(title: title)
        )
    }

    /// Registers a custom label view for a specific type to be displayed in the Property Inspector's UI.
    ///
    /// Use this function to define how the label for a given type should be displayed in the property inspector. The label is generated dynamically based on the value of the specified type.
    ///
    /// Usage Example:
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Important")
    ///             .inspectorRowLabel(for: String.self) { stringValue in
    ///                 Text(stringValue).fontWeight(.bold)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The type of value for which the custom label view is provided.
    ///   - label: A closure that takes an instance of the specified type and returns a view to be used as a label.
    /// - Returns: A view modified to include a custom label view for a specific type in the property inspector.
    func inspectorRowLabel<Value, Label: View>(
        for type: Value.Type,
        @ViewBuilder label: @escaping (Value) -> Label
    ) -> some View {
        modifier(
            PropertyInspectorViewBuilderModifier(
                key: PropertyInspectorLabelViewBuilderKey.self,
                label: label
            )
        )
    }

    /// Registers a custom detail view for a specific type to be shown in the Property Inspector's UI.
    ///
    /// This function enables the customization of the detail view presented for a given type within the property inspector. It allows for detailed, context-specific views based on the provided value.
    ///
    /// Usage Example:
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("User Detail")
    ///             .inspectorRowDetail(for: String.self) { stringValue in
    ///                 HStack {
    ///                     Text("Detail:")
    ///                     Text(stringValue).italic()
    ///                 }
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The type of value for which the custom detail view is provided.
    ///   - detail: A closure that takes an instance of the specified type and returns a view to be used as a detail view.
    /// - Returns: A view modified to include a custom detail view for a specific type in the property inspector.
    func inspectorRowDetail<Value, Detail: View>(
        for type: Value.Type,
        @ViewBuilder detail: @escaping (Value) -> Detail
    ) -> some View {
        modifier(
            PropertyInspectorViewBuilderModifier(
                key: PropertyInspectorDetailViewBuilderKey.self,
                label: detail
            )
        )
    }
}

extension EnvironmentValues {
    var inspectorDisabled: Bool {
        get { self[PropertyInspectorDisabledKey.self] }
        set { self[PropertyInspectorDisabledKey.self] = newValue }
    }
}

struct PropertyInspectorDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 16.4, *)
struct PropertyInspectorList: View {
    @EnvironmentObject
    private var data: PropertyInspectorDataStore

    @State
    private var searchQuery = ""

    private var rows: [PropertyInspectorItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return data.items }
        return data.items.filter { item in
            String(describing: item).localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                if rows.isEmpty {
                    Text(emptyMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }

                ForEach(rows) { item in
                    PropertyInspectorItemRow(
                        item: item,
                        icon: makeBody(item, using: data.icons),
                        label: makeBody(item, using: data.labels),
                        detail: makeBody(item, using: data.details)
                    )
                }
                .listRowBackground(Color.clear)

            } header: {
                header
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .presentationDetents([
            .fraction(1/3),
            .fraction(1/2),
            .fraction(2/3),
        ])
        .presentationBackgroundInteraction(.enabled)
        .presentationContentInteraction(.scrolls)
        .presentationCornerRadius(20)
        .presentationBackground(Material.thinMaterial)
        .toggleStyle(PropertyInspectorToggleStyle(alignment: .firstTextBaseline))
    }

    private var emptyMessage: String {
        searchQuery.isEmpty ?
        "Nothing yet.\nInspect items using `inspectProperty(_:)`" :
        "No results for '\(searchQuery)'"
    }

    private var header: some View {
        VStack(spacing: 6) {
            Toggle(sources: rows, isOn: \.$isHighlighted) {
                Text(data.title)
                    .bold()
                    .font(.title2)
            }

            HStack {
                TextField(
                    "Search \(rows.count) items",
                    text: $searchQuery
                )

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery.removeAll()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }

        }
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

    private func makeBody(_ item: PropertyInspectorItem, using dict: PropertyInspectorViewBuilderDictionary) -> AnyView? {
        for key in dict.keys {
            if let view = dict[key]?.view(item.value) {
                return view
            }
        }
        return nil
    }
}

struct PropertyInspectorToggleStyle: ToggleStyle {
    var alignment: VerticalAlignment = .center

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: alignment) {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
            }
        }
    }
}

/// Represents an individual inspectable property within the `PropertyInspector`.
///
/// `PropertyInspectorItem` encapsulates the value and metadata of a property to be inspected, including its location within the source code and whether it is currently highlighted in the UI. This type is crucial for organizing and presenting property data within the inspector interface.
///
/// - Note: Conforms to `Identifiable`, `Comparable`, and `Hashable` to support efficient collection operations and UI presentation.
public struct PropertyInspectorItem: Identifiable, Comparable, Hashable {
    /// A unique identifier for the inspector item, necessary for conforming to `Identifiable`.
    public let id = UUID()

    /// The value of the property being inspected. This is stored as `Any` to accommodate any property type.
    public let value: Any

    /// Metadata describing the source code location where this property is inspected.
    public let location: PropertyInspectorLocation

    /// A binding to a Boolean value indicating whether this item is highlighted within the UI.
    @Binding var isHighlighted: Bool

    var stringValue: String {
        String(describing: value)
    }

    private var sortString: String {
        "\(location)\(stringValue)"
    }

    init(value: Any, isHighlighted: Binding<Bool>, location: PropertyInspectorLocation) {
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
    }

    public static func == (lhs: PropertyInspectorItem, rhs: PropertyInspectorItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.location == rhs.location &&
        lhs.stringValue == rhs.stringValue
    }

    public static func < (lhs: PropertyInspectorItem, rhs: PropertyInspectorItem) -> Bool {
        lhs.sortString.localizedCaseInsensitiveCompare(rhs.sortString) == .orderedAscending
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Encapsulates the location within the source code where a `PropertyInspectorItem` was defined.
///
/// This class includes detailed information about the function or variable, the file path, and the line number where the inspected property is located, aiding in pinpointing the exact source of the property.
///
/// - Note: Conforms to `Comparable` and `CustomStringConvertible` for sorting and presenting location information.
public final class PropertyInspectorLocation: Comparable, CustomStringConvertible {
    /// The name of the function or variable where the inspection item is defined.
    public let function: String

    /// The full path of the file where the inspection item is defined.
    public let file: String

    /// The line number within the file where the inspection item is defined.
    public let line: Int

    init(function: String, file: String, line: Int) {
        self.function = function
        self.file = file
        self.line = line
    }

    /// A textual description of the location, typically used for display purposes.
    /// This includes the file name (without the full path) and the line number.
    public private(set) lazy var description: String = {
        guard let fileName = file.split(separator: "/").last else {
            return function
        }
        return "\(fileName):\(line)"
    }()

    public static func < (lhs: PropertyInspectorLocation, rhs: PropertyInspectorLocation) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }

    public static func == (lhs: PropertyInspectorLocation, rhs: PropertyInspectorLocation) -> Bool {
        lhs.description == rhs.description
    }
}

@available(iOS 16.0, *)
struct PropertyInspectorItemRow: View {
    let item: PropertyInspectorItem
    var icon: AnyView?
    var label: AnyView?
    var detail: AnyView?

    var body: some View {
        Toggle(isOn: item.$isHighlighted) {
            HStack {
                Group {
                    if let icon {
                        icon
                    } else {
                        Image(systemName: "questionmark.diamond")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.footnote.bold())

                VStack(alignment: .leading, spacing: 1) {
                    Spacer().frame(height: 3) // padding doesn't work

                    Group {
                        if let label {
                            label
                        } else {
                            Text(verbatim: item.stringValue)
                        }
                    }
                    .font(.footnote.bold())
                    .foregroundStyle(.primary)

                    if let detail {
                        detail
                    } else {
                        Text(verbatim: item.location.function) +
                        Text(verbatim: " — ") +
                        Text(verbatim: item.location.description)
                    }

                    Spacer().frame(height: 3) // padding doesn't work
                }
            }
            .foregroundStyle(.secondary)
            .font(.caption2)
            .contentShape(Rectangle())
        }
        .toggleStyle(PropertyInspectorToggleStyle())
    }
}

struct PropertyInspectorViewModifier: ViewModifier  {
    let values: [Any]
    let location: PropertyInspectorLocation

    @State
    private var isHighlighted = false

    @Environment(\.inspectorDisabled)
    private var disabled

    var data: [PropertyInspectorItem] {
        if disabled {
            return []
        }
        return values.map {
            PropertyInspectorItem(
                value: $0,
                isHighlighted: $isHighlighted,
                location: location
            )
        }
    }

    func body(content: Content) -> some View {
        content
            .background(
                Color.clear.preference(
                    key: PropertyInspectorValueKey.self,
                    value: data
                )
            )
            .inspectorHighlight(isOn: $isHighlighted)
    }
}

extension View {
    func inspectorHighlight(isOn: Binding<Bool>) -> PropertyInspectorHighlightView<Self> {
        PropertyInspectorHighlightView(isOn: isOn) {
            self
        }
    }
}

struct PropertyInspectorHighlightView<Content: View>: View {
    @State
    private var animationToken = UUID()

    @Binding
    var isOn: Bool

    @ViewBuilder
    var content: Content

    @Environment(\.inspectorDisabled)
    private var disabled

    @Environment(\.colorScheme)
    private var colorScheme

    var transition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: .random(in: 2 ... 2.5))),
            removal: .identity
        )
    }

    var isVisible: Bool {
        isOn && !disabled
    }

    var body: some View {
        content
            .zIndex(isVisible ? 999 : 0)
            .overlay {
                if isVisible {
                    Rectangle()
                        .stroke(lineWidth: 1.5)
                        .fill(colorScheme == .light ? Color.blue : Color.yellow)
                        .id(animationToken)
                        .transition(transition)
                }
            }
            .onChange(of: isVisible) { newValue in
                guard newValue else { return }
                animationToken = UUID()
            }
            .animation(animation, value: animationToken)
    }

    var animation: Animation {
        .snappy(
            duration: .random(in: 0.2 ... 0.5),
            extraBounce: .random(in: 0 ... 0.1))
        .delay(.random(in: 0 ... 0.3))
    }
}

// MARK: - View Builders

private extension PropertyInspectorViewBuilderDictionary {
    mutating func merge(_ next: Self) {
        merge(next) { content, _ in
            content
        }
    }
}

typealias PropertyInspectorViewBuilderDictionary = [String: PropertyInspectorViewBuilder]

// MARK: - Preference Keys

struct PropertyInspectorTitleKey: PreferenceKey {
    static var defaultValue: String = "Inspect"

    static func reduce(value: inout String, nextValue: () -> String) {}
}

struct PropertyInspectorValueKey: PreferenceKey {
    /// The default value for the dynamic value entries.
    static var defaultValue: [PropertyInspectorItem] { [] }

    /// Combines the current value with the next value.
    ///
    /// - Parameters:
    ///   - value: The current value of dynamic value entries.
    ///   - nextValue: A closure that returns the next set of dynamic value entries.
    static func reduce(value: inout [PropertyInspectorItem], nextValue: () -> [PropertyInspectorItem]) {
        value.append(contentsOf: nextValue())
    }
}

struct PropertyInspectorDetailViewBuilderKey: PreferenceKey {
    static let defaultValue = PropertyInspectorViewBuilderDictionary()

    static func reduce(value: inout PropertyInspectorViewBuilderDictionary, nextValue: () -> PropertyInspectorViewBuilderDictionary) {
        value.merge(nextValue())
    }
}

struct PropertyInspectorIconViewBuilderKey: PreferenceKey {
    static let defaultValue = PropertyInspectorViewBuilderDictionary()

    static func reduce(value: inout PropertyInspectorViewBuilderDictionary, nextValue: () -> PropertyInspectorViewBuilderDictionary) {
        value.merge(nextValue())
    }
}

struct PropertyInspectorLabelViewBuilderKey: PreferenceKey {
    static let defaultValue = PropertyInspectorViewBuilderDictionary()

    static func reduce(value: inout PropertyInspectorViewBuilderDictionary, nextValue: () -> PropertyInspectorViewBuilderDictionary) {
        value.merge(nextValue())
    }
}

// MARK: - View Builders

struct PropertyInspectorViewBuilder: Equatable {
    let view: (Any) -> AnyView?
    static func == (lhs: PropertyInspectorViewBuilder, rhs: PropertyInspectorViewBuilder) -> Bool {
        String(describing: lhs.view) == String(describing: rhs.view)
    }
}

struct PropertyInspectorViewBuilderModifier<Key: PreferenceKey, Value, Label: View>: ViewModifier where Key.Value == PropertyInspectorViewBuilderDictionary {
    var key: Key.Type

    @ViewBuilder
    var label: (Value) -> Label

    private var valueType: String {
        String(describing: Value.self)
    }

    private var builder: PropertyInspectorViewBuilder {
        PropertyInspectorViewBuilder { value in
            guard let castedValue = value as? Value else {
                return nil
            }
            return AnyView(label(castedValue))
        }
    }

    private var data: PropertyInspectorViewBuilderDictionary {
        [valueType: builder]
    }

    func body(content: Content) -> some View {
        content.background(
            Color.clear.preference(
                key: key,
                value: data
            )
        )
    }
}

struct PropertyInspectorTitleModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content.background(
            Color.clear.preference(
                key: PropertyInspectorTitleKey.self,
                value: title
            )
        )
    }
}
