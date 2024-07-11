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

struct PropertyInspectorFilters<Filter>: View where Filter: Hashable {
    var data: [Filter]
    
    @Binding

    var toggleAll: Bool

    var title: KeyPath<Filter, String>

    var isOn: (_ data: Filter) -> Binding<Bool>

    @EnvironmentObject
    private var context: Context.Data
    
    var body: some View {
        HStack(spacing: .zero) {
            toggleAllButton
            filterList
        }
        .font(.caption.bold())
        .toggleStyle(.button)
        .controlSize(.mini)
        .tint(.secondary)
        .padding(.vertical, 5)
    }

    private var toggleAllicon: String {
        "line.3.horizontal.decrease\(toggleAll ? ".circle.fill" : "")"
    }

    private var toggleAllAccessibilityLabel: Text {
        Text(toggleAll ? "Deselect All Filters" : "Select All Filters")
    }

    private var toggleAllButton: some View {
        Toggle(
            isOn: $toggleAll,
            label: {
                ZStack {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.title2)
                        .opacity(toggleAll ? 1 : 0)
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.subheadline)
                        .padding(.top, 1)
                        .opacity(toggleAll ? 0 : 1)
                }
                .accessibilityElement()
                .accessibilityLabel(toggleAllAccessibilityLabel)
            }
        )
        .buttonStyle(.plain)
        .tint(.primary)
        .symbolRenderingMode(.hierarchical)
    }

    private var filterList: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(data, id: \.self) { element in
                    Toggle(element[keyPath: title], isOn: isOn(element))
                }
            }
            .padding(
                EdgeInsets(
                    top: 2,
                    leading: 10,
                    bottom: 2,
                    trailing: 0
                )
            )

            .fixedSize(horizontal: false, vertical: true)
            .padding(.trailing, 20)
        }
        .mask({
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .leading,
                endPoint: .init(x: 0.04, y: 0.5)
            )
        })
        .padding(.trailing, -20)
        .animation(.inspectorDefault, value: data)
        .ios16_hideScrollIndicators()
    }
}

#Preview {
    FilterDemo()
}

private struct FilterDemo: View {
    @State var toggleAll = false
    var body: some View {
        PropertyInspectorFilters(
            data: ["test1", "test2", "test3", "test4"],
            toggleAll: $toggleAll,
            title: \.self,
            isOn: { _ in $toggleAll }
        )
    }
}
