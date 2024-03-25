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
///   - Value: The type of the property values being inspected.
///   - Content: The type of the main content view.
///   - Label: The type of the view providing the label for each property.
///   - Detail: The type of the view providing additional details for each property.
///   - Icon: The type of the view providing an icon for each property.
///
/// Usage example:
/// ```
/// @State private var isInspectorPresented: Bool = false
///
/// var body: some View {
///     PropertyInspector(isPresented: $isInspectorPresented) {
///         // Main content view
///     } icon: { value in
///         // Icon view for the property value
///     } label: { value in
///         // Label view for the property value
///     } detail: { value in
///         // Detail view for the property value
///     }
/// }
/// ```
///
/// The `PropertyInspector` leverages SwiftUI's preference system to collect property information
/// from descendant views into a consolidated list, which is then presented in an inspector pane
/// when the `isPresented` binding is toggled to `true`.
@available(iOS 16.4, *)
public struct PropertyInspector<Value, Content: View, Label: View, Detail: View, Icon: View>: View {
    public typealias Item = PropertyInspectorItem<Value>

    private var title: String?
    private var content: Content
    private var icon: (Item) -> Icon
    private var label: (Item) -> Label
    private var detail: (Item) -> Detail
    private var comparator: ItemComparator?

    @Binding
    private var isPresented: Bool

    @State
    private var data: [PropertyInspectorItem<Value>] = []

    /// Initializes a `PropertyInspector` with the most detailed configuration, including title, content,
    /// icon, label, and detail views for each property.
    ///
    /// - Parameters:
    ///   - title: An optional title for the property inspector pane.
    ///   - value: The property value type.
    ///   - isPresented: A binding to control the presentation state of the inspector.
    ///   - content: A closure providing the main content view.
    ///   - icon: A closure providing an icon view for each property value.
    ///   - label: A closure providing a label view for each property value.
    ///   - detail: A closure providing a detail view for each property value.
    ///
    /// Usage example:
    /// ```
    /// @State private var isInspectorPresented = false
    ///
    /// var body: some View {
    ///     PropertyInspector("Properties", MyValueType.self, isPresented: $isInspectorPresented) {
    ///         // Main content view goes here
    ///     } icon: { value in
    ///         Image(systemName: "gear")
    ///     } label: { value in
    ///         Text("Property \(value)")
    ///     } detail: { value in
    ///         Text("Detail for \(value)")
    ///     }
    /// }
    /// ```
    public init(
        _ title: String? = nil,
        _ value: Value.Type = Value.self,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder icon: @escaping (Value) -> Icon,
        @ViewBuilder label: @escaping (Value) -> Label,
        @ViewBuilder detail: @escaping (Value) -> Detail
    ) {
        self.title = title
        self._isPresented = isPresented
        self.content = content()
        self.icon = { icon($0.value) }
        self.label = { label($0.value) }
        self.detail = { detail($0.value) }
    }

    /// Initializes a `PropertyInspector` with the most detailed configuration, including title, content,
    /// icon, label, and detail views for each property.
    ///
    /// - Parameters:
    ///   - title: An optional title for the property inspector pane.
    ///   - value: The property value type.
    ///   - isPresented: A binding to control the presentation state of the inspector.
    ///   - content: A closure providing the main content view.
    ///   - icon: A closure providing an icon view for each property value.
    ///   - label: A closure providing a label view for each property value.
    ///   - detail: A closure providing a detail view for each property value.
    ///
    /// Usage example:
    /// ```
    /// @State private var isInspectorPresented = false
    ///
    /// var body: some View {
    ///     PropertyInspector("Properties", MyValueType.self, isPresented: $isInspectorPresented) {
    ///         // Main content view goes here
    ///     } icon: { value in
    ///         Image(systemName: "gear")
    ///     } label: { value in
    ///         Text("Property \(value)")
    ///     } detail: { value in
    ///         Text("Detail for \(value)")
    ///     }
    /// }
    /// ```
    public init(
        _ title: String? = nil,
        _ value: Value.Type = Value.self,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder icon: @escaping (Item) -> Icon,
        @ViewBuilder label: @escaping (Item) -> Label,
        @ViewBuilder detail: @escaping (Item) -> Detail
    ) {
        self.title = title
        self._isPresented = isPresented
        self.content = content()
        self.icon = icon
        self.label = label
        self.detail = detail
    }

    public var body: some View {
        content
            .onPreferenceChange(PropertyInspectorItemKey<Value>.self) { newValue in
                guard let comparator else {
                    data = newValue.sorted()
                    return
                }
                data = newValue.sorted(by: { lhs, rhs in
                    comparator(lhs, rhs)
                })
            }
            .safeAreaInset(edge: .bottom) {
                if isPresented {
                    Spacer().frame(height: UIScreen.main.bounds.midY)
                }
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
                    PropertyInspectorList(
                        title: title,
                        data: data,
                        icon: icon,
                        label: label,
                        detail: detail
                    )
                }
            }
    }
}

/// An extension to `PropertyInspector` that adds the ability to sort the properties displayed
/// in the inspector view. It utilizes a comparator closure to determine the sorting logic.
@available(iOS 16.4, *)
public extension PropertyInspector {

    /// Defines the type for the sorting comparator closure, which takes two `Value` instances
    /// and returns a `Bool` indicating whether the first value should be ordered before the second.
    typealias ValueComparator = (_ lhs: Value, _ rhs: Value) -> Bool

    /// Modifies the current `PropertyInspector` to sort its items using the provided comparator
    /// when presenting the property list.
    ///
    /// - Parameter comparator: A closure that takes two values of the `Value` type and returns a
    ///   Boolean value indicating whether the first value should come before the second value in the sorted list.
    ///
    /// - Returns: A new `PropertyInspector` instance with sorting applied.
    ///
    /// Usage example:
    /// ```
    /// @State private var isInspectorPresented = false
    ///
    /// var body: some View {
    ///     PropertyInspector("Properties", MyValueType.self, isPresented: $isInspectorPresented) {
    ///         // Main content view goes here
    ///     } icon: { value in
    ///         Image(systemName: "gear")
    ///     } label: { value in
    ///         Text("Property \(value)")
    ///     }
    ///     .sort { lhs, rhs in
    ///         // Sorting logic goes here
    ///         return lhs.propertyName < rhs.propertyName
    ///     }
    /// }
    /// ```
    ///
    /// The `sort(by:)` function can be called on a `PropertyInspector` instance to provide custom sorting
    /// for the items it displays, based on properties of `Value`. This can be particularly useful when the
    /// order of properties impacts the user experience, or when a logical grouping is needed.
    func sort(by comparator: @escaping ValueComparator) -> Self {
        var copy = self
        copy.comparator = {
            comparator($0.value, $1.value)
        }
        return copy
    }

    /// Defines the type for the sorting comparator closure, which takes two wrapped `Value` instances
    /// and returns a `Bool` indicating whether the first value should be ordered before the second.
    typealias ItemComparator = (_ lhs: Item, _ rhs: Item) -> Bool

    /// Modifies the current `PropertyInspector` to sort its items using the provided comparator
    /// when presenting the property list.
    ///
    /// - Parameter comparator: A closure that takes two values of the wraped `Value` type and returns a
    ///   Boolean value indicating whether the first value should come before the second value in the sorted list.
    ///
    /// - Returns: A new `PropertyInspector` instance with sorting applied.
    ///
    /// Usage example:
    /// ```
    /// @State private var isInspectorPresented = false
    ///
    /// var body: some View {
    ///     PropertyInspector("Properties", MyValueType.self, isPresented: $isInspectorPresented) {
    ///         // Main content view goes here
    ///     } icon: { value in
    ///         Image(systemName: "gear")
    ///     } label: { value in
    ///         Text("Property \(value)")
    ///     }
    ///     .sort { lhs, rhs in
    ///         // Sorting logic goes here
    ///         return lhs.value.propertyName && lhs.file < rhs.value.propertyName && rhs.file
    ///     }
    /// }
    /// ```
    ///
    /// The `sort(by:)` function can be called on a `PropertyInspector` instance to provide custom sorting
    /// for the items it displays, based on properties of `Value`. This can be particularly useful when the
    /// order of properties impacts the user experience, or when a logical grouping is needed.
    func sort(by comparator: @escaping ItemComparator) -> Self {
        var copy = self
        copy.comparator = comparator
        return copy
    }
}


public extension View {
    /// Attaches a property inspector to the view, which can be used to inspect the specified value when
    /// the inspector is presented. The view will collect information about the property and make it available
    /// for inspection in the UI.
    ///
    /// - Parameters:
    ///   - value: The value to be inspected. It can be of any type.
    ///   - function: The name of the function from where the inspector is called, typically left as the default.
    ///   - line: The line number in the file from where the inspector is called, typically left as the default.
    ///   - file: The name of the file from where the inspector is called, typically left as the default.
    ///
    /// - Returns: A view modified with a property inspector for the given value.
    ///
    /// Usage example:
    /// ```
    /// struct MyView: View {
    ///     let myProperty = "Example"
    ///
    ///     var body: some View {
    ///         Text("Hello World")
    ///             .inspectProperty(myProperty)
    ///     }
    /// }
    /// ```
    ///
    /// By default, the `inspectProperty` method uses Swift's compile-time literals such as `#function`,
    /// `#line`, and `#file` to capture the context where the property is being inspected. This context
    /// information is used to provide insightful details within the property inspector.
    func inspectProperty<Value>(
        _ value: Value,
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        modifier(
            PropertyInspectorViewModifier(
                value: value,
                location: .init(
                    function: function,
                    file: file,
                    line: line
                )
            )
        )
    }

    /// Disables the property inspection functionality for this view. When inspection is disabled, the view
    /// will not collect property information for the inspector.
    ///
    /// - Parameter disabled: A Boolean value that determines whether the property inspection is disabled.
    ///   The default value is `true`.
    ///
    /// - Returns: A view that conditionally disables property inspection.
    func inspectingDisabled(_ disabled: Bool = true) -> some View {
        environment(\.propertyInspectorDisabled, disabled)
    }

    /// An extension on `View` to set the corner radius for `PropertyInspectorHighlightView`.
    /// This environment value customizes the corner radius applied to the highlight effect
    /// of a property within the inspector.
    ///
    /// - Parameter radius: The corner radius to apply to the property inspector's highlight view.
    ///
    /// - Returns: A view that sets the specified corner radius in the current environment.
    ///
    /// Usage example:
    /// ```
    /// var body: some View {
    ///     MyContentView()
    ///         .propertyInspectorCornerRadius(10) // Applies a corner radius of 10 to the highlight view
    /// }
    /// ```
    ///
    /// When you apply this modifier to a view, the `PropertyInspectorHighlightView` within the
    /// inspector will display with rounded corners of the specified radius. This can be used to
    /// maintain consistent styling within your app, especially if you have a design system with
    /// specific corner radius values.
    func inspectorHighlightCornerRadius(_ radius: CGFloat) -> some View {
        environment(\.propertyInspectorCornerRadius, radius)
    }
}

extension EnvironmentValues {
    var propertyInspectorDisabled: Bool {
        get { self[PropertyInspectorDisabledKey.self] }
        set { self[PropertyInspectorDisabledKey.self] = newValue }
    }
}

struct PropertyInspectorDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 16.4, *)
struct PropertyInspectorList<Value, Label: View, Detail: View, Icon: View>: View {
    typealias Item = PropertyInspectorItem<Value>
    
    let title: String?
    let data: [Item]
    let icon: (Item) -> Icon
    let label: (Item) -> Label
    let detail: (Item) -> Detail

    @State
    private var searchQuery = ""

    private var filteredData: [Item] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return data }
        return data.filter { item in
            "\(type(of: item))-\(item.value)".localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                if filteredData.isEmpty {
                    Text(emptyMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                ForEach(filteredData, content: row(_ :))
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
            "No \(title ?? "items")" :
            "No results for '\(searchQuery)'"
    }

    private var header: some View {
        VStack(spacing: 6) {
            if let title {
                Toggle(sources: filteredData, isOn: \.isHighlighted) {
                    Text(title)
                        .bold()
                        .font(.title2)
                }
            }

            HStack {
                TextField(
                    "Search \(filteredData.count) items",
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

    private func row(_ item: Item) -> some View {
        Toggle(isOn: item.isHighlighted) {
            PropertyInspectorItemRow(
                icon: icon(item),
                label: label(item),
                detail: {
                    if Detail.self == EmptyView.self {
                        Text(item.location.description)
                    } else {
                        detail(item)
                    }
                }
            )
        }
        .listRowBackground(Color.clear)
        .toggleStyle(PropertyInspectorToggleStyle())
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

/// Represents an individual item to be inspected within the Property Inspector.
/// This class encapsulates a single property's value and metadata for display and comparison purposes.
public final class PropertyInspectorItem<Value>: Identifiable, Comparable {
    /// A unique identifier for the inspector item, used to differentiate between items.
    public let id = UUID()

    /// The value of the property being inspected. The type of this value is generic, allowing for flexibility in what can be inspected.
    public let value: Value

    /// The location within the source code where this item was tagged for inspection.
    /// This includes the function name, file name, and line number.
    public let location: PropertyInspectorLocation

    /// A binding to a Boolean value that determines whether this item is currently highlighted within the UI.
    let isHighlighted: Binding<Bool>

    init(value: Value, isHighlighted: Binding<Bool>, location: PropertyInspectorLocation) {
        self.value = value
        self.isHighlighted = isHighlighted
        self.location = location
    }

    public static func == (lhs: PropertyInspectorItem<Value>, rhs: PropertyInspectorItem<Value>) -> Bool {
        lhs.id == rhs.id
    }
    
    public static func < (lhs: PropertyInspectorItem<Value>, rhs: PropertyInspectorItem<Value>) -> Bool {
        lhs.location < rhs.location
    }
}

/// Represents the location within the source code where a `PropertyInspectorItem` was defined.
/// This includes the function or variable name, the file name, and the line number.
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
            return prettyFunctionName
        }
        return "\(fileName):\(line)"
    }()

    /// Provides a formatted version of the function name for readability.
    private var prettyFunctionName: String {
        if function.contains("(") { return "func \(function)" }
        return "var \(function)"
    }

    public static func < (lhs: PropertyInspectorLocation, rhs: PropertyInspectorLocation) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }

    public static func == (lhs: PropertyInspectorLocation, rhs: PropertyInspectorLocation) -> Bool {
        lhs.description == rhs.description
    }
}

@available(iOS 16.0, *)
struct PropertyInspectorItemRow<Icon: View, Label: View, Detail: View>: View {
    let icon: Icon
    let label: Label
    @ViewBuilder var detail: Detail

    var body: some View {
        HStack {
            icon.drawingGroup()

            VStack(alignment: .leading, spacing: 1) {
                Spacer().frame(height: 3) // padding doesn't work

                label
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .bold()

                detail

                Spacer().frame(height: 3) // padding doesn't work
            }
            .foregroundStyle(.secondary)
            .font(.caption2)
        }
        .contentShape(Rectangle())
    }
}

struct PropertyInspectorViewModifier<Value>: ViewModifier  {
    let value: Value
    let location: PropertyInspectorLocation

    @State
    private var isHighlighted = false

    @Environment(\.propertyInspectorDisabled)
    private var disabled

    var data: PropertyInspectorItem<Value> {
        PropertyInspectorItem(
            value: value,
            isHighlighted: $isHighlighted,
            location: location
        )
    }

    func body(content: Content) -> some View {
        if disabled {
            content
        } else {
            PropertyInspectorHighlightView(isOn: $isHighlighted) {
                content.background(
                    Color.clear.preference(
                        key: PropertyInspectorItemKey<Value>.self,
                        value: [data]
                    )
                )
            }
        }
    }
}

struct PropertyInspectorItemKey<Value>: PreferenceKey {
    /// The default value for the dynamic value entries.
    static var defaultValue: [PropertyInspectorItem<Value>] { [] }

    /// Combines the current value with the next value.
    ///
    /// - Parameters:
    ///   - value: The current value of dynamic value entries.
    ///   - nextValue: A closure that returns the next set of dynamic value entries.
    static func reduce(value: inout [PropertyInspectorItem<Value>], nextValue: () -> [PropertyInspectorItem<Value>]) {
        value.append(contentsOf: nextValue())
    }
}

struct PropertyInspectorHighlightCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var propertyInspectorCornerRadius: CGFloat {
        get { self[PropertyInspectorHighlightCornerRadiusKey.self] }
        set { self[PropertyInspectorHighlightCornerRadiusKey.self] = newValue }
    }
}

struct PropertyInspectorHighlightView<Content: View>: View {
    @State
    private var animationToken = UUID()

    @Binding
    var isOn: Bool

    @ViewBuilder 
    var content: Content

    @Environment(\.propertyInspectorCornerRadius)
    private var cornerRadius

    var transition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: .random(in: 2 ... 2.5))),
            removal: .identity
        )
    }

    var body: some View {
        content
            .zIndex(isOn ? 999 : 0)
            .overlay {
                if isOn {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(lineWidth: 1.5)
                        .fill(Color.blue)
                        .id(animationToken)
                        .transition(transition)
                }
            }
            .compositingGroup()
            .onChange(of: isOn) { newValue in
                guard newValue else { return }
                animationToken = UUID()
            }
            .animation(animation, value: animationToken)
    }

    var animation: Animation {
        .snappy(
            duration: .random(in: 0.2 ... 0.6),
            extraBounce: .random(in: 0 ... 0.1))
        .delay(.random(in: 0 ... 0.2))
    }
}
