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

struct PropertySelector: ViewModifier  {
    var data: [Any]
    var location: PropertyLocation

    init(data: [Any], location: PropertyLocation) {
        self.data = data
        self.location = location
        self._ids = State(initialValue: data.map { _ in
            Property.ID()
        })
    }

    @State
    private var ids: [Property.ID]

    @State
    private var createdAt = Date()

    @State
    private var changes = 0 {
        didSet {
            print("[PropertyInspector]", "🆕", String(describing: data), "updated count")
        }
    }

    @State
    private var _isOn = false

    private var isOn: Binding<Bool> {
        Binding {
            !disabled && _isOn
        } set: { newValue in
            _isOn = newValue
        }
    }

    @Environment(\.propertyInspectorHidden)
    private var disabled

    func body(content: Content) -> some View {
        PropertySelector._printChanges()
        return content.setPreference(
            PropertyPreferenceKey.self, value: Set(properties)
        )
        .modifier(
            HighlightModifier(isOn: isOn)
        )
    }

    private var properties: [Property] {
        if disabled { return [] }

        return data.enumerated().map { (index, element) in
            Property(
                id: ids[index],
                value: element,
                isHighlighted: Binding(
                    get: {
                        isOn.wrappedValue
                    },
                    set: { newValue in
                        isOn.wrappedValue = newValue
                        changes += 1
                    }
                ),
                location: location,
                index: index,
                createdAt: createdAt,
                changes: changes
            )
        }
    }

}
