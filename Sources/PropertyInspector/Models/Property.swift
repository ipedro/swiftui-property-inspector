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
final class Property: Identifiable, Comparable, Hashable, CustomStringConvertible {
    /// A unique identifier for the property, ensuring that each instance is uniquely identifiable.
    let id: PropertyID

    /// The value of the property stored as `Any`, allowing it to accept any property type.
    let value: PropertyValue

    /// A binding to a Boolean that indicates whether the property is currently highlighted in the UI.
    @Binding
    var isHighlighted: Bool

    /// Signal view updates
    let token: AnyHashable

    /// Returns the type of the value as a string, useful for dynamic type checks or displays.
    var stringValueType: String {
        String(describing: type(of: value.rawValue))
    }

    /// Returns the string representation of the property's value.
    var stringValue: String {
        String(describing: value.rawValue)
    }

    var description: String { stringValue }

    /// Initializes a new `Property` with detailed information about its value and location.
    /// - Parameters:
    ///   - value: The value of the property.
    ///   - isHighlighted: A binding to the Boolean indicating if the property is highlighted.
    ///   - location: The location of the property in the source code.
    ///   - offset: An offset used to uniquely sort the property when multiple properties share the same location.
    init(
        id: ID,
        token: AnyHashable,
        value: PropertyValue,
        isHighlighted: Binding<Bool>
    ) {
        self.token = token
        self.id = id
        self.value = value
        self._isHighlighted = isHighlighted
    }

    /// Compares two `Property` instances for equality, considering both their unique identifiers and highlight states.
    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id && 
        lhs.stringValue == rhs.stringValue &&
        lhs.token == rhs.token
    }

    /// Determines if one `Property` should precede another in a sorted list, based on a composite string that includes their location and value.
    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.id < rhs.id
    }

    /// Contributes to the hashability of the property, incorporating its unique identifier into the hash.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(stringValue)
        hasher.combine(token)
    }
}
