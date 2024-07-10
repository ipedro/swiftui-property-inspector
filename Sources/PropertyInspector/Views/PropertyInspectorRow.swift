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

struct PropertyInspectorRow<Icon: View, Label: View, Detail: View>: View, Equatable {
    static func == (lhs: PropertyInspectorRow<Icon, Label, Detail>, rhs: PropertyInspectorRow<Icon, Label, Detail>) -> Bool {
        lhs.id == rhs.id
    }
    var id: Int
    @Binding
    var isOn: Bool
    var hideIcon: Bool
    var icon: Icon
    var label: Label
    var detail: Detail
    
    @Environment(\.rowLabelFont)
    private var labelFont

    @Environment(\.rowDetailFont)
    private var detailFont

    var body: some View {
        #if VERBOSE
        PropertyInspectorRow._printChanges()
        #endif
        return Toggle(isOn: $isOn, label: content).toggleStyle(
            PropertyToggleStyle()
        )
        .foregroundStyle(.secondary)
        .padding(.vertical, 1)
        .listRowBackground(
            Rectangle().fill(.background.opacity(isOn ? 0.5 : 0))
        )
    }

    private func content() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label.foregroundStyle(.primary)
            detail.font(detailFont)
        }
        .allowsTightening(true)
        .multilineTextAlignment(.leading)
        .contentShape(Rectangle())
        .safeAreaInset(edge: .leading, alignment: .firstTextBaseline) {
            if !hideIcon {
                icon.scaledToFit().frame(width: 25)
            }
        }
        .font(labelFont)
    }
}

#Preview {
    PropertyInspectorRow(
        id: 0,
        isOn: .constant(true),
        hideIcon: false,
        icon: Image(systemName: "circle"),
        label: Text(verbatim: "Some text"),
        detail: Text(verbatim: "Some detail")
    )
}

#Preview {
    PropertyInspectorRow(
        id: 0,
        isOn: .constant(true),
        hideIcon: true,
        icon: Image(systemName: "circle"),
        label: Text(verbatim: "Some text"),
        detail: Text(verbatim: "Some detail")
    )
}
