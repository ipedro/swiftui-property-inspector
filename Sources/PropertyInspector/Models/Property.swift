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

/// `Property` encapsulates details about a specific property within a view or model, including its value, display metadata, and location.
/// This struct is intended for internal use within the ``PropertyInspector`` framework to track and manage property information dynamically.
struct Property: Identifiable, Comparable, Hashable {
    struct ID: Hashable {
        private let id = UUID()
    }

    /// A unique identifier for the property, ensuring that each instance is uniquely identifiable.
    let id: ID = ID()

    /// The value of the property stored as `Any`, allowing it to accept any property type.
    let value: PropertyValue

    /// A binding to a Boolean that indicates whether the property is currently highlighted in the UI.
    @Binding
    var isHighlighted: Bool

    /// The location of the property within the source code, provided for better traceability and debugging.
    let location: PropertyLocation

    let createdAt: Date

    /// A computed string that provides a sortable representation of the property based on its location and index.
    private let sortString: String

    /// Returns the type of the value as a string, useful for dynamic type checks or displays.
    var stringValueType: String {
        String(describing: type(of: value.rawValue))
    }

    /// Returns the string representation of the property's value.
    var stringValue: String {
        String(describing: value.rawValue)
    }

    /// Initializes a new `Property` with detailed information about its value and location.
    /// - Parameters:
    ///   - value: The value of the property.
    ///   - isHighlighted: A binding to the Boolean indicating if the property is highlighted.
    ///   - location: The location of the property in the source code.
    ///   - index: An index used to uniquely sort the property when multiple properties share the same location.
    init(
        value: Any,
        isHighlighted: Binding<Bool>,
        location: PropertyLocation,
        index: Int,
        createdAt: Date
    ) {
        self.value = PropertyValue(value)
        self._isHighlighted = isHighlighted
        self.location = location
        self.createdAt = createdAt
        self.sortString = [
            location.id,
            String(createdAt.timeIntervalSince1970),
            String(index)
        ].joined(separator: "_")
    }

    /// Compares two `Property` instances for equality, considering both their unique identifiers and highlight states.
    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id && lhs.isHighlighted == rhs.isHighlighted
    }

    /// Determines if one `Property` should precede another in a sorted list, based on a composite string that includes their location and value.
    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }

    /// Contributes to the hashability of the property, incorporating its unique identifier into the hash.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
