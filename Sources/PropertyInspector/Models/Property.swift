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

struct Property: Identifiable, Comparable, CustomStringConvertible, Hashable {
    let id = UUID()

    let value: Any

    @Binding
    var isHighlighted: Bool

    @Binding
    var icon: ObjectIdentifier?

    @Binding
    var label: ObjectIdentifier?

    @Binding
    var detail: ObjectIdentifier?

    let location: PropertyLocation

    var description: String {
        sortString
    }

    var stringValueType: String {
        String(describing: type(of: value))
    }

    var stringValue: String {
        String(describing: value)
    }

    private let sortString: String

    init(
        value: Any,
        isHighlighted: Binding<Bool>,
        icon: Binding<ObjectIdentifier?>,
        label: Binding<ObjectIdentifier?>,
        detail: Binding<ObjectIdentifier?>,
        location: PropertyLocation,
        index: Int
    ) {
        self.value = value
        self._isHighlighted = isHighlighted
        self.location = location
        self._icon = icon
        self._label = label
        self._detail = detail
        self.sortString = [
            location.id,
            String(index),
            String(describing: value)
        ].joined(separator: "_")
    }

    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id &&
        lhs.isHighlighted == rhs.isHighlighted
    }

    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
