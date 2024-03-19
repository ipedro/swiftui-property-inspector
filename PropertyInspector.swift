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
public struct PropertyInspector<Content: View, Value>: View {
    private let content: Content
    private let propertyTitle: (Value) -> Text
    private let propertyDetail: (Value) -> Text?
    private let propertyIcon: (Value) -> Image?

    @State
    private var data: [PropertyInspectorItem<Value>] = []

    @Binding
    private var isPresented: Bool

    let title: String?

    public init(
        _ title: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder propertyIcon: @escaping (Value) -> Image?,
        @ViewBuilder propertyTitle: @escaping (Value) -> Text,
        @ViewBuilder propertyDetail: @escaping (Value) -> Text?
    ) {
        self.title = title
        self._isPresented = isPresented
        self.content = content()
        self.propertyIcon = propertyIcon
        self.propertyTitle = propertyTitle
        self.propertyDetail = propertyDetail
    }

    public init(
        _ title: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder propertyTitle: @escaping (Value) -> Text
    ) {
        self.init(
            title,
            isPresented: isPresented,
            content: content,
            propertyIcon: { _ in Optional<Image>.none },
            propertyTitle: propertyTitle,
            propertyDetail: { _ in Optional<Text>.none }
        )
    }

    public init(
        _ title: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder propertyTitle: @escaping (Value) -> Text,
        @ViewBuilder propertyDetail: @escaping (Value) -> Text?
    ) {
        self.init(
            title,
            isPresented: isPresented,
            content: content,
            propertyIcon: { _ in Optional<Image>.none },
            propertyTitle: propertyTitle,
            propertyDetail: propertyDetail
        )
    }

    public var body: some View {
        content
            .onPreferenceChange(InspectorPreferenceKey<Value>.self) {
                data = $0
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
                    PropertyInepctorItemList(
                        title: title,
                        data: data,
                        propertyIcon: propertyIcon,
                        propertyTitle: propertyTitle,
                        propertyDetail: propertyDetail
                    )
                }
            }
    }
}

@available(iOS 16.4, *)
private struct PropertyInepctorItemList<Value>: View {
    let title: String?
    let data: [PropertyInspectorItem<Value>]
    let propertyIcon: (Value) -> Image?
    let propertyTitle: (Value) -> Text
    let propertyDetail: (Value) -> Text?

    var body: some View {
        List {
            Section {
                ForEach(data) { item in
                    PropertyInspectorItemView(
                        highlight: item.isHighlighted,
                        icon: propertyIcon(item.wrappedValue),
                        title: propertyTitle(item.wrappedValue),
                        detail: propertyDetail(item.wrappedValue)
                    )
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

    private struct _ToggleStyle: ToggleStyle {
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

private struct PropertyInspectorItem<Value>: Identifiable, Equatable {
    let id = UUID()
    let wrappedValue: Value
    let isHighlighted: Binding<Bool>

    static func == (lhs: PropertyInspectorItem, rhs: PropertyInspectorItem) -> Bool {
        lhs.id == rhs.id
    }
}

private struct PropertyInspectorItemView: View {
    @Binding var highlight: Bool
    let icon: Image?
    let title: Text
    let detail: Text?

    var body: some View {
        Toggle(isOn: $highlight) {
            HStack {
                icon.drawingGroup()
                TitleView(title: title, detail: detail)
            }
            .contentShape(Rectangle())
        }
    }

    private struct TitleView: View {
        let title: Text
        let detail: Text?

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 3) // padding doesn't work

                title
                    .foregroundStyle(.primary)
                    .font(.body)

                detail

                Spacer().frame(height: 3) // padding doesn't work
            }
            .foregroundStyle(.secondary)
            .font(.caption2)
        }
    }

}

extension View {
    func propertyInspectorValue<Value>(_ token: Value) -> some View {
        modifier(
            PropertyInspectorViewModifier(data: token)
        )
    }
}

private struct PropertyInspectorViewModifier<Value>: ViewModifier  {
    private typealias Key = InspectorPreferenceKey<Value>

    @State
    private var animationValue = UUID()

    /// The current selection state of the dynamic value, observed for changes to update the view.
    let data: Value

    @State
    private var highlight = false

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

    private var highlightColor: Color {
        highlight ? .blue.opacity(0.75) : .clear
    }

    @ViewBuilder
    private var highlightView: some View {
        Rectangle().stroke(highlightColor)
    }

    private var item: PropertyInspectorItem<Value> {
        PropertyInspectorItem(wrappedValue: data, isHighlighted: $highlight)
    }

    /// A helper view for capturing and forwarding preference changes without altering the main content's appearance.
    private var background: some View {
        Color.clear.preference(key: Key.self, value: [item])
    }

}

private struct InspectorPreferenceKey<Value>: PreferenceKey {
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
        // TODO: re-introduce sorting
        //value.sort()
    }
}
