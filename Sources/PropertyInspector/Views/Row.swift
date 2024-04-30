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

struct Row: View {
    var hideIcon: Bool
    @Binding var isOn: Bool
    var icon: AnyView
    var label: AnyView
    var detail: AnyView

    private var leading: CGFloat? {
        hideIcon ? 0 : 25
    }

    var body: some View {
        Row._printChanges()
        return Toggle(isOn: $isOn, label: content)
            .toggleStyle(
                PropertyToggleStyle(alignment: .firstTextBaseline)
            )
            .foregroundStyle(.secondary)
            .symbolRenderingMode(.hierarchical)
    }

    private func content() -> some View {
        VStack(alignment: .leading) {
            iconAndLabel

            detail.font(.caption).padding(.leading, leading)
        }
        .allowsTightening(true)
        .contentShape(Rectangle())
        .multilineTextAlignment(.leading)
    }

    private var iconAndLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: .zero) {
            icon.opacity(hideIcon ? 0 : 1).frame(
                width: leading,
                alignment: .leading
            )

            label.foregroundStyle(.primary)
        }
        .font(.footnote.bold())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
