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
                data: values,
                location: .init(
                    function: function,
                    file: file,
                    line: line
                )
            )
        )
    }

    /// Hides the view and its children from property inspection.
    ///
    /// - Returns: A view that unconditionally disables property inspection.
    func propertyInspectorHidden() -> some View {
        environment(\.propertyInspectorHidden, true)
    }

    /// This environment value customizes the corner radius applied to the highlight effect
    /// of a property within the inspector.
    ///
    /// - Parameter radius: The corner radius to apply to the property inspector's highlight view.
    ///
    /// - Returns: A view that sets the specified corner radius in the current environment.
   func propertyInspectorCornerRadius(_ radius: CGFloat) -> some View {
        environment(\.propertyInspectorCornerRadius, radius)
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
        setPreferenceChange(RowIconPreferenceKey.self, body: icon)
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
        setPreferenceChange(RowLabelPreferenceKey.self, body: label)
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
        setPreferenceChange(RowDetailPreferenceKey.self, body: detail)
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

    @State
    private var bottomInset: Double = 0

    @StateObject
    private var data = PropertyInspectorStorage()

    /// Initializes a `PropertyInspector` with the most detailed configuration, including title, content,
    /// icon, label, and detail views for each property.
    ///
    /// - Parameters:
    ///   - title: An optional title for the property inspector pane.
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

    public var body: some View {
        // Do not change the following order:
        //   1. view modifiers
        //   2. data listeners
        //   3. data store
        content
            // 1. view modifiers
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Spacer().frame(height: bottomInset)
            }
            .toolbar {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: isPresented ? "xmark.circle.fill" : "magnifyingglass.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .rotationEffect(.degrees(isPresented ? 180 : 0))
                        .font(.title3)

                }
            }
            .animation(.snappy, value: isPresented)
            .modifier(
                PropertyInspectorSheetModifier(
                    isPresented: $isPresented,
                    title: title
                )
            )
            // 2. data listeners
            .onPreferenceChange(PropertyPreferenceKey.self, perform: { newValue in
                let uniqueProperties = newValue
                    .removingDuplicates()
                    .sorted()

                if data.properties != uniqueProperties {
                    data.properties = uniqueProperties
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
            .onChange(of: isPresented) { _ in
                bottomInset = isPresented ? UIScreen.main.bounds.midY : 0
            }
            // 3. data store
            .environmentObject(data)
    }
}

// MARK: - Private Extensions

private extension View {
    func setPreferenceChange<K: PreferenceKey>(
        _ key: K.Type,
        value: K.Value
    ) -> some View {
        modifier(PreferenceChangeModifier(key, value))
    }

    func setPreferenceChange<K: PreferenceKey, C: View, T>(
        _ key: K.Type,
        @ViewBuilder body: @escaping (T) -> C
    ) -> some View where K.Value == [String: PropertyRowBuilder] {
        let dataType = String(describing: T.self)
        let viewBuilder = PropertyRowBuilder { value in
            if let castedValue = value as? T {
                return AnyView(body(castedValue))
            }
            return nil
        }
        let value = [dataType: viewBuilder]
        return modifier(PreferenceChangeModifier(key, value))
    }
}

private extension Collection where Element: Identifiable {
    func removingDuplicates() -> [Element] {
        var seenIDs = Set<Element.ID>()
        return filter {
            seenIDs.insert($0.id).inserted
        }
    }
}

@available(iOS 16.4, *)
private struct PropertyInspectorSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String?

    func body(content: Content) -> some View {
        content.overlay {
            Spacer().sheet(isPresented: $isPresented) {
                PropertyInspectorList(title: title)
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
            }
        }
    }
}

private struct PropertyInspectorList: View {
    let title: String?

    @EnvironmentObject
    private var data: PropertyInspectorStorage

    var body: some View {
        let rows = data.rows
        List {
            Section {
                Rows(
                    data: data.rows,
                    icons: data.rowIcons,
                    labels: data.rowLabels,
                    details: data.rowDetails,
                    emptyMessage: {
                        data.searchQuery.isEmpty ?
                        "Empty" :
                        "No results for '\(data.searchQuery)'"
                    }
                )
                .listRowBackground(Color.clear)
            } header: {
                Header(
                    title: title,
                    data: rows,
                    searchQuery: $data.searchQuery
                )
                .equatable()
            }
        }
        .tint(.primary)
        .multilineTextAlignment(.leading)
        .toggleStyle(PropertyInspectorToggleStyle(alignment: .firstTextBaseline))
        .symbolRenderingMode(.hierarchical)
    }

    private struct Rows: View {
        let data: PropertyPreferenceKey.Value
        let icons: RowIconPreferenceKey.Value
        let labels: RowLabelPreferenceKey.Value
        let details: RowDetailPreferenceKey.Value
        let emptyMessage: () -> String

        @ViewBuilder
        var body: some View {
            {
                Self._printChanges()
                return EmptyView()
            }()
            if data.isEmpty {
                Text(emptyMessage())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height / 5)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .multilineTextAlignment(.center)
            }

            ForEach(data) { row in
                Row(
                    data: row,
                    customIcon: makeBody(configuration: (row, icons)),
                    customLabel: makeBody(configuration: (row, labels)),
                    customDetails: makeBody(configuration: (row, details))
                )
                .equatable()
            }
        }

        private func makeBody(configuration: (item: Property, source: [String: PropertyRowBuilder])) -> AnyView? {
            for key in configuration.source.keys {
                if let view = configuration.source[key]?.view(configuration.item.value) {
                    return view
                }
            }
            return nil
        }
    }

    private struct Header: View, Equatable {
        static func == (lhs: PropertyInspectorList.Header, rhs: PropertyInspectorList.Header) -> Bool {
            lhs.data == rhs.data &&
            lhs.searchQuery == rhs.searchQuery &&
            lhs.title == rhs.title
        }

        let title: String?
        let data: PropertyPreferenceKey.Value
        @Binding var searchQuery: String

        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                if let title {
                    Text(title).bold().font(.title2)
                }

                TextField(
                    "Search \(data.count) items",
                    text: $searchQuery
                )
                .frame(maxWidth: .infinity)

                if #available(iOS 16.0, *) {
                    Toggle(sources: data, isOn: \.$isHighlighted) {
                        EmptyView()
                    }
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

    private struct Row: View, Equatable {
        static func == (lhs: PropertyInspectorList.Row, rhs: PropertyInspectorList.Row) -> Bool {
            lhs.data == rhs.data
        }

        var data: Property
        var customIcon: AnyView?
        var customLabel: AnyView?
        var customDetails: AnyView?

        private func icon() -> some View {
            Group {
                if let customIcon { customIcon }
                else { Image(systemName: "info.circle.fill") }
            }
            .font(.caption)
            .frame(minWidth: 20, alignment: .leading)
        }
        
        private func label() -> some View {
            Group {
                if let customLabel { customLabel }
                else { Text(verbatim: data.stringValue).minimumScaleFactor(0.8) }
            }
            .font(.footnote.bold())
            .foregroundStyle(.primary)
        }
        
        @ViewBuilder
        private func details() -> some View {
            if let customDetails { customDetails }
            else { Text(verbatim: data.location.description) }
        }
        
        var body: some View {
            Self._printChanges()
            return Toggle(isOn: data.$isHighlighted) {
                HStack(alignment: .firstTextBaseline) {
                    icon()
                    VStack(alignment: .leading, spacing: 1) {
                        label()
                        details()
                    }
                }
                .foregroundStyle(.secondary)
                .allowsTightening(true)
                .font(.caption2)
                .contentShape(Rectangle())
            }
            .listRowBackground(Color.clear)
            .toggleStyle(PropertyInspectorToggleStyle(alignment: .firstTextBaseline))
        }
    }
}

// MARK: - Custom Styles

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

// MARK: - View Modifiers

/// A modifier that you apply to a view or another view modifier to set a value for any given preference key.
private struct PreferenceChangeModifier<K: PreferenceKey>: ViewModifier {
    let value: K.Value

    init(_ key: K.Type = K.self, _ value: K.Value) {
        self.value = value
    }

    func body(content: Content) -> some View {
        content.background(
            Spacer().preference(key: K.self, value: value)
        )
    }
}

private struct PropertyInspectorViewModifier: ViewModifier  {
    let data: [Any]
    let location: PropertyLocation

    @State
    private var isOn = false

    @Environment(\.propertyInspectorHidden)
    private var disabled

    @Environment(\.propertyInspectorCornerRadius)
    private var cornerRadius

    func body(content: Content) -> some View {
        content
            .setPreferenceChange(PropertyPreferenceKey.self, value: properties)
            .zIndex(isOn ? 999 : 0)
            .overlay {
                if isOn {
                    RoundedRectangle(cornerRadius: cornerRadius)
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

    private var properties: PropertyPreferenceKey.Value {
        if disabled { return [] }
        return data.enumerated().map { (index, value) in
            Property(
                value: value,
                isHighlighted: $isOn,
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

// MARK: - Preferences

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

private struct TitlePreferenceKey: PreferenceKey {
    static let defaultValue = LocalizedStringKey("Properties")
    static func reduce(value: inout LocalizedStringKey, nextValue: () -> LocalizedStringKey) {}
}

private struct RowDetailPreferenceKey: PreferenceKey {
    static let defaultValue = [String: PropertyRowBuilder]()
    static func reduce(value: inout [String: PropertyRowBuilder], nextValue: () -> [String: PropertyRowBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

private struct RowIconPreferenceKey: PreferenceKey {
    static let defaultValue = [String: PropertyRowBuilder]()
    static func reduce(value: inout [String: PropertyRowBuilder], nextValue: () -> [String: PropertyRowBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

private struct RowLabelPreferenceKey: PreferenceKey {
    static let defaultValue = [String: PropertyRowBuilder]()
    static func reduce(value: inout [String: PropertyRowBuilder], nextValue: () -> [String: PropertyRowBuilder]) {
        value.merge(nextValue()) { content, _ in
            content
        }
    }
}

// MARK: - Environment Values

private struct PropertyInspectorHighlightCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct PropertyInspectorHiddenKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private extension EnvironmentValues {
    var propertyInspectorCornerRadius: CGFloat {
        get { self[PropertyInspectorHighlightCornerRadiusKey.self] }
        set { self[PropertyInspectorHighlightCornerRadiusKey.self] = newValue }
    }

    var propertyInspectorHidden: Bool {
        get { self[PropertyInspectorHiddenKey.self] }
        set { self[PropertyInspectorHiddenKey.self] = newValue }
    }
}

// MARK: - Models

private final class PropertyInspectorStorage: ObservableObject {
    @Published
    var properties = PropertyPreferenceKey.Value()

    @Published
    var searchQuery = ""

    var rows: PropertyPreferenceKey.Value {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return properties }
        return properties.filter {
            String(describing: $0).localizedCaseInsensitiveContains(query)
        }
    }

    @Published
    var rowDetails = RowDetailPreferenceKey.Value()

    @Published
    var rowIcons = RowIconPreferenceKey.Value()

    @Published
    var rowLabels = RowLabelPreferenceKey.Value()
}

private struct PropertyRowBuilder: Equatable, Identifiable {
    let id = UUID()
    let view: (Any) -> AnyView?

    static func == (lhs: PropertyRowBuilder, rhs: PropertyRowBuilder) -> Bool {
        lhs.id == rhs.id
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
    @Binding
    var isHighlighted: Bool

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
        index: Int
    ) {
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
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

/// Represents the location within the source code where a `Property` was defined.
/// This includes the function or variable name, the file name, and the line number.
private struct PropertyLocation: Identifiable, Comparable, CustomStringConvertible {
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
