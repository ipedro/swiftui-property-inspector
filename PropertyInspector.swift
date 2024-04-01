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
/// ```swift
/// @State private var isInspectorPresented: Bool = false
///
/// var body: some View {
///    PropertyInspector(initialHighlight: true) {
///        let foreground = HierarchicalShapeStyle.primary
///        let padding: Double = 20
///
///        VStack(alignment: .center, content: {
///            Button {
///                // action
///            } label: {
///                Text("Button").inspectSelf()
///            }
///            .foregroundStyle(foreground)
///            .inspectProperty(
///                foreground,
///                function: "foregroundStyle()")
///            .padding(padding)
///            .inspectProperty(
///                padding,
///                function: "padding()")
///        })
///        .frame(maxWidth: .infinity)
///    }
///    .propertyInspectorTint(.cyan)
///    .propertyInspectorStyle(.sheet(isPresented: .constant(true)))
/// }
/// ```
///
/// The `PropertyInspector` leverages SwiftUI's preference system to collect property information
/// from descendant views into a consolidated list, which is then presented in an inspector pane
/// when the `isPresented` binding is toggled to `true`.
public struct PropertyInspector<Content: View>: View {
    private var content: Content

    let initialHighlight: Bool

    @StateObject
    private var data = PropertyInspectorStorage()

    @Environment(\.inspectorStyle)
    private var style

    public init(
        initialHighlight: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.initialHighlight = initialHighlight
        self.content = content()
    }

    private var configuration: PropertyInspectorStyleConfiguration {
        .init(
            content: AnyView(contentWithDataListeners),
            header: PropertyInspectorHeader.init,
            list: PropertyInspectorList.init,
            rows: PropertyInspectorValueRows.init
        )
    }

    public var body: some View {
        AnyView(style.makeBody(configuration: configuration))
            .toggleStyle(PropertyInspectorToggleStyle())
            .environmentObject(data)
    }

    private var contentWithDataListeners: some View {
        content
            .environment(\.inspectorInitialHighlight, initialHighlight)
            .onPreferenceChange(PropertyInspectorDetailViewBuilderKey.self) { data.details = $0 }
            .onPreferenceChange(PropertyInspectorIconViewBuilderKey.self) { data.icons = $0  }
            .onPreferenceChange(PropertyInspectorLabelViewBuilderKey.self) { data.labels = $0 }
            .onPreferenceChange(PropertyInspectorTitleKey.self) { data.title = $0 }
            .onPreferenceChange(PropertyInspectorValueKey.self) { data.values = Set($0).sorted() }
    }
}

public struct PropertyInspectorStyleConfiguration {
    public let content: AnyView
    public let header: () -> PropertyInspectorHeader
    public let list: () -> PropertyInspectorList
    public let rows: () -> PropertyInspectorValueRows
}

public protocol PropertyInspectorStyle {
    typealias Configuration = PropertyInspectorStyleConfiguration
    associatedtype Body: View
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

public extension PropertyInspectorStyle where Self == PropertyInspectorInlineStyle {
    static var inline: Self {
        .init()
    }
}

public struct PropertyInspectorInlineStyle: PropertyInspectorStyle {
    public func makeBody(configuration: Configuration) -> some View {
        LazyVStack(alignment: .leading) {
            configuration.content
            configuration.rows()
                .padding(.vertical, 3)
                .multilineTextAlignment(.leading)
                .overlay(Divider(), alignment: .bottom)
                .padding(.horizontal)
        }
    }
}

public extension PropertyInspectorStyle where Self == PropertyInspectorShowcaseStyle {

    static var showcase: Self {
        .init(title: "")
    }

    static func showcase(title: LocalizedStringKey) -> Self {
        .init(title: title)
    }
}

public struct PropertyInspectorShowcaseStyle: PropertyInspectorStyle {
    let title: LocalizedStringKey

    public func makeBody(configuration: Configuration) -> some View {
        LazyVStack(pinnedViews: [.sectionHeaders]) {
            Section {
                GroupBox(title) {
                    configuration.content
                }
                .padding()

                configuration.rows()
                    .padding(.vertical, 3)
                    .multilineTextAlignment(.leading)
                    .overlay(Divider(), alignment: .bottom)
                    .padding(.horizontal)
            } header: {
                configuration.header()
                    .padding(.horizontal)
            }
        }   
    }
}

@available(iOS 16.4, *)
public extension PropertyInspectorStyle where Self == PropertyInspectorSheetStyle {
    static func sheet(
        isPresented: Binding<Bool>,
        detent: PresentationDetent = .fraction(2/3),
        presentationDetents: Set<PresentationDetent> = [
            .fraction(1/3),
            .fraction(2/3),
            .large
        ]
    ) -> Self {
        .init(
            isPresented: isPresented,
            detent: detent,
            presentationDetents: presentationDetents
        )
    }
}

@available(iOS 16.4, *)
public struct PropertyInspectorSheetStyle: PropertyInspectorStyle {
    @Binding
    var isPresented: Bool

    @State
    var detent: PresentationDetent

    let presentationDetents: Set<PresentationDetent>

    public func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .safeAreaInset(edge: .bottom, content: bottomInset)
            .toolbar(content: toolbarButton)
            .animation(.snappy, value: isPresented)
            .overlay(sheet(configuration: configuration))
    }

    private func bottomInset() -> some View {
        Spacer().frame(
            height: isPresented ? UIScreen.main.bounds.midY : 0
        )
    }

    private func toolbarButton() -> some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: isPresented ? "xmark.circle" : "magnifyingglass.circle")
                .rotationEffect(.degrees(isPresented ? 180 : 0))
        }
    }

    private func sheet(configuration: Configuration) -> some View {
        Spacer().sheet(isPresented: $isPresented) {
            configuration.list()
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .presentationDetents(
                    presentationDetents,
                    selection: $detent
                )
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
                .presentationCornerRadius(20)
                .presentationBackground(Material.thinMaterial)
                .toggleStyle(PropertyInspectorToggleStyle())
        }
    }
}

final class PropertyInspectorStorage: ObservableObject {
    @Published var searchQuery = ""
    @Published var title = PropertyInspectorTitleKey.defaultValue
    @Published var values = [PropertyInspectorValue]()
    @Published var icons = [String: PropertyInspectorViewBuilder]()
    @Published var labels = [String: PropertyInspectorViewBuilder]()
    @Published var details = [String: PropertyInspectorViewBuilder]()

    var valuesMatchingSearchQuery: [PropertyInspectorValue] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query.count > 1 else { return values }
        return values.filter { item in
            String(describing: item).localizedCaseInsensitiveContains(query)
        }
    }
}

public extension View {
    func propertyInspectorStyle<S: PropertyInspectorStyle>(_ style: S) -> some View {
        environment(\.inspectorStyle, style)
    }

    func propertyInspectorTint(_ color: Color?) -> some View {
        environment(\.inspectorTint, color)
    }

    func inspectSelf(
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        inspectProperty(self, function: function, line: line, file: file)
    }

    /// Attaches an inspectable property to the view, which can be introspected by the `PropertyInspector`.
    ///
    /// Use `inspectProperty` to mark values within your view hierarchy as inspectable. These values are then available within the `PropertyInspector` UI, allowing you to debug and inspect values at runtime.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello, world!")
    ///     .inspect("Hello, world!", function: "Text(_:)")
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
            PropertyInspectorValueModifier(
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
    func propertyInspectorDisabled(_ disabled: Bool = true) -> some View {
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
        modifier(
            PropertyInspectorViewBuilderModifier(
                key: PropertyInspectorIconViewBuilderKey.self,
                label: icon
            )
        )
    }

    func propertyInspectorTitle(_ title: LocalizedStringKey) -> some View {
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
        modifier(
            PropertyInspectorViewBuilderModifier(
                key: PropertyInspectorDetailViewBuilderKey.self,
                label: detail
            )
        )
    }
}

public struct PropertyInspectorList: View {
    public var body: some View {
        List {
            Section(
                content: PropertyInspectorValueRows.init,
                header: PropertyInspectorHeader.init
            )
            .listRowBackground(Color.clear)
        }
    }
}

public struct PropertyInspectorHeader: View {
    @EnvironmentObject
    private var data: PropertyInspectorStorage

    public var body: some View {
        VStack(spacing: 6) {
            Toggle(isOn: .init(
                get: {
                    !data.valuesMatchingSearchQuery.isEmpty
                    && data.valuesMatchingSearchQuery
                        .map(\.isHighlighted)
                        .filter { $0 == false }
                        .isEmpty
                },
                set: { newValue in
                    data.valuesMatchingSearchQuery.forEach {
                        $0.isHighlighted = newValue
                    }
                }
            )) {
                Text(data.title)
                    .bold()
                    .font(.title2)
            }

            HStack {
                TextField(
                    "Search \(data.valuesMatchingSearchQuery.count) items",
                    text: $data.searchQuery
                )

                if !data.searchQuery.isEmpty {
                    Button {
                        data.searchQuery.removeAll()
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
}
struct PropertyInspectorToggleStyle: ToggleStyle {
    var alignment: VerticalAlignment = .center
    
    func icon(_ isOn: Bool) -> String {
        isOn ? "checkmark.circle.fill" : "circle"
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: alignment) {
                configuration.label
                Spacer()
                Image(systemName: icon(configuration.isOn))
            }
            .tint(.primary)
        }
    }
}

/// Represents an individual inspectable property within the `PropertyInspector`.
///
/// `PropertyInspectorValue` encapsulates the value and metadata of a property to be inspected, including its location within the source code and whether it is currently highlighted in the UI. This type is crucial for organizing and presenting property data within the inspector interface.
///
/// - Note: Conforms to `Identifiable`, `Comparable`, and `Hashable` to support efficient collection operations and UI presentation.
public struct PropertyInspectorValue: Identifiable, Comparable, Hashable {
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

    var stringValueType: String {
        String(describing: type(of: value))
    }

    private var sortString: String {
        "\(location)\(stringValueType)\(stringValue)"
    }

    init(value: Any, isHighlighted: Binding<Bool>, location: PropertyInspectorLocation) {
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
    }

    public static func == (lhs: PropertyInspectorValue, rhs: PropertyInspectorValue) -> Bool {
        lhs.id == rhs.id &&
        lhs.location == rhs.location &&
        lhs.stringValue == rhs.stringValue
    }

    public static func < (lhs: PropertyInspectorValue, rhs: PropertyInspectorValue) -> Bool {
        lhs.sortString.localizedCaseInsensitiveCompare(rhs.sortString) == .orderedAscending
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Encapsulates the location within the source code where a `PropertyInspectorValue` was defined.
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

public struct PropertyInspectorValueRows: View {
    @EnvironmentObject
    private var data: PropertyInspectorStorage

    public var body: some View {
        let rows = data.valuesMatchingSearchQuery

        if rows.isEmpty {
            Text(emptyMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .listRowSeparator(.hidden)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top)
        } else {
            ForEach(rows) { row in
                PropertyInspectorValueRow(
                    data: row,
                    icon: makeBody(configuration: (row, data.icons)),
                    label: makeBody(configuration: (row, data.labels)),
                    detail: makeBody(configuration: (row, data.details))
                )
            }
        }
    }

    private var emptyMessage: String {
        data.searchQuery.isEmpty ?
        "Nothing yet.\nInspect items using `inspectProperty(_:)`" :
        "No results for '\(data.searchQuery)'"
    }

    private func makeBody(configuration: (item: PropertyInspectorValue, source: [String: PropertyInspectorViewBuilder])) -> AnyView? {
        for key in configuration.source.keys {
            if let view = configuration.source[key]?.view(configuration.item.value) {
                return view
            }
        }
        return nil
    }
}

struct PropertyInspectorValueRow: View {
    let data: PropertyInspectorValue
    var icon: AnyView?
    var label: AnyView?
    var detail: AnyView?

    var body: some View {
        Toggle(isOn: data.$isHighlighted) {
            HStack {
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
                            Text(verbatim: data.stringValue)
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

struct PropertyInspectorValueModifier: ViewModifier  {
    @Environment(\.inspectorInitialHighlight)
    private var isHighlighted
    let values: [Any]
    let location: PropertyInspectorLocation

    func body(content: Content) -> some View {
        content.modifier(
            _ViewModifier(
                isHighlighted: isHighlighted,
                values: values,
                location: location
            )
        )
    }

    private struct _ViewModifier: ViewModifier  {
        @State
        var isHighlighted: Bool
        var values: [Any]
        var location: PropertyInspectorLocation

        @Environment(\.inspectorDisabled)
        private var disabled

        private var data: [PropertyInspectorValue] {
            if disabled { return [] }
            return values.map {
                PropertyInspectorValue(
                    value: $0,
                    isHighlighted: $isHighlighted,
                    location: location
                )
            }
        }

        private var isOn: Binding<Bool> {
            disabled ? .constant(false) : $isHighlighted
        }

        func body(content: Content) -> some View {
            PropertyInspectorHighlightView(isOn: isOn) {
                content.background(
                    Color.clear.preference(
                        key: PropertyInspectorValueKey.self,
                        value: data
                    )
                )
            }
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

    @Environment(\.inspectorTint)
    private var tint

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

    var tintShape: some ShapeStyle {
        if let tint { return tint }
        return colorScheme == .light ? Color.blue : Color.yellow
    }

    var body: some View {
        content
            .zIndex(isVisible ? 999 : 0)
            .overlay {
                if isVisible {
                    Rectangle()
                        .stroke(lineWidth: 1.5)
                        .fill(tintShape)
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

private extension [String: PropertyInspectorViewBuilder] {
    mutating func merge(_ next: Self) {
        merge(next) { content, _ in
            content
        }
    }
}

// MARK: - Environment Keys

struct PropertyInspectorTintKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

struct PropertyInspectorDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

struct PropertyInspectorStyleKey: EnvironmentKey {
    static var defaultValue: any PropertyInspectorStyle = .inline
}

struct PropertyInspectorInitialHighlightKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var inspectorDisabled: Bool {
        get { self[PropertyInspectorDisabledKey.self] }
        set { self[PropertyInspectorDisabledKey.self] = newValue }
    }

    var inspectorInitialHighlight: Bool {
        get { self[PropertyInspectorInitialHighlightKey.self] }
        set { self[PropertyInspectorInitialHighlightKey.self] = newValue }
    }

    var inspectorStyle: any PropertyInspectorStyle {
        get { self[PropertyInspectorStyleKey.self] }
        set { self[PropertyInspectorStyleKey.self] = newValue }
    }

    var inspectorTint: Color? {
        get { self[PropertyInspectorTintKey.self] }
        set { self[PropertyInspectorTintKey.self] = newValue }
    }
}

// MARK: - Preference Keys

struct PropertyInspectorTitleKey: PreferenceKey {
    static var defaultValue: LocalizedStringKey = "Inspect"
    static func reduce(value: inout LocalizedStringKey, nextValue: () -> LocalizedStringKey) {}
}

struct PropertyInspectorValueKey: PreferenceKey {
    static var defaultValue: [PropertyInspectorValue] { [] }
    static func reduce(value: inout [PropertyInspectorValue], nextValue: () -> [PropertyInspectorValue]) {
        value.append(contentsOf: nextValue())
    }
}

struct PropertyInspectorDetailViewBuilderKey: PreferenceKey {
    static let defaultValue = [String: PropertyInspectorViewBuilder]()
    static func reduce(value: inout [String: PropertyInspectorViewBuilder], nextValue: () -> [String: PropertyInspectorViewBuilder]) {
        value.merge(nextValue())
    }
}

struct PropertyInspectorIconViewBuilderKey: PreferenceKey {
    static let defaultValue = [String: PropertyInspectorViewBuilder]()
    static func reduce(value: inout [String: PropertyInspectorViewBuilder], nextValue: () -> [String: PropertyInspectorViewBuilder]) {
        value.merge(nextValue())
    }
}

struct PropertyInspectorLabelViewBuilderKey: PreferenceKey {
    static let defaultValue = [String: PropertyInspectorViewBuilder]()
    static func reduce(value: inout [String: PropertyInspectorViewBuilder], nextValue: () -> [String: PropertyInspectorViewBuilder]) {
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

struct PropertyInspectorViewBuilderModifier<Key: PreferenceKey, Value, Label: View>: ViewModifier where Key.Value == [String: PropertyInspectorViewBuilder] {
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

    private var data: [String: PropertyInspectorViewBuilder] {
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
    let title: LocalizedStringKey

    func body(content: Content) -> some View {
        content.background(
            Color.clear.preference(
                key: PropertyInspectorTitleKey.self,
                value: title
            )
        )
    }
}

#if DEBUG
@available(iOS 16.4, *)
#Preview {
    PropertyInspector(initialHighlight: true) {
        let foreground = HierarchicalShapeStyle.primary
        let padding: Double = 20

        VStack(alignment: .center, content: {
            Button {
                // action
            } label: {
                Text("Button")
                    .inspectSelf()
            }
            .foregroundStyle(foreground)
            .inspectProperty(
                "\(foreground)",
                function: "foregroundStyle()")
            .padding(padding)
            .inspectProperty(
                padding,
                function: "padding()")
        })
        .frame(maxWidth: .infinity)
        .propertyInspectorTitle("Example")
        .propertyInspectorRowIcon(for: Double.self) { value in
            Image(systemName: "\(Int(value)).circle.fill").symbolRenderingMode(.hierarchical)
        }
    }
    .propertyInspectorTint(.cyan)
    .propertyInspectorStyle(.showcase(title: "Preview"))
    //.propertyInspectorStyle(.sheet(isPresented: .constant(true)))
}
#endif
