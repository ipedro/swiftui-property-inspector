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

struct RowBuilderRegistry: Hashable {

    struct Key: Identifiable, Hashable {
        let id: ObjectIdentifier
        let type: Any.Type

        init<D>(_ data: D.Type = D.self) {
            self.id = ObjectIdentifier(data)
            self.type = data
        }

        static func == (lhs: RowBuilderRegistry.Key, rhs: RowBuilderRegistry.Key) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    private var data: [Key: RowBuilder]

    private let cache = Cache<UUID, Key>()

    init(_ values: RowBuilder...) {
        self.data = values.reduce(into: [:], { partialResult, builder in
            partialResult[builder.id] = builder
        })
    }

    var isEmpty: Bool { data.isEmpty }

    var identifiers: [Key] {
        Array(data.keys)
    }

    subscript(id: Key) -> RowBuilder? {
        get {
            data[id]
        }
        set {
            if data[id] != newValue {
                data[id] = newValue
            }
        }
    }

    mutating func merge(_ other: RowBuilderRegistry) {
        data.merge(other.data) { content, _ in
            content
        }
    }

    func merged(_ other: RowBuilderRegistry) -> Self {
        var copy = self
        copy.merge(other)
        return copy
    }

    func makeBody<V: View>(property: Property, @ViewBuilder fallback: () -> V) -> AnyView {
        if let key = cache[property.id] {
            if let view = data[key]?.body(property.value) {
                return view
            } else {
                cache[property.id] = nil
                print("busted stale cache")
            }
        }

        var matches = [RowBuilderRegistry.Key: AnyView]()

        for id in identifiers {
            if let view = data[id]?.body(property.value) {
                matches[id] = view
            }
        }

        #if DEBUG
        if matches.keys.count > 1 {
            let matchingTypes = matches.keys.map({ String(describing: $0.type) })

            print(
                "[PropertyInspector]",
                "⚠️ Warning:",
                #function,
                "–",
                "Multiple row builders match value of type '\(property.stringValueType)' which can cause undefined behavior:",
                matchingTypes.sorted().joined(separator: ", ")
            )
        }
        #endif

        if let match = matches.first {
            cache[property.id] = match.key
            return match.value
        }

        return AnyView(fallback())
    }
}
