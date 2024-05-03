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

import Foundation
import SwiftUI

struct Rows: View {
    @EnvironmentObject
    private var context: Context.Data

    private var emptyMessage: String {
        context.searchQuery.isEmpty ?
        "Empty" :
        "No results for '\(context.searchQuery)'"
    }

    var body: some View {
        Rows._printChanges()
        return ForEach(context.properties) { property in
            Row(
                id: property.hashValue,
                isOn: property.$isHighlighted,
                hideIcon: context.iconRegistry.isEmpty,
                icon:  icon(for: property),
                label: label(for: property),
                detail: detail(for: property)
            )
            .equatable()
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            if context.properties.isEmpty {
                Text(emptyMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .multilineTextAlignment(.center)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 200
                    )
            }
        }
    }

    @ViewBuilder
    private func icon(for property: Property) -> some View {
        if let icon = context.iconRegistry.makeBody(property: property) {
            icon
        } else if !context.iconRegistry.isEmpty {
            Image(systemName: "info.circle.fill")
        }
    }

    @ViewBuilder
    private func label(for property: Property) -> some View {
        if let label = context.labelRegistry.makeBody(property: property) {
            label
        } else {
            Text(verbatim: property.stringValue)
        }
    }

    @ViewBuilder
    private func detail(for property: Property) -> some View {
        VStack(alignment: .leading) {
            context.detailRegistry.makeBody(property: property)
            Text(verbatim: property.id.location.description).opacity(2/3)
        }
    }
}
