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

struct PropertyViewBuilderRegistry: Hashable {
    private var data: [PropertyViewBuilder.ID: PropertyViewBuilder]

    private let cache = Cache<PropertyValue.ID, HashableBox<AnyView>>()

    init(_ values: PropertyViewBuilder...) {
        self.data = values.reduce(into: [:], { partialResult, builder in
            partialResult[builder.id] = builder
        })
    }

    var isEmpty: Bool { data.isEmpty }

    var identifiers: [PropertyViewBuilder.ID] {
        Array(data.keys)
    }

    subscript(id: PropertyViewBuilder.ID) -> PropertyViewBuilder? {
        get {
            data[id]
        }
        set {
            if data[id] != newValue {
                data[id] = newValue
            }
        }
    }

    mutating func merge(_ other: PropertyViewBuilderRegistry) {
        data.merge(other.data) { content, _ in
            content
        }
    }

    func merged(_ other: PropertyViewBuilderRegistry) -> Self {
        var copy = self
        copy.merge(other)
        return copy
    }

    func makeBody<V: View>(property: Property, @ViewBuilder fallback: () -> V) -> AnyView {
        if let cached = resolveFromCache(property: property) {
            print("[PropertyInspector]", "♻️", property.value.id, "resolved from cache")
            return cached
        }
        else if let body = createBody(property: property) {
            print("[PropertyInspector]", "🆕", property.value.id, "created custom view")
            return body
        }
        print("[PropertyInspector]", "🍁", property.value.id, "created fallback view")
        let fallback = AnyView(fallback())
        cache[property.value.id] = HashableBox(fallback)
        return fallback
    }

    private func resolveFromCache(property: Property) -> AnyView? {
        if let cached = cache[property.value.id] {
            return cached.value
        }
        return nil
    }

    #if DEBUG
    private func createBody(property: Property) -> AnyView? {
        var matches = [PropertyViewBuilder.ID: AnyView]()

        for id in identifiers {
            if let view = data[id]?.body(property) {
                matches[id] = view
            }
        }

        if matches.keys.count > 1 {
            let matchingTypes = matches.keys.map({ String(describing: $0.type) })
            print(
                "[PropertyInspector]",
                "⚠️ Warning:",
                "Undefined behavior.",
                "Multiple row builders",
                "match '\(property.stringValueType)' declared in '\(property.location)':",
                matchingTypes.sorted().joined(separator: ", ")
            )
        }

        if let match = matches.first {
            cache[property.value.id] = HashableBox(match.value)
            return match.value
        }

        return nil
    }
    #else
    private func createBody(property: Property) -> AnyView? {
        for id in identifiers {
            if let view = data[id]?.body(property) {
                cache[property.value.id] = HashableBox(view)
                return view
            }
        }
        return nil
    }
    #endif
}
