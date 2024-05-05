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

struct PropertyType: Identifiable {
    let id: ObjectIdentifier
    let rawValue: Any.Type

    init<T>(_ subject: T) {
        let start = Date()
        let type: Any.Type
        if T.self == Any.self {
            // only use mirror as last resort
            type = Mirror(reflecting: subject).subjectType
            debugPrint(#function, "🐢", "Determined type \(type) in \((Date().timeIntervalSince(start) * 1000).formatted()) ms")
        } else {
            type = T.self
            debugPrint(#function, "🐰", "Determined type \(type) in \((Date().timeIntervalSince(start) * 1000).formatted()) ms")
        }
        self.id = ObjectIdentifier(type)
        self.rawValue = type
    }
}

extension PropertyType: Comparable {
    static func < (lhs: PropertyType, rhs: PropertyType) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }
}

extension PropertyType: CustomDebugStringConvertible {
    var debugDescription: String {
        "<PropertyType: \(description)>"
    }
}

extension PropertyType: CustomStringConvertible {
    var description: String {
        String(describing: rawValue)
    }
}

extension PropertyType: Equatable {
    static func == (lhs: RowViewBuilder.ID, rhs: RowViewBuilder.ID) -> Bool {
        lhs.id == rhs.id
    }
}

extension PropertyType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
