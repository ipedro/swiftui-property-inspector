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
    private var data: Context

    private var emptyMessage: String {
        data.searchQuery.isEmpty ?
        "Empty" :
        "No results for '\(data.searchQuery)'"
    }

    var body: some View {
        Rows._printChanges()
        return ForEach(data.properties) { property in
            Row(
                hideIcon: data.iconRegistry.isEmpty,
                isOn: property.$isHighlighted,
                icon:  icon(for: property),
                label: label(for: property),
                detail: detail(for: property)
            )
        }
        .animation(.interactiveSpring, value: data.properties)
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            if data.properties.isEmpty {
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

    private func icon(for property: Property) -> AnyView {
        data.iconRegistry.makeBody(property: property, fallback: {
            if !data.iconRegistry.isEmpty {
                Image(systemName: "info.circle.fill")
            }
        })
    }

    private func label(for property: Property) -> AnyView {
        data.labelRegistry.makeBody(property: property, fallback: {
            Text(verbatim: property.stringValue)
        })
    }

    private func detail(for property: Property) -> AnyView {
        data.detailRegistry.makeBody(property: property, fallback: {
            Text(verbatim: property.location.description)
        })
    }
}
