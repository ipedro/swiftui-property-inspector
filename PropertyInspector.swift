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

public extension View {
    /// Registers a custom icon view for a specific type to be used in the Property Inspector's UI.
    ///
    /// This function allows you to provide a custom icon representation for a given type when displayed in the property inspector. The icon view is constructed using the provided value of the specified type.
    ///
    /// Usage Example:
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Hello, World!")
    ///             .propertyInspectorRowIcon(for: String.self) { stringValue in
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
    func propertyInspectorRowIcon<Value, Icon: View>(
        for type: Value.Type,
        @ViewBuilder icon: @escaping (Value) -> Icon
    ) -> some View {
        setPreferenceChange(RowIconPreference.self, content: icon)
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
    ///             .propertyInspectorRowLabel(for: String.self) { stringValue in
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
    func propertyInspectorRowLabel<Value, Label: View>(
        for type: Value.Type,
        @ViewBuilder label: @escaping (Value) -> Label
    ) -> some View {
        setPreferenceChange(RowLabelPreference.self, content: label)
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
    ///             .propertyInspectorRowDetail(for: String.self) { stringValue in
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
    func propertyInspectorRowDetail<Value, Detail: View>(
        for type: Value.Type,
        @ViewBuilder detail: @escaping (Value) -> Detail
    ) -> some View {
        setPreferenceChange(RowDetailPreference.self, content: detail)
    }

    /// Attaches a property inspector to the view, which can be used to inspect the specified value when
    /// the inspector is presented. The view will collect information about the property and make it available
    /// for inspection in the UI.
    ///
    /// - Parameters:
    ///   - values: The values to be inspected. It can be of any type.
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
public struct PropertyInspector<Content: View>: View {
    private var title: String?

    private var content: Content

    @Binding
    private var isPresented: Bool

    @StateObject
    private var data = PropertyInspectorStorage()

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
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isPresented = isPresented
        self.content = content()
    }

    private var bottomInset: CGFloat {
        isPresented ? UIScreen.main.bounds.midY : 0
    }

    public var body: some View {
        content
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
                    PropertyInspectorList(title: title)
                }
            }
            .onPreferenceChange(PropertyInspectorItemKey.self) {
                let newValue = Set($0).sorted()
                if newValue != data.properties {
                    data.properties = newValue
                }
            }
            .onPreferenceChange(RowDetailPreference.self) { data.details = $0 }
            .onPreferenceChange(RowIconPreference.self) { data.icons = $0  }
            .onPreferenceChange(RowLabelPreference.self) { data.labels = $0 }
            .environmentObject(data)
    }
}

/// Represents an individual item to be inspected within the Property Inspector.
/// This class encapsulates a single property's value and metadata for display and comparison purposes.
private final class PropertyInspectorItem: Identifiable, Comparable, CustomStringConvertible, Hashable {
    /// A unique identifier for the inspector item, used to differentiate between items.
    let id = UUID()

    /// The value of the property being inspected. The type of this value is generic, allowing for flexibility in what can be inspected.
    let value: Any

    /// A binding to a Boolean value that determines whether this item is currently highlighted within the UI.
    @Binding var isHighlighted: Bool

    /// The location within the source code where this item was tagged for inspection.
    /// This includes the function name, file name, and line number.
    let location: PropertyInspectorLocation

    let index: Int

    var description: String {
        "\(location) — \(stringValue)"
    }

    var stringValueType: String {
        String(
            describing: type(of: value)
        )
    }

    var stringValue: String {
        String(describing: value)
    }

    private var sortString: String {
        "\(location):\(index):\(stringValue)"
    }

    init(
        value: Any,
        isHighlighted: Binding<Bool>,
        location: PropertyInspectorLocation,
        index: Int
    ) {
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
        self.index = index
    }

    static func == (lhs: PropertyInspectorItem, rhs: PropertyInspectorItem) -> Bool {
        lhs.id == rhs.id
    }

    static func < (lhs: PropertyInspectorItem, rhs: PropertyInspectorItem) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents the location within the source code where a `PropertyInspectorItem` was defined.
/// This includes the function or variable name, the file name, and the line number.
final class PropertyInspectorLocation: Comparable, CustomStringConvertible {
    /// The name of the function or variable where the inspection item is defined.
    let function: String

    /// The full path of the file where the inspection item is defined.
    let file: String

    /// The line number within the file where the inspection item is defined.
    let line: Int

    init(function: String, file: String, line: Int) {
        self.function = function
        self.file = file
        self.line = line
    }

    /// A textual description of the location, typically used for display purposes.
    /// This includes the file name (without the full path) and the line number.
    private(set) lazy var description: String = {
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

    static func < (lhs: PropertyInspectorLocation, rhs: PropertyInspectorLocation) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }

    static func == (lhs: PropertyInspectorLocation, rhs: PropertyInspectorLocation) -> Bool {
        lhs.description == rhs.description
    }
}


private final class PropertyInspectorStorage: ObservableObject {
    @Published var searchQuery = ""
    @Published var properties = [PropertyInspectorItem]()
    @Published var icons = [String: RowViewBuilder]()
    @Published var labels = [String: RowViewBuilder]()
    @Published var details = [String: RowViewBuilder]()

    var valuesMatchingSearchQuery: [PropertyInspectorItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query.count > 1 else { return properties }
        return properties.filter { item in
            String(describing: item).localizedCaseInsensitiveContains(query)
        }
    }
}

@available(iOS 16.4, *)
private struct PropertyInspectorList: View {
    typealias Item = PropertyInspectorItem

    let title: String?

    @EnvironmentObject
    private var data: PropertyInspectorStorage

    @State
    private var searchQuery = ""

    private var filteredData: [PropertyInspectorItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return data.properties }
        return data.properties.filter {
            String(describing: $0).localizedCaseInsensitiveContains(query)
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

                ForEach(filteredData) {
                    PropertyInspectorRow(
                        data: $0,
                        icon: makeBody(configuration: ($0, data.icons)),
                        label: makeBody(configuration: ($0, data.labels)),
                        detail: makeBody(configuration: ($0, data.details))
                    )
                    .listRowBackground(Color.clear)
                }
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
        Toggle(sources: filteredData, isOn: \.$isHighlighted) {
            HStack(alignment: .firstTextBaseline) {
                if let title {
                    Text(title).bold().font(.title2)
                }
                TextField(
                    "Search \(filteredData.count) items",
                    text: $searchQuery
                )
            }
            .padding(
                EdgeInsets(
                    top: 16,
                    leading: 0,
                    bottom: 8,
                    trailing: 0
                )
            )
            .tint(.primary)
        }
    }

    private func makeBody(configuration: (item: Item, source: [String: RowViewBuilder])) -> AnyView? {
        for key in configuration.source.keys {
            if let view = configuration.source[key]?.view(configuration.item.value) {
                return view
            }
        }
        return nil
    }
}

private struct PropertyInspectorToggleStyle: ToggleStyle {
    var alignment: VerticalAlignment = .center

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: alignment) {
                configuration.label
                Spacer()
                Image(systemName: {
                    if #available(iOS 16.0, *), configuration.isMixed { return "minus.circle" }
                    if configuration.isOn { return "checkmark.circle.fill" }
                    return "circle"
                }())
            }
        }
    }
}

private struct PropertyInspectorViewModifier: ViewModifier  {
    let values: [Any]
    let location: PropertyInspectorLocation

    @State
    private var isHighlighted = false

    @Environment(\.propertyInspectorDisabled)
    private var disabled

    var data: [PropertyInspectorItem] {
        if disabled { return [] }
        return values.enumerated().map { (offset, value) in
            PropertyInspectorItem(
                value: value,
                isHighlighted: $isHighlighted,
                location: location,
                index: offset
            )
        }
    }

    func body(content: Content) -> some View {
        PropertyInspectorHighlightView(isOn: $isHighlighted) {
            content.background(
                Color.clear.preference(
                    key: PropertyInspectorItemKey.self,
                    value: data
                )
            )
        }
    }
}

// MARK: - Preference View Modifiers

private extension View {
    func setPreferenceChange<K: PreferenceKey>(
        _ key: K.Type,
        value: K.Value
    ) -> some View where K.Value: Hashable {
        modifier(PreferenceValueModifier(key, value))
    }

    func setPreferenceChange<K: PreferenceKey, C: View, T>(
        _ key: K.Type,
        @ViewBuilder content: @escaping (T) -> C
    ) -> some View where K.Value == [String: RowViewBuilder] {
        let dataType = String(describing: T.self)
        let viewBuilder = RowViewBuilder { value in
            if let castedValue = value as? T {
                return AnyView(content(castedValue))
            }
            return nil
        }
        let value = [dataType: viewBuilder]
        return modifier(PreferenceValueModifier(key, value))
    }
}

/// A modifier that you apply to a view or another view modifier to set a value for any given preference key.
private struct PreferenceValueModifier<K: PreferenceKey>: ViewModifier where K.Value: Hashable {
    let value: K.Value

    init(_ key: K.Type = K.self, _ value: K.Value) {
        self.value = value
    }

    func body(content: Content) -> some View {
        content.background(
            Color.clear.preference(key: K.self, value: value).id(String(describing: value))
        )
    }
}

// MARK: - Preference Keys

private struct PropertyInspectorItemKey: PreferenceKey {
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

private struct RowDetailPreference: PreferenceKey {
    static let defaultValue = [String: RowViewBuilder]()
    static func reduce(value: inout [String: RowViewBuilder], nextValue: () -> [String: RowViewBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

private struct RowIconPreference: PreferenceKey {
    static let defaultValue = [String: RowViewBuilder]()
    static func reduce(value: inout [String: RowViewBuilder], nextValue: () -> [String: RowViewBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

private struct RowLabelPreference: PreferenceKey {
    static let defaultValue = [String: RowViewBuilder]()
    static func reduce(value: inout [String: RowViewBuilder], nextValue: () -> [String: RowViewBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

// MARK: - Environment Keys

private struct PropertyInspectorHighlightCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct PropertyInspectorDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private extension EnvironmentValues {
    var propertyInspectorCornerRadius: CGFloat {
        get { self[PropertyInspectorHighlightCornerRadiusKey.self] }
        set { self[PropertyInspectorHighlightCornerRadiusKey.self] = newValue }
    }

    var propertyInspectorDisabled: Bool {
        get { self[PropertyInspectorDisabledKey.self] }
        set { self[PropertyInspectorDisabledKey.self] = newValue }
    }
}

// MARK: - Row Builder

private struct RowViewBuilder: Hashable, Identifiable {
    let id = UUID()
    let view: (Any) -> AnyView?

    static func == (lhs: RowViewBuilder, rhs: RowViewBuilder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private struct PropertyInspectorHighlightView<Content: View>: View {
    @State
    private var animationToken = UUID()

    @Binding
    var isOn: Bool

    @ViewBuilder
    var content: Content

    @Environment(\.propertyInspectorCornerRadius)
    private var cornerRadius

    @Environment(\.propertyInspectorDisabled)
    private var disabled

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
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(lineWidth: 1.5)
                        .fill(Color.blue)
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

private struct PropertyInspectorRow: View {
    var data: PropertyInspectorItem
    var icon: AnyView?
    var label: AnyView?
    var detail: AnyView?

    var body: some View {
        Toggle(isOn: data.$isHighlighted) {
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if let icon {
                        icon
                    } else {
                        Image(systemName: "info.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .font(.footnote.bold())

                VStack(alignment: .leading, spacing: 1) {
                    Spacer().frame(height: 3) // padding doesn't work

                    Group {
                        if let label {
                            label
                        } else {
                            Text(verbatim: String(describing: data.value))
                        }
                    }
                    .font(.footnote.bold())
                    .foregroundStyle(.primary)

                    if let detail {
                        detail
                    } else {
                        Text(verbatim: data.location.function) +
                        Text(verbatim: " — ") +
                        Text(verbatim: data.location.description)
                    }

                    Spacer().frame(height: 3) // padding doesn't work
                }
            }
            .foregroundStyle(.secondary)
            .font(.caption2)
            .multilineTextAlignment(.leading)
        }
    }
}
