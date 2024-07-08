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

struct PropertyWriter: ViewModifier  {
    var data: [PropertyValue]
    var location: PropertyLocation

    init(data: [PropertyValue], location: PropertyLocation) {
        self.data = data
        self.location = location
        self._ids = State(initialValue: (0..<data.count).map { offset in
            PropertyID(
                offset: offset,
                createdAt: Date(),
                location: location
            )
        })
    }

    @State
    private var ids: [PropertyID]

    @State
    private var changes = 0
//    {
//        didSet {
//            debugPrint("[PropertyInspector]", "🆕", String(describing: data), "updated count")
//        }
//    }

    @State
    private var _isOn = false

    private var isOn: Binding<Bool> {
        Binding {
            isInspectable && _isOn
        } set: { newValue in
            _isOn = newValue
        }
    }

    @Environment(\.isInspectable)
    private var isInspectable

    func body(content: Content) -> some View {
        PropertyWriter._printChanges()
        return content.setPreference(
            PropertyPreferenceKey.self, value: properties
        )
        .modifier(
            PropertyHiglighter(isOn: isOn)
        )
    }

    private var properties: [PropertyType: Set<Property>] {
        if !isInspectable {
            return [:]
        }
        let result: [PropertyType: Set<Property>] = zip(ids, data).reduce(into: [PropertyType: Set<Property>]()) { dict, element in
            let (id, value) = element
            let key = value.type
            var set = dict[key] ?? Set()
            set.insert(
                Property(
                    id: id,
                    changes: changes,
                    value: value,
                    isHighlighted: Binding(
                        get: {
                            isOn.wrappedValue
                        },
                        set: { newValue in
                            isOn.wrappedValue = newValue
                            changes += 1
                        }
                    )
                )
            )
            dict[key] = set
        }

        return result
    }

}
