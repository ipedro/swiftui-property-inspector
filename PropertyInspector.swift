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
                    PropertyInspectorList(title: {
                        if let title { return Text(title) }
                        return nil
                    }())
                }
            }
            .onPreferenceChange(PropertyPreferenceKey.self) {
                let newValue = ($0).sorted()
                if newValue != data.properties {
                    data.properties = newValue
                }
            }
            .onPreferenceChange(RowDetailPreferenceKey.self) { data.details = $0 }
            .onPreferenceChange(RowIconPreferenceKey.self) { data.icons = $0  }
            .onPreferenceChange(RowLabelPreferenceKey.self) { data.labels = $0 }
            .environmentObject(data)
    }
}

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
        changePreference(RowIconPreferenceKey.self, content: icon)
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
        changePreference(RowLabelPreferenceKey.self, content: label)
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
        changePreference(RowDetailPreferenceKey.self, content: detail)
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
        _ values: [Any],
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        modifier(
            PropertyViewModifier(
                data: values,
                location: .init(
                    function: function,
                    file: file,
                    line: line
                )
            )
        )
    }

    /// Hides this view and its children from the property inspection.
    func propertyInspectorHidden(_ hidden: Bool = true) -> some View {
        environment(\.propertyInspectorHidden, hidden)
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
    func propertyInspectorCornerRadius(_ radius: CGFloat) -> some View {
        environment(\.propertyInspectorCornerRadius, radius)
    }
}

/// Represents an individual item to be inspected within the Property Inspector.
/// This class encapsulates a single property's value and metadata for display and comparison purposes.
private struct Property: Identifiable, Comparable, CustomStringConvertible, Hashable {
    /// A unique identifier for the inspector item, used to differentiate between items.
    let id = UUID()

    /// The value of the property being inspected. The type of this value is generic, allowing for flexibility in what can be inspected.
    let value: Any

    /// A binding to a Boolean value that determines whether this item is currently highlighted within the UI.
    @Binding var isHighlighted: Bool

    /// The location within the source code where this item was tagged for inspection.
    /// This includes the function name, file name, and line number.
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
        location: PropertyLocation,
        level: Int,
        index: Int
    ) {
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
        self.sortString = [
            String(level) + String(index),
            location.id,
            String(describing: value)
        ].joined(separator: "_")
    }

    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id
    }

    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents the location within the source code where a `PropertyInspectorItem` was defined.
/// This includes the function or variable name, the file name, and the line number.
struct PropertyLocation: Identifiable, Comparable, CustomStringConvertible {
    let id: String

    /// The name of the function or variable where the inspection item is defined.
    let function: String

    /// The full path of the file where the inspection item is defined.
    let file: String

    /// The line number within the file where the inspection item is defined.
    let line: Int

    init(function: String, file: String, line: Int) {
        let fileName = URL(string: file)?.lastPathComponent ?? file

        self.id = "\(file):\(line):\(function)"
        self.description = "\(fileName):\(line)"
        self.function = function
        self.file = file
        self.line = line
    }

    /// A textual description of the location, includes the file name (without the full path) and the line number.
    let description: String

    static func < (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
    }

    static func == (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id == rhs.id
    }
}

private final class PropertyInspectorStorage: ObservableObject {
    @Published var searchQuery = ""
    @Published var properties = [Property]() {
        didSet {
            print(properties)
        }
    }
    @Published var icons = [String: RowViewBuilder]()
    @Published var labels = [String: RowViewBuilder]()
    @Published var details = [String: RowViewBuilder]()

    var emptyMessage: Text? {
        guard searchResults.isEmpty else { return nil }
        let message = searchQuery.isEmpty ?
        "Nothing to inspect" :
        "No results for '\(searchQuery)'"

        return Text(message)
    }

    var searchResults: [Property] {
        lazy var query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !properties.isEmpty,
            !query.isEmpty,
            query.count > 1
        else {
            return properties
        }
        return properties.filter { item in
            (item.stringValue + item.location.description).localizedCaseInsensitiveContains(query)
        }
    }
}

@available(iOS 16.4, *)
private struct PropertyInspectorList: View {
    let title: Text?

    var body: some View {
        List {
            Section {
                PropertyInspectorRows().listRowBackground(Color.clear)
            } header: {
                PropertyInspectorHeader(title: title)
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
}

private struct PropertyInspectorRows: View {
    @EnvironmentObject
    private var data: PropertyInspectorStorage

    var body: some View {
        data.emptyMessage?
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

        ForEach(data.searchResults) {
            PropertyRow(
                data: $0,
                icon: makeBody(configuration: ($0, data.icons)),
                label: makeBody(configuration: ($0, data.labels)),
                detail: makeBody(configuration: ($0, data.details))
            )
        }
        .toggleStyle(PropertyInspectorToggleStyle(alignment: .firstTextBaseline))
    }

    private func makeBody(configuration: (item: Property, source: [String: RowViewBuilder])) -> AnyView? {
        for key in configuration.source.keys {
            if let view = configuration.source[key]?.view(configuration.item.value) {
                return view
            }
        }
        return nil
    }
}

private struct PropertyInspectorHeader: View {
    let title: Text?

    @EnvironmentObject
    private var data: PropertyInspectorStorage

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            title?
                .bold()
                .font(.title2)

            TextField(
                "Search \(data.searchResults.count) items",
                text: $data.searchQuery
            )
            .frame(maxWidth: .infinity)

            if #available(iOS 16.0, *) {
                Toggle(sources: data.searchResults, isOn: \.$isHighlighted) {
                    EmptyView()
                }
            }
        }
        .foregroundStyle(.primary)
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
                    if #available(iOS 16.0, *), configuration.isMixed { return "minus.circle.fill" }
                    if configuration.isOn { return "checkmark.circle.fill" }
                    return "circle"
                }())
            }
        }
    }
}

private struct PropertyViewModifier: ViewModifier  {
    let data: [Any]
    let location: PropertyLocation

    @State
    private var isHighlighted = false

    @Environment(\.propertyInspectorHidden)
    private var hidden

    @State
    private var level = 0

    private var properties: [Property] {
        if hidden { return [] }
        return data.enumerated().map { (offset, value) in
            Property(
                value: value,
                isHighlighted: $isHighlighted,
                location: location,
                level: level,
                index: offset
            )
        }
    }

    func body(content: Content) -> some View {
        PropertyHighlight(isOn: $isHighlighted) {
            content
                .changePreference(PropertyPreferenceKey.self, value: properties)
                .changePreference(LevelPreferenceKey.self, value: level + 1)
        }
        .onPreferenceChange(LevelPreferenceKey.self) { value in
            level = value
        }
    }
}

// MARK: - Preference View Modifiers

private extension View {
    func changePreference<K: PreferenceKey>(
        _ key: K.Type,
        value: K.Value
    ) -> some View where K.Value: Hashable {
        modifier(PreferenceKeyChangeModifier(key, value))
    }

    func changePreference<K: PreferenceKey, C: View, T>(
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
        return modifier(PreferenceKeyChangeModifier(key, value))
    }
}

/// A modifier that you apply to a view or another view modifier to set a value for any given preference key.
private struct PreferenceKeyChangeModifier<K: PreferenceKey>: ViewModifier where K.Value: Hashable {
    let value: K.Value

    init(_ key: K.Type = K.self, _ value: K.Value) {
        self.value = value
    }

    func body(content: Content) -> some View {
        content.background(
            Color.clear
                .preference(key: K.self, value: value)
        )
    }
}

// MARK: - Preference Keys

private struct PropertyPreferenceKey: PreferenceKey {
    /// The default value for the dynamic value entries.
    static var defaultValue: [Property] { [] }

    /// Combines the current value with the next value.
    ///
    /// - Parameters:
    ///   - value: The current value of dynamic value entries.
    ///   - nextValue: A closure that returns the next set of dynamic value entries.
    static func reduce(value: inout [Property], nextValue: () -> [Property]) {
        value.append(contentsOf: nextValue())
    }
}

private struct RowDetailPreferenceKey: PreferenceKey {
    static let defaultValue = [String: RowViewBuilder]()
    static func reduce(value: inout [String: RowViewBuilder], nextValue: () -> [String: RowViewBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

private struct RowIconPreferenceKey: PreferenceKey {
    static let defaultValue = [String: RowViewBuilder]()
    static func reduce(value: inout [String: RowViewBuilder], nextValue: () -> [String: RowViewBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

private struct RowLabelPreferenceKey: PreferenceKey {
    static let defaultValue = [String: RowViewBuilder]()
    static func reduce(value: inout [String: RowViewBuilder], nextValue: () -> [String: RowViewBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

private struct LevelPreferenceKey: PreferenceKey {
    static let defaultValue: Int = 0
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value += nextValue()
    }
}

// MARK: - Environment Keys

private struct CornerRadiusEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct DisabledEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private extension EnvironmentValues {
    var propertyInspectorCornerRadius: CGFloat {
        get { self[CornerRadiusEnvironmentKey.self] }
        set { self[CornerRadiusEnvironmentKey.self] = newValue }
    }

    var propertyInspectorHidden: Bool {
        get { self[DisabledEnvironmentKey.self] }
        set { self[DisabledEnvironmentKey.self] = newValue }
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

private struct PropertyHighlight<Content: View>: View {
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
        Self._printChanges()
        return content
            .zIndex(isOn ? 999 : 0)
            .overlay {
                if isOn {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(style:  StrokeStyle(
                            lineWidth: 1.5,
                            lineCap: .round,
                            lineJoin: .round
                        ))
                        .fill(Color.blue)
                        .id(animationToken)
                        .transition(transition)
                }
            }
            .onChange(of: isOn) { newValue in
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

private struct PropertyRow: View, Equatable {
    static func == (lhs: PropertyRow, rhs: PropertyRow) -> Bool {
        lhs.data == rhs.data
    }

    var data: Property
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
