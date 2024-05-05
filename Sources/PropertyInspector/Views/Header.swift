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

struct Header: View {
    var data: LocalizedStringKey

    init?(data: LocalizedStringKey?) {
        guard let data else { return nil }
        self.data = data
    }

    @EnvironmentObject
    private var context: Context.Data

    private var text: Text {
        Text(data) + Text(" (\(context.properties.count))")
    }

    private func title() -> Group<_ConditionalContent<AnyView, Text>> {
        return Group {
            if #available(iOS 16.0, *) {
                Toggle(sources: context.properties, isOn: \.$isHighlighted) {
                    text.bold().font(.title3).frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .lineLimit(1)
                }
                .toggleStyle(
                    PropertyToggleStyle(alignment: .firstTextBaseline)
                )
            } else {
                text
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            title()
            ScrollView(.horizontal) {
                HStack(content: {
                    ForEach(context.filters.sorted(), id: \.self) { filter in
                        Toggle(isOn: context.isOn(filter: filter)) {
                            Text(verbatim: filter.wrappedValue.description)
                                .font(.caption2)
                                .padding(
                                    EdgeInsets(
                                        top: 2,
                                        leading: 5,
                                        bottom: 2,
                                        trailing: 5
                                    )
                                )
                                .foregroundStyle(filter.isOn ? Color(uiColor: .systemBackground) : .secondary)
                        }
                        .toggleStyle(_FilterToggleStyle())
                        .background {
                            if filter.isOn {
                                Capsule().fill(.secondary)
                            } else {
                                Capsule().strokeBorder()
                            }
                        }
                    }
                })
            }
        }
        .ios16_hideScrollIndicators()
        .ios17_scrollClipDisabled()
        .multilineTextAlignment(.leading)
        .environment(\.textCase, nil)
        .foregroundStyle(.primary)
        .tint(.primary)
        .padding(
            EdgeInsets(
                top: 10,
                leading: 0,
                bottom: 8,
                trailing: 0
            )
        )
    }

    private struct _FilterToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button(action: {
                configuration.isOn.toggle()
            }, label: {
                configuration.label
            })
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
