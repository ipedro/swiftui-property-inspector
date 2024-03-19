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
    let content: Content
    let icon: (Value) -> Icon
    let label: (Value) -> Label
    let detail: (Value) -> Detail
    let sort: (Value, Value) -> Bool

    @State
    var data: [PropertyInspectorItem<Value>] = []

    @Binding
    var isPresented: Bool

    let title: String?

    public init(
        _ title: String? = nil,
        _ value: Value.Type,
        isPresented: Binding<Bool>,
        sort: @escaping (Value, Value) -> Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder icon: @escaping (Value) -> Icon,
        @ViewBuilder label: @escaping (Value) -> Label,
        @ViewBuilder detail: @escaping (Value) -> Detail
    ) {
        self.title = title
        self._isPresented = isPresented
        self.sort = sort
        self.content = content()
        self.icon = icon
        self.label = label
        self.detail = detail
    }

    public init(
        _ title: String? = nil,
        _ value: Value.Type,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder icon: @escaping (Value) -> Icon,
        @ViewBuilder label: @escaping (Value) -> Label,
        @ViewBuilder detail: @escaping (Value) -> Detail
    ) where Value: Comparable {
        self.title = title
        self._isPresented = isPresented
        self.sort = { $0 < $1 }
        self.content = content()
        self.icon = icon
        self.label = label
        self.detail = detail
    }

    public var body: some View {
        content
            .onPreferenceChange(InspectorPreferenceKey<Value>.self) { newValue in
                data = newValue.sorted {
                    sort($0.wrappedValue, $1.wrappedValue)
                }
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
                    PropertyInspectorItemList(
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

@available(iOS 16.4, *)
struct PropertyInspectorItemList<Value, Label: View, Detail: View, Icon: View>: View {
    typealias Data = [PropertyInspectorItem<Value>]
    let title: String?
    let data: Data
    let icon: (Value) -> Icon
    let label: (Value) -> Label
    let detail: (Value) -> Detail

    var body: some View {
        List {
            Section {
                ForEach(data) { item in
                    Toggle(isOn: item.isHighlighted) {
                        HStack {
                            icon(item.wrappedValue).drawingGroup()
                            PropertyInspectorItemLabel(
                                label: label(item.wrappedValue),
                                detail: detail(item.wrappedValue)
                            )
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Color.clear)
                    .toggleStyle(_ToggleStyle(alignment: .center))
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
            .fraction(3/4),
        ])
        .presentationBackgroundInteraction(.enabled)
        .presentationContentInteraction(.scrolls)
        .presentationCornerRadius(20)
        .presentationBackground(Material.ultraThin)
        .toggleStyle(_ToggleStyle(alignment: .firstTextBaseline))
    }

    struct _ToggleStyle: ToggleStyle {
        let alignment: VerticalAlignment

        func makeBody(configuration: Configuration) -> some View {
            Button {
                configuration.isOn.toggle()
            } label: {
                HStack(alignment: alignment) {
                    configuration.label

                    Spacer()

                    Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                        .tint(.accentColor)
                }
                .tint(.primary)
            }
        }
    }
}

struct PropertyInspectorItem<Value>: Identifiable, Equatable {
    let id = UUID()
    let wrappedValue: Value
    let isHighlighted: Binding<Bool>

    static func == (lhs: PropertyInspectorItem<Value>, rhs: PropertyInspectorItem<Value>) -> Bool {
        lhs.id == rhs.id
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
}

struct PropertyInspectorViewModifier<Value>: ViewModifier  {
    typealias Key = InspectorPreferenceKey<Value>

    @State
    var animationValue = UUID()

    /// The current selection state of the dynamic value, observed for changes to update the view.
    let data: Value

    @State
    var highlight = false

    /// The body of the `PropertyInspectorContentView`, rendering the content based on the current selection.
    /// It uses a clear background view to capture preference changes, allowing the dynamic property picker system to react.
    func body(content: Content) -> some View {
        content
            .zIndex(highlight ? 999 : 0)
            .background(background)
            .overlay {
                if highlight {
                    Rectangle()
                        .stroke(lineWidth: 1.5)
                        .fill(Color.blue)
                        .id(animationValue)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(
                                    with: .scale(
                                        scale: .random(in: 2 ... 2.5)
                                    )
                                ),
                                removal: .identity
                            )
                        )
                }
            }
            .compositingGroup()
            .animation(
                .snappy(
                    duration: .random(in: 0.2 ... 0.6),
                    extraBounce: .random(in: 0 ... 0.1)
                )
                .delay(.random(in: 0 ... 0.2)),
                value: animationValue
            )
            .onChange(of: highlight) { newValue in
                if newValue {
                    animationValue = UUID()
                }
            }
    }

    var highlightColor: Color {
        highlight ? .blue.opacity(0.75) : .clear
    }

    @ViewBuilder
    var highlightView: some View {
        Rectangle().stroke(highlightColor)
    }

    var item: PropertyInspectorItem<Value> {
        PropertyInspectorItem(wrappedValue: data, isHighlighted: $highlight)
    }

    /// A helper view for capturing and forwarding preference changes without altering the main content's appearance.
    var background: some View {
        Color.clear.preference(key: Key.self, value: [item])
    }

}

struct InspectorPreferenceKey<Value>: PreferenceKey {
    /// The default value for the dynamic value entries.
    static var defaultValue: [PropertyInspectorItem<Value>] { [] }

    /// Combines the current value with the next value.
    ///
    /// - Parameters:
    ///   - value: The current value of dynamic value entries.
    ///   - nextValue: A closure that returns the next set of dynamic value entries.
    static func reduce(
        value: inout [PropertyInspectorItem<Value>],
        nextValue: () -> [PropertyInspectorItem<Value>]
    ) {
        value = value + nextValue()
    }
}
