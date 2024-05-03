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

struct TypeReference: Identifiable {
    let id: ObjectIdentifier
    let rawValue: Any.Type

    init<D>(_ data: D.Type = D.self) {
        self.id = ObjectIdentifier(data)
        self.rawValue = data
    }
}

extension TypeReference: Comparable {
    static func < (lhs: TypeReference, rhs: TypeReference) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }
}

extension TypeReference: CustomDebugStringConvertible {
    var debugDescription: String {
        "<TypeReference: \(description)>"
    }
}

extension TypeReference: CustomStringConvertible {
    var description: String {
        String(describing: rawValue)
    }
}

extension TypeReference: Hashable {
    static func == (lhs: RowViewBuilder.ID, rhs: RowViewBuilder.ID) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
