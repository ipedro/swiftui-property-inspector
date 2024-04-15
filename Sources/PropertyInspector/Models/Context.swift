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

final class Context: ObservableObject {
    @Published
    var allObjects = [Property]()

    @Published
    var searchQuery = ""

    @Published
    var iconBuilders = ViewBuilderRegistry() {
        willSet {
            for property in allObjects where property.iconBuilder != nil {
                property.iconBuilder = nil
            }
        }
    }

    @Published
    var labelBuilders = ViewBuilderRegistry() {
        willSet {
            for property in allObjects where property.labelBuilder != nil {
                property.labelBuilder = nil
            }
        }
    }

    @Published
    var detailBuilders = ViewBuilderRegistry() {
        willSet {
            for property in allObjects where property.detailBuilder != nil {
                property.detailBuilder = nil
            }
        }
    }

    var properties: [Property] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return allObjects }
        return allObjects.filter {
            String(describing: $0).localizedCaseInsensitiveContains(query)
        }
    }

    func makeIcon(_ property: Property) -> AnyView? {
        makeBody(property, location: iconBuilders, cache: \.$iconBuilder)
    }

    func makeLabel(_ property: Property) -> AnyView? {
        makeBody(property, location: labelBuilders, cache: \.$labelBuilder)
    }

    func makeDetail(_ property: Property) -> AnyView? {
        makeBody(property, location: detailBuilders, cache: \.$detailBuilder)
    }

    private func makeBody(
        _ property: Property,
        location: ViewBuilderRegistry,
        cache keyPath: KeyPath<Property, Binding<ObjectIdentifier?>>
    ) -> AnyView? {
        let cache = property[keyPath: keyPath]

        if let key = cache.wrappedValue {
            let view = location[key]?.body(property.value)
            return view
        }

        for id in location.identifiers {
            if let view = location[id]?.body(property.value) {
                cache.wrappedValue = id
                return view
            }
        }

        cache.wrappedValue = ObjectIdentifier(Any.self)
        return nil
    }
}
