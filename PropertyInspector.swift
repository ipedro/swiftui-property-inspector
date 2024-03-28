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

    @State
    private var iconBuilders = PropertyInspectorViewBuilderDictionary()

    @State
    private var labelBuilders = PropertyInspectorViewBuilderDictionary()

    @State
    private var detailBuilders = PropertyInspectorViewBuilderDictionary()

    @Binding
    private var isPresented: Bool

    @State
    private var data = [PropertyInspectorItem]()

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
            .onPreferenceChange(PropertyInspectorValueKey.self) { data = Set($0).sorted() }
            .onPreferenceChange(PropertyInspectorIconViewBuilderKey.self) { iconBuilders = $0  }
            .onPreferenceChange(PropertyInspectorLabelViewBuilderKey.self) { labelBuilders = $0 }
            .onPreferenceChange(PropertyInspectorDetailViewBuilderKey.self) { detailBuilders = $0 }
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
                    PropertyInspectorList(
                        title: title,
                        data: data,
                        iconBuilders: iconBuilders,
                        labelBuilders: labelBuilders,
                        detailBuilders: detailBuilders
                    )
                }
            }
    }
}

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
    func inspectorDisabled(_ disabled: Bool = true) -> some View {
        environment(\.inspectorDisabled, disabled)
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
    ///         .inspectorCornerRadius(10) // Applies a corner radius of 10 to the highlight view
    /// }
    /// ```
    ///
    /// When you apply this modifier to a view, the `PropertyInspectorHighlightView` within the
    /// inspector will display with rounded corners of the specified radius. This can be used to
    /// maintain consistent styling within your app, especially if you have a design system with
    /// specific corner radius values.
    func inspectorHighlightCornerRadius(_ radius: CGFloat) -> some View {
        environment(\.inspectorCornerRadius, radius)
    }
    
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
    let title: String?
    let data: [PropertyInspectorItem]
    let iconBuilders: PropertyInspectorViewBuilderDictionary
    let labelBuilders: PropertyInspectorViewBuilderDictionary
    let detailBuilders: PropertyInspectorViewBuilderDictionary

    @State
    private var searchQuery = ""

    private var filteredData: [PropertyInspectorItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return data }
        return data.filter { item in
            String(describing: item).localizedCaseInsensitiveContains(query)
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

                ForEach(filteredData) { item in
                    PropertyInspectorItemRow(
                        item: item,
                        icon: makeBody(item, using: iconBuilders),
                        label: makeBody(item, using: labelBuilders),
                        detail: makeBody(item, using: detailBuilders)
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

/// Represents an individual item to be inspected within the Property Inspector.
/// This class encapsulates a single property's value and metadata for display and comparison purposes.
public struct PropertyInspectorItem: Identifiable, Comparable, Hashable {
    /// A unique identifier for the inspector item, used to differentiate between items.
    public let id = UUID()

    /// The value of the property being inspected. The type of this value is generic, allowing for flexibility in what can be inspected.
    public let value: Any

    /// The location within the source code where this item was tagged for inspection.
    /// This includes the function name, file name, and line number.
    public let location: PropertyInspectorLocation

    /// A binding to a Boolean value that determines whether this item is currently highlighted within the UI.
    let isHighlighted: Binding<Bool>

    var stringValue: String {
        String(describing: value)
    }

    private var sortString: String {
        "\(location)\(stringValue)"
    }

    init(value: Any, isHighlighted: Binding<Bool>, location: PropertyInspectorLocation) {
        self.value = value
        self.isHighlighted = isHighlighted
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
        //        hasher.combine(location.description)
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
        Toggle(isOn: item.isHighlighted) {
            HStack {
                if let icon {
                    icon
                } else {
                    Image(systemName: "questionmark.diamond")
                        .foregroundStyle(.tertiary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Spacer().frame(height: 3) // padding doesn't work

                    Group {
                        if let label {
                            label
                        } else {
                            Text(verbatim: item.stringValue)
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .bold()

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

struct PropertyInspectorViewModifier<Value>: ViewModifier  {
    let values: [Value]
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

struct PropertyInspectorHighlightCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var inspectorCornerRadius: CGFloat {
        get { self[PropertyInspectorHighlightCornerRadiusKey.self] }
        set { self[PropertyInspectorHighlightCornerRadiusKey.self] = newValue }
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

    @Environment(\.inspectorCornerRadius)
    private var cornerRadius

    @Environment(\.inspectorDisabled)
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

// MARK: - View Builders

private extension PropertyInspectorViewBuilderDictionary {
    mutating func merge(_ next: Self) {
        merge(next) { content, _ in
            content
        }
    }
}

typealias PropertyInspectorViewBuilderDictionary = [String: PropertyInspectorViewBuilder]

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
