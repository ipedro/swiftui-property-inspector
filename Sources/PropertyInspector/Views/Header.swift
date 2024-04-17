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

struct Header: View {
    var title: String?

    @EnvironmentObject
    private var data: Context

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let title {
                Text(title).bold().font(.title2)
            }

            TextField(
                "Search \(data.properties.count) items",
                text: $data.searchQuery
            )
            .frame(maxWidth: .infinity)

            if #available(iOS 16.0, *) {
                Toggle(sources: data.allObjects, isOn: \.$isHighlighted) {
                    EmptyView()
                }
                .toggleStyle(
                    PropertyToggleStyle(alignment: .firstTextBaseline)
                )
            }
        }
        .environment(\.textCase, nil)
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
}
