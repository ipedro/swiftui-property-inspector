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
/// let foreground: HierarchicalShapeStyle = .primary
/// let padding: Double = 20
///
/// var body: some View {
///    PropertyInspector(initialHighlight: true) {
///        // component we want to inspect
///        Button {
///            // some action
///        } label: {
///            // you can inspect views directly, useful for debugging
///            Text("Button").inspectSelf()
///        }
///        // inspect foreground style
///        .foregroundStyle(foreground)
///        .inspectProperty(
///            "\(foreground)",
///            function: "foregroundStyle()"
///        )
///        // inspect padding value
///        .padding(padding)
///        .inspectProperty(
///            padding,
///            function: "padding()"
///        )
///        // optional: custom title
///        .propertyInspectorTitle("Example")
///        // optional: register custom icons, labels, detail views
///        .propertyInspectorRowIcon(for: Double.self) { value in
///            Image(systemName: "\(Int(value)).circle.fill")
///                .symbolRenderingMode(.hierarchical)
///        }
///    }
///    // optional: change highlight tint
///    .propertyInspectorTint(.cyan)
///    // optional: change behavior
///    .propertyInspectorStyle(.showcase)
/// ```
///
/// The `PropertyInspector` leverages SwiftUI's preference system to collect property information
/// from descendant views into a consolidated list, which is then presented in an inspector pane
/// when the `isPresented` binding is toggled to `true`.
public struct PropertyInspector: View {
    private var initialHighlight: Bool

    private var content: AnyView

    @StateObject
    private var data = Storage()

    @Environment(\.inspectorStyle)
    private var style

    public init<Content: View>(
        initialHighlight: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.initialHighlight = initialHighlight
        self.content = AnyView(content())
    }

    private var configuration: PropertyInspectorStyleConfiguration {
        PropertyInspectorStyleConfiguration(content: content)
    }

    public var body: some View {
        AnyView(style.resolve(configuration: configuration))
            .environment(\.inspectorInitialHighlight, initialHighlight)
            .toggleStyle(PropertyInspectorToggle())
            .onPreferenceChange(RowDetailPreference.self) { data.details = $0 }
            .onPreferenceChange(RowIconPreference.self) { data.icons = $0  }
            .onPreferenceChange(RowLabelPreference.self) { data.labels = $0 }
            .onPreferenceChange(TitlePreference.self) { data.title = $0 }
            .onPreferenceChange(PropertyPreference.self) { data.properties = Set($0).sorted() }
            .environmentObject(data)
    }
}

public struct PropertyInspectorStyleConfiguration {
    public let content: AnyView
    public let header = PropertyInspectorHeader()
    public let rows = PropertyInspectorRows()
}

public struct PropertyInspectorHeader: View {
    @EnvironmentObject
    private var data: Storage

    public var body: some View {
        VStack(spacing: 6) {
            Toggle(isOn: .init {
                !data.valuesMatchingSearchQuery.isEmpty
                && data.valuesMatchingSearchQuery
                    .map(\.isHighlighted)
                    .filter { $0 == false }
                    .isEmpty
            } set: { newValue in
                data.valuesMatchingSearchQuery.forEach {
                    $0.isHighlighted = newValue
                }
            }) {
                data.title?.value.font(.title2.bold())
            }

            searchField()
        }
        .tint(.primary)
        .padding(
            EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0)
        )
    }

    private func searchField() -> HStack<TupleView<(TextField<Text>, Button<some View>?)>> {
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

}

public struct PropertyInspectorRows: View {
    @EnvironmentObject
    private var data: Storage

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
            ForEach(rows) {
                Row(
                    data: $0,
                    icon: makeBody(configuration: ($0, data.icons)),
                    label: makeBody(configuration: ($0, data.labels)),
                    detail: makeBody(configuration: ($0, data.details))
                )
            }
        }
    }

    private var emptyMessage: String {
        data.searchQuery.isEmpty ?
        "Nothing yet.\nInspect items using `inspectProperty(_:)`" :
        "No results for '\(data.searchQuery)'"
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

// MARK: - Style Protocol

public protocol PropertyInspectorStyle: DynamicProperty {
    typealias Configuration = PropertyInspectorStyleConfiguration
    associatedtype Body: View
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

private struct ResolvedStyle<Style: PropertyInspectorStyle>: View {
    var configuration: PropertyInspectorStyleConfiguration
    var style: Style

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

private extension PropertyInspectorStyle {
    func resolve(configuration: Configuration) -> some View {
        ResolvedStyle(configuration: configuration, style: self)
    }
}

public extension PropertyInspectorStyle where Self == InlinePropertyInspector {
    static var inline: Self {
        .init(alignment: .center)
    }

    static func inline(alignment: HorizontalAlignment) -> Self {
        .init(alignment: alignment)
    }
}

public extension PropertyInspectorStyle where Self == ContextMenuPropertyInspector {
    static var contextMenu: Self { .init() }
}

// MARK: - Context Menu Style

/// A style that presents dynamic value options within a context menu.
public struct ContextMenuPropertyInspector: PropertyInspectorStyle {
    /// Creates the view for the context menu style, presenting the dynamic value options within a context menu.
    ///
    /// - Parameter configuration: The configuration containing the dynamic value options and content.
    /// - Returns: A view displaying the dynamic value options in a context menu.
    public func makeBody(configuration: Configuration) -> some View {
        configuration.content.contextMenu {
            configuration.rows
        }
    }
}

// MARK: - Inline Style

public struct InlinePropertyInspector: PropertyInspectorStyle {
    let alignment: HorizontalAlignment

    public func makeBody(configuration: Configuration) -> some View {
        LazyVStack(alignment: alignment) {
            configuration.content
            configuration.rows
                .padding(.vertical, 3)
                .multilineTextAlignment(.leading)
                .overlay(Divider(), alignment: .bottom)
                .padding(.horizontal)
        }
    }
}


public extension PropertyInspectorStyle where Self == ListPropertyInspector<PlainListStyle, Color> {
    static var list: Self { .list() }

    static func list(
        rowBackground: Color = Color(uiColor: .systemBackground)
    ) -> Self {
        .init(
            listStyle: .init(),
            listRowBackground: rowBackground
        )
    }
}

public extension PropertyInspectorStyle where Self == ListPropertyInspector<InsetGroupedListStyle, Color> {
    static var insetGroupedList: Self { .insetGroupedList() }

    static func insetGroupedList(
        rowBackground: Color = Color(uiColor: .systemBackground)
    ) -> Self {
        .init(
            listStyle: .init(),
            listRowBackground: rowBackground
        )
    }
}

public extension PropertyInspectorStyle where Self == ListPropertyInspector<GroupedListStyle, Color> {
    static var groupedList: Self { .groupedList() }

    static func groupedList(
        rowBackground: Color = Color(uiColor: .systemBackground)
    ) -> Self {
        .init(
            listStyle: .init(),
            listRowBackground: rowBackground
        )
    }
}

public extension PropertyInspectorStyle where Self == ListPropertyInspector<SidebarListStyle, Color> {
    static var sidebarList: Self { .sidebarList() }

    static func sidebarList(
        rowBackground: Color = Color(uiColor: .systemBackground)
    ) -> Self {
        .init(
            listStyle: .init(),
            listRowBackground: rowBackground
        )
    }
}

// MARK: - List Style

public struct ListPropertyInspector<S: ListStyle, B: View>: PropertyInspectorStyle {
    let listStyle: S
    let listRowBackground: B

    public func makeBody(configuration: Configuration) -> some View {
        List {
            Section {
                configuration.rows
                    .listRowBackground(listRowBackground)
            } header: {
                VStack(spacing: .zero) {
                    configuration.content
                        .environment(\.textCase, nil)
                        .padding(.vertical)
                        .padding(.vertical)

                    configuration.header
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .listStyle(listStyle)
    }
}

// MARK: - Sheet Style

@available(iOS 16.4, *)
public extension PropertyInspectorStyle where Self == SheetPropertyInspector {
    static func sheet(
        isPresented: Binding<Bool>,
        adjustsBottomInset: Bool = true,
        detent: PresentationDetent = .fraction(1/4),
        presentationDetents: Set<PresentationDetent> = [
            .fraction(1/4),
            .medium,
            .fraction(2/3),
            .large
        ]
    ) -> Self {
        .init(
            isPresented: isPresented,
            adjustsBottomInset: adjustsBottomInset,
            detent: detent,
            presentationDetents: presentationDetents
        )
    }
}

@available(iOS 16.4, *)
public struct SheetPropertyInspector: PropertyInspectorStyle {
    @Binding
    var isPresented: Bool

    let adjustsBottomInset: Bool

    @State
    var detent: PresentationDetent

    let presentationDetents: Set<PresentationDetent>

    public func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: bottomInset)
            }
            .toolbar(content: toolbarButton)
            .animation(.snappy, value: isPresented)
            .overlay(sheet(configuration: configuration))
    }

    private var bottomInset: Double {
        adjustsBottomInset && isPresented ? UIScreen.main.bounds.midY : 0
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
            List {
                Section {
                    configuration.rows
                } header: {
                    configuration.header
                }
                .listRowBackground(Color.clear)
            }
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
            .toggleStyle(PropertyInspectorToggle())
        }
    }
}

// MARK: - Public API

public extension View {
    func propertyInspectorStyle<S: PropertyInspectorStyle>(_ style: S) -> some View {
        environment(\.inspectorStyle, style)
    }

    func propertyInspectorTint(_ color: Color?) -> some View {
        environment(\.inspectorHighlightTint, color)
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
    func inspectProperty<T>(
        _ values: T...,
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        PropertyHighlightModifier(
            content: self,
            values: values,
            location: .init(
                function: function,
                file: file,
                line: line
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
        setPreferenceChange(RowIconPreference.self, content: icon)
    }

    func propertyInspectorTitle(_ title: LocalizedStringKey?) -> some View {
        setPreferenceChange(TitlePreference.self, value: {
            if let title {
                return HashableBox(value: Text(title))
            }
            return nil
        }())
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
}

extension AnyShapeStyle: Equatable {
    public static func == (lhs: AnyShapeStyle, rhs: AnyShapeStyle) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}

private struct PropertyInspectorToggle: ToggleStyle {
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

private final class Storage: ObservableObject {
    @Published var searchQuery = ""
    @Published var title = TitlePreference.defaultValue
    @Published var properties = [Property]()
    @Published var icons = [String: RowViewBuilder]()
    @Published var labels = [String: RowViewBuilder]()
    @Published var details = [String: RowViewBuilder]()

    var valuesMatchingSearchQuery: [Property] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query.count > 1 else { return properties }
        return properties.filter { item in
            String(describing: item).localizedCaseInsensitiveContains(query)
        }
    }
}

/// Represents an individual inspectable property within the `PropertyInspector`.
///
/// `Property` encapsulates the value and metadata of a property to be inspected, including its location within the source code and whether it is currently highlighted in the UI. This type is crucial for organizing and presenting property data within the inspector interface.
///
/// - Note: Conforms to `Identifiable`, `Comparable`, and `Hashable` to support efficient collection operations and UI presentation.
private struct Property: Identifiable, Comparable, Hashable {
    /// A unique identifier for the inspector item, necessary for conforming to `Identifiable`.
    let id: String

    /// The value of the property being inspected. This is stored as `Any` to accommodate any property type.
    let value: Any

    /// Metadata describing the source code location where this property is inspected.
    let location: PropertyLocation

    let index: Int

    /// A binding to a Boolean value indicating whether this item is highlighted within the UI.
    @Binding 
    var isHighlighted: Bool

    var stringValue: String

    var stringValueType: String

    private let sortString: String

    init(
        id: String,
        value: Any,
        isHighlighted: Binding<Bool>,
        location: PropertyLocation,
        index: Int = 0
    ) {
        self.id = id
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
        self.index = index

        let stringValueType = String(describing: type(of: value))
        let stringValue = String(describing: value)
        self.stringValueType = stringValueType
        self.stringValue = stringValue
        self.sortString = "\(location):\(index):\(stringValueType):\(stringValue)"
    }

    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id
    }

    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.sortString.localizedCaseInsensitiveCompare(rhs.sortString) == .orderedAscending
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Encapsulates the location within the source code where an inspectable property was defined.
///
/// This class includes detailed information about the function or variable, the file path, and the line number where the inspected property is located, aiding in pinpointing the exact source of the property.
///
/// - Note: Conforms to `Comparable` and `CustomStringConvertible` for sorting and presenting location information.
final class PropertyLocation: Comparable, CustomStringConvertible {
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
            return function
        }
        return "\(fileName):\(line)"
    }()

    static func < (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }

    static func == (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.description == rhs.description
    }
}

private struct Row: View {
    var data: Property
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

private struct PropertyHighlightModifier<Content: View, Value>: View {
    @State
    private var animationToken = UUID()

    @State
    var isOn: Bool = false

    @State
    var id = UUID()

    var content: Content

    var values: [Value]

    var location: PropertyLocation

    @Environment(\.inspectorHighlightTint)
    private var tint

    @Environment(\.inspectorDisabled)
    private var disabled

    @Environment(\.colorScheme)
    private var colorScheme

    private var data: [Property] {
        if disabled { return [] }
        return values.enumerated().map { (offset, value) in
            Property(
                id: "\(id.uuidString)-\(offset)",
                value: value,
                isHighlighted: $isOn,
                location: location,
                index: offset
            )
        }
    }

    var transition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: .random(in: 2 ... 2.5))),
            removal: .identity
        )
    }

    var tintShape: some ShapeStyle {
        if let tint { return tint }
        return colorScheme == .light ? Color.blue : Color.yellow
    }

    var zIndex: Double {
        isOn ? 999 : 0
    }

    var body: some View {
        content
            .setPreferenceChange(PropertyPreference.self, value: data)
            .zIndex(zIndex)
            .overlay {
                if !disabled, isOn {
                    Rectangle()
                        .stroke(lineWidth: 1.5)
                        .fill(tintShape)
                        .id(animationToken)
                        .transition(transition)
                }
            }
            .onChange(of: isOn) { newValue in
                guard !disabled, newValue else { return }
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

// MARK: - Environment Keys

private struct HighlightTintKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private struct DisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct StyleKey: EnvironmentKey {
    static var defaultValue: any PropertyInspectorStyle = .inline
}

private struct InitialHighlightKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var inspectorDisabled: Bool {
        get { self[DisabledKey.self] }
        set { self[DisabledKey.self] = newValue }
    }

    var inspectorInitialHighlight: Bool {
        get { self[InitialHighlightKey.self] }
        set { self[InitialHighlightKey.self] = newValue }
    }

    var inspectorStyle: any PropertyInspectorStyle {
        get { self[StyleKey.self] }
        set { self[StyleKey.self] = newValue }
    }

    var inspectorHighlightTint: Color? {
        get { self[HighlightTintKey.self] }
        set { self[HighlightTintKey.self] = newValue }
    }
}

// MARK: - Property Wrappers

@propertyWrapper
private struct PreferenceKeyState<K: PreferenceKey>: DynamicProperty {
    @State<K.Value>
    var wrappedValue: K.Value = K.defaultValue
    var projectedValue: Binding<K.Value> { $wrappedValue }
}

// MARK: - Preference Keys

private struct HashableBox<Value>: Identifiable, Hashable, CustomStringConvertible {
    static func == (lhs: HashableBox<Value>, rhs: HashableBox<Value>) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: String { description }

    let value: Value

    let description: String

    init(value: Value) {
        self.value = value
        self.description = String(describing: value)
    }
}

private struct TitlePreference: PreferenceKey {
    static var defaultValue: HashableBox<Text>?
    static func reduce(value: inout HashableBox<Text>?, nextValue: () -> HashableBox<Text>?) {}
}

private struct PropertyPreference: PreferenceKey {
    static let defaultValue = [Property]()
    static func reduce(value: inout [Property], nextValue: () -> [Property]) {
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

#if DEBUG
@available(iOS 16.4, *)
#Preview {
    PropertyInspector(initialHighlight: true) {
        let foreground = HierarchicalShapeStyle.primary
        let padding: Double = 20

        // component we want to inspect
        Button {
            // some action
        } label: {
            // you can inspect views directly, useful for debugging
            Text("Button").inspectSelf()
        }
        // inspect foreground style
        .foregroundStyle(foreground)
        .inspectProperty(
            "\(foreground)",
            function: "foregroundStyle()"
        )
        // inspect padding value
        .padding(padding)
        .inspectProperty(
            padding,
            function: "padding()"
        )
        // optional: customize title
        .propertyInspectorTitle("Properties")
        // optional: register custom icons, labels, detail views
        .propertyInspectorRowIcon(for: Double.self) { value in
            Image(systemName: "\(Int(value)).circle.fill")
                .symbolRenderingMode(.hierarchical)
        }
    }
    // optional: change highlight tint
    .propertyInspectorTint(.cyan)
    // optional: choose from different built-in styles or create your own
    .propertyInspectorStyle(.list)
    .propertyInspectorStyle(.insetGroupedList)
    .propertyInspectorStyle(.sidebarList)
    .propertyInspectorStyle(.sheet(isPresented: .constant(true)))
    .propertyInspectorStyle(.contextMenu)
    .propertyInspectorStyle(.inline(alignment: .trailing))
    .propertyInspectorStyle(.inline)
}
#endif
