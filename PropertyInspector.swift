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

private final class PropertyStore: ObservableObject {
    @Published
    var properties: [Property] = []
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
public struct PropertyInspector<Content: View, Label: View, Detail: View, Icon: View>: View {
    private var title: String?
    private var content: Content
    private var icon: (Any) -> Icon
    private var label: (Any) -> Label
    private var detail: (Any) -> Detail

    @Binding
    private var isPresented: Bool

    @State
    private var bottomInset: Double = 0

    private let highlightOnPresent: Bool

    @StateObject
    private var data = PropertyStore()

    /// Initializes a `PropertyInspector` with the most detailed configuration, including title, content,
    /// icon, label, and detail views for each property.
    ///
    /// - Parameters:
    ///   - title: An optional title for the property inspector pane.
    ///   - highlightOnPresent: Highlights properties when presenting and hides them when dismissed.
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
        highlightOnPresent: Bool = false,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder icon: @escaping (Any) -> Icon,
        @ViewBuilder label: @escaping (Any) -> Label,
        @ViewBuilder detail: @escaping (Any) -> Detail
    ) {
        self.title = title
        self.highlightOnPresent = highlightOnPresent
        self._isPresented = isPresented
        self.content = content()
        self.icon = icon
        self.label = label
        self.detail = detail
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
            .overlay {
                Spacer().sheet(isPresented: $isPresented) {
                    PropertyInspectorList(
                        title: title,
                        icon: icon,
                        label: label,
                        detail: detail
                    )
                }
            }
            // 2. data listeners
            .onPreferenceChange(PropertyPreferenceKey.self) { newValue in
                let uniqueProperties = newValue
                    .removingDuplicates()
                    .sorted()

                if data.properties != uniqueProperties {
                    data.properties = uniqueProperties
                }
            }
            .onChange(of: isPresented) { _ in
                bottomInset = isPresented ? UIScreen.main.bounds.midY : 0

                guard highlightOnPresent else {
                    return
                }
                withAnimation(.default.delay(250)) {
                    data.properties.enumerated().forEach { (offset, property) in
                        withAnimation(.default.delay(TimeInterval(50 * offset))) {
                            property.isHighlighted = isPresented
                        }
                    }
                }
            }
            // 3. data store
            .environmentObject(data)
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

extension Collection where Element: Identifiable {
    func removingDuplicates() -> [Element] {
        var seenIDs = Set<Element.ID>()
        return filter {
            seenIDs.insert($0.id).inserted
        }
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

private extension EnvironmentValues {
    var propertyInspectorDisabled: Bool {
        get { self[PropertyInspectorDisabledKey.self] }
        set { self[PropertyInspectorDisabledKey.self] = newValue }
    }
}

private struct PropertyInspectorDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 16.4, *)
private struct PropertyInspectorList<Label: View, Detail: View, Icon: View>: View {
    let title: String?
    let icon: (Any) -> Icon
    let label: (Any) -> Label
    let detail: (Any) -> Detail

    @EnvironmentObject
    private var data: PropertyStore

    @State
    private var searchQuery = ""

    private var filteredData: [Property] {
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
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height / 5)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .multilineTextAlignment(.center)
                }

                ForEach(filteredData, content: row(_ :))
            } header: {
                header
            }
        }
        .multilineTextAlignment(.leading)
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
        .symbolRenderingMode(.hierarchical)
    }

    private var emptyMessage: String {
        searchQuery.isEmpty ?
        "Empty" :
        "No results for '\(searchQuery)'"
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            if let title {
                Text(title).bold().font(.title2)
            }

            TextField(
                "Search \(filteredData.count) items",
                text: $searchQuery
            )
            .frame(maxWidth: .infinity)

            Toggle(sources: filteredData, isOn: \.$isHighlighted) {
                EmptyView()
            }
        }
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

    private func row(_ item: Property) -> some View {
        Toggle(isOn: item.$isHighlighted) {
            HStack(alignment: .firstTextBaseline) {
                if Icon.self == EmptyView.self {
                    Image(systemName: "info.circle.fill")
                } else {
                    icon(item.value)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Group {
                        if Label.self == EmptyView.self {
                            Text(verbatim: item.stringValue).minimumScaleFactor(0.8)
                        } else {
                            label(item.value)
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .bold()

                    if Detail.self == EmptyView.self {
                        Text(verbatim: item.location.description)
                    } else {
                        detail(item.value)
                    }
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

private struct PropertyInspectorViewModifier: ViewModifier  {
    let values: [Any]
    let location: PropertyLocation

    @State
    private var isOn = false

    @Environment(\.propertyInspectorDisabled)
    private var disabled

    var data: [Property] {
        if disabled {
            return []
        }
        return values.enumerated().map { (index, value) in
            Property(
                value: value,
                isHighlighted: $isOn,
                location: location,
                index: index
            )
        }
    }

    func body(content: Content) -> some View {
        content.background(
            Spacer().preference(key: PropertyPreferenceKey.self, value: data)
        )
        .modifier(
            PropertyInspectorHighlightViewModifier(isOn: isOn)
        )
    }
}

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

private struct PropertyInspectorHighlightCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private extension EnvironmentValues {
    var propertyInspectorCornerRadius: CGFloat {
        get { self[PropertyInspectorHighlightCornerRadiusKey.self] }
        set { self[PropertyInspectorHighlightCornerRadiusKey.self] = newValue }
    }
}

private struct PropertyInspectorHighlightViewModifier: ViewModifier {
    var isOn: Bool

    @Environment(\.propertyInspectorCornerRadius)
    private var cornerRadius

    func body(content: Content) -> some View {
        content
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
#endif
