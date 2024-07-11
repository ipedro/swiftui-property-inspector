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
        VStack(spacing: 4) {
            title()
            let filters = context.filters.sorted()
            
            if !filters.isEmpty {
                PropertyInspectorFilters(
                    data: filters,
                    toggleAll: context.toggleAllFilters,
                    title: \.wrappedValue.description,
                    isOn: context.toggleFilter(_:)
                )
            }
        }
        .multilineTextAlignment(.leading)
        .environment(\.textCase, nil)
        .foregroundStyle(.primary)
    }

    private var accessoryTitle: String {
        if context.properties.isEmpty {
            return ""
        }
        let count = context.properties.count
        let allCount = context.allProperties.count
        if count != allCount {
            return "\(count) of \(allCount) items"
        }
        return "\(count) items"
    }

    @ViewBuilder
    private func title() -> some View {
        let formattedText = Text(data)
            .font(.title.weight(.medium))
            .lineLimit(1)

        if #available(iOS 16.0, *), !context.properties.isEmpty {
            Toggle(sources: context.properties, isOn: \.$isHighlighted) {
                HStack(alignment: .firstTextBaseline) {
                    formattedText

                    Text(accessoryTitle)
                        .contentTransition(.numericText())
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(uiColor: .systemBackground).opacity(0.5))
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(
                PropertyToggleStyle(alignment: .firstTextBaseline)
            )
        } else {
            formattedText.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
