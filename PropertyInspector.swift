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

@available(iOS 16.4, *)
public struct PropertyInspector<Value, Content: View, Label: View, Detail: View, Icon: View>: View {
    let title: String?
    let content: Content
    let icon: (Value) -> Icon
    let label: (Value) -> Label
    let detail: (Value) -> Detail
    var comparator: SortComparator?

    @Binding
    var isPresented: Bool

    @State
    private var data: [PropertyInspectorItem<Value>] = []

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
        self.icon = icon
        self.label = label
        self.detail = detail
    }

    public init(
        _ title: String? = nil,
        _ value: Value.Type = Value.self,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder icon: @escaping (Value) -> Icon,
        @ViewBuilder label: @escaping (Value) -> Label
    ) where Detail == EmptyView {
        self.init(
            title,
            value,
            isPresented: isPresented,
            content: content,
            icon: icon,
            label: label,
            detail: { _ in EmptyView() }
        )
    }

    public init(
        _ title: String? = nil,
        _ value: Value.Type = Value.self,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: @escaping (Value) -> Label
    ) where Detail == EmptyView, Icon == EmptyView {
        self.init(
            title,
            value,
            isPresented: isPresented,
            content: content,
            icon: { _ in EmptyView() },
            label: label,
            detail: { _ in EmptyView() }
        )
    }

    public var body: some View {
        content
            .onPreferenceChange(PropertyInspectorItemKey<Value>.self) { newValue in
                guard let comparator else {
                    data = newValue
                    return
                }
                data = newValue.sorted(by: { lhs, rhs in
                    comparator(lhs.value, rhs.value)
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
public extension PropertyInspector {
    typealias SortComparator = (_ lhs: Value, _ rhs: Value) -> Bool
    func sort(by comparator: @escaping SortComparator) -> Self {
        var copy = self
        copy.comparator = comparator
        return copy
    }
}

@available(iOS 16.4, *)
struct PropertyInspectorList<Value, Label: View, Detail: View, Icon: View>: View {
    let title: String?
    let data: [PropertyInspectorItem<Value>]
    let icon: (Value) -> Icon
    let label: (Value) -> Label
    let detail: (Value) -> Detail

    var body: some View {
        List {
            Section {
                ForEach(data) { item in
                    Toggle(isOn: item.isHighlighted) {
                        HStack {
                            icon(item.value).drawingGroup()
                            PropertyInspectorItemLabel(
                                label: label(item.value),
                                detail: detail(item.value)
                            )
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Color.clear)
                    .toggleStyle(
                        PropertyInspectorToggleStyle(
                            alignment: .center
                        )
                    )
                }
            } header: {
                if let title {
                    Toggle(sources: data, isOn: \.isHighlighted) {
                        Text(title)
                            .bold()
                            .font(.title2)
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
        .presentationBackground(Material.ultraThin)
        .toggleStyle(
            PropertyInspectorToggleStyle(
                alignment: .firstTextBaseline
            )
        )
    }
}

struct PropertyInspectorToggleStyle: ToggleStyle {
    let alignment: VerticalAlignment

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: alignment) {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
            }
            .tint(.primary)
        }
    }
}

struct PropertyInspectorItem<Value>: Identifiable, Equatable {
    let id = UUID()
    let value: Value
    let isHighlighted: Binding<Bool>

    static func == (lhs: PropertyInspectorItem<Value>, rhs: PropertyInspectorItem<Value>) -> Bool {
        lhs.id == rhs.id
    }
}

extension PropertyInspectorItem: Comparable where Value: Comparable {
    static func < (lhs: PropertyInspectorItem<Value>, rhs: PropertyInspectorItem<Value>) -> Bool {
        lhs.value < rhs.value
    }
}

struct PropertyInspectorItemLabel<Label: View, Detail: View>: View {
    let label: Label
    let detail: Detail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 3) // padding doesn't work

            label
                .foregroundStyle(.primary)
                .font(.body)

            detail

            Spacer().frame(height: 3) // padding doesn't work
        }
        .foregroundStyle(.secondary)
        .font(.caption2)
    }
}

public extension View {
    func propertyInspector<Value>(_ value: Value) -> some View {
        modifier(
            PropertyInspectorViewModifier(data: value)
        )
    }

    func disablePropertyInspector(_ disabled: Bool = true) -> some View {
        environment(\.propertyInspectorDisabled, disabled)
    }
}

struct PropertyInspectorViewModifier<Value>: ViewModifier  {
    let data: Value

    @State
    private var isHighlighted = false

    @Environment(\.propertyInspectorDisabled)
    private var disabled

    var item: PropertyInspectorItem<Value> {
        PropertyInspectorItem(value: data, isHighlighted: $isHighlighted)
    }

    func body(content: Content) -> some View {
        if disabled {
            content
        } else {
            PropertyInspectorHighlightView(isOn: $isHighlighted) {
                content.background(
                    Color.clear.preference(
                        key: PropertyInspectorItemKey<Value>.self,
                        value: [item]
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

struct PropertyInspectorHighlightView<Content: View>: View {
    @State
    private var animationToken = UUID()

    @Binding
    var isOn: Bool

    @ViewBuilder var content: Content

    var transition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: .random(in: 2 ... 2.5))),
            removal: .identity
        )
    }

    var body: some View {
        content
            .zIndex(isOn ? 999 : 0)
            .overlay {
                if isOn {
                    Rectangle()
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
