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
    private var data: [ObjectIdentifier: RowBuilder]

    init(_ values: RowBuilder...) {
        self.data = values.reduce(into: [:], { partialResult, builder in
            partialResult[builder.id] = builder
        })
    }

    var isEmpty: Bool { data.isEmpty }

    var identifiers: [ObjectIdentifier] { Array(data.keys) }

    subscript(id: ObjectIdentifier) -> RowBuilder? {
        get { data[id] }
        set { data[id] = newValue }
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

    func makeBody(for property: Property, cache keyPath: KeyPath<Property, Binding<ObjectIdentifier?>>) -> AnyView? {
        let cache = property[keyPath: keyPath]

        if let key = cache.wrappedValue {
            let view = self[key]?.body(property.value)
            return view
        }

        for id in identifiers {
            if let view = self[id]?.body(property.value) {
                cache.wrappedValue = id
                return view
            }
        }

        cache.wrappedValue = ObjectIdentifier(Never.self)
        return nil
    }
}

struct RowBuilder: Hashable, Identifiable {
    let id: ObjectIdentifier
    let body: (Any) -> AnyView?

    init<D, C: View>(@ViewBuilder body: @escaping (D) -> C) {
        self.id = ObjectIdentifier(D.self)
        self.body = { anyValue in
            guard let castedValue = anyValue as? D else {
                return nil
            }
            return AnyView(body(castedValue))
        }
    }

    static func == (lhs: RowBuilder, rhs: RowBuilder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
