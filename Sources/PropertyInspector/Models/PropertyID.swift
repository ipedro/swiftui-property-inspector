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

final class PropertyID {
    private let _uuid = UUID()

    /// The location of the property within the source code, provided for better traceability and debugging.
    let location: PropertyLocation

    let createdAt: Date

    /// A computed string that provides a sortable representation of the property based on its location and offset.
    private let sortString: String

    init(
        offset: Int,
        createdAt: Date,
        location: PropertyLocation
    ) {
        self.location = location
        self.createdAt = createdAt
        self.sortString = [
            location.id,
            String(createdAt.timeIntervalSince1970),
            String(offset)
        ].joined(separator: "_")
    }
}

extension PropertyID: Hashable {
    /// Compares two `Property` instances for equality, considering both their unique identifiers and highlight states.
    static func == (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs._uuid == rhs._uuid
    }

    /// Contributes to the hashability of the property, incorporating its unique identifier into the hash.
    func hash(into hasher: inout Hasher) {
        hasher.combine(_uuid)
    }
}

extension PropertyID: Comparable {
    /// Determines if one `ID` should precede another in a sorted list, based on a composite string that includes their location and value.
    static func < (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }
}
