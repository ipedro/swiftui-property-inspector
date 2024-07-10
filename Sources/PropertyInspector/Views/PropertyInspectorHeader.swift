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

struct PropertyInspectorHeader: View {
    var data: LocalizedStringKey

    init?(data: LocalizedStringKey?) {
        guard let data else { return nil }
        self.data = data
    }

    @EnvironmentObject
    private var context: Context.Data
    
    var body: some View {
        VStack {
            title()
            let filters = context.filters.sorted()
            if !filters.isEmpty {
                filterList(data: filters)
            }
        }
        .ios16_hideScrollIndicators()
        .ios17_scrollClipDisabled()
        .multilineTextAlignment(.leading)
        .environment(\.textCase, nil)
        .foregroundStyle(.primary)
        .padding(
            EdgeInsets(top: 10, leading: 0, bottom: 8, trailing: 0)
        )
    }

    private func filterList(data: [Context.Filter<PropertyType>]) -> ScrollView<some View> {
        ScrollView(.horizontal) {
            LazyHStack(pinnedViews: .sectionHeaders) {
                let allSelected = !data.map(\.isOn).contains(false)
                Section {
                    HStack {
                        ForEach(data, id: \.self) { filter in
                            Toggle(
                                filter.wrappedValue.description,
                                isOn: context.isOn(filter: filter)
                            )
                        }
                    }
                } header: {
                    header(data, isOn: allSelected).buttonStyle(.plain)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .font(.caption.bold())
            .toggleStyle(.button)
            .controlSize(.mini)
            .tint(.secondary)
            .padding(.vertical, 5)
        }
    }

    @ViewBuilder
    private func header(_ filters: [Context.Filter<PropertyType>], isOn: Bool) -> some View {
        Toggle(
            isOn: Binding {
                isOn
            } set: { newValue in
                filters.forEach {
                    context.isOn(filter: $0).wrappedValue = newValue
                }
            },
            label: {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .accessibilityLabel(Text(isOn ? "Deselect All Filters" : "Select All Filters"))
                    .background {
                        Circle().fill(Color(uiColor: .systemBackground))
                    }
            }
        )
    }

    @ViewBuilder
    private func title() -> some View {
        let text = if context.properties.isEmpty {
            Text(data)
        } else {
            Text(data) + Text(" (\(context.properties.count))")
        }

        let formattedText = text.bold()
            .font(.title3)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

        if #available(iOS 16.0, *), !context.properties.isEmpty {
            Toggle(sources: context.properties, isOn: \.$isHighlighted) {
                formattedText
            }
            .toggleStyle(
                PropertyToggleStyle(alignment: .firstTextBaseline)
            )
        } else {
            formattedText
        }
    }
}

private extension View {
    @ViewBuilder
    func ios17_scrollClipDisabled() -> some View {
        if #available(iOS 17.0, *) {
            scrollClipDisabled()
        } else {
            // Fallback on earlier versions
            self
        }
    }

    @ViewBuilder
    func ios16_hideScrollIndicators(_ hide: Bool = true) -> some View {
        if #available(iOS 16.0, *) {
            scrollIndicators(hide ? .hidden : .automatic)
        } else {
            // Fallback on earlier versions
            self
        }
    }
}
