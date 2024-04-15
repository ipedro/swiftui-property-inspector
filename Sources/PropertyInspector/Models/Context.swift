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
    var iconRegistry = RowBuilderRegistry() {
        willSet {
            for property in allObjects where property.icon != nil {
                property.icon = nil
            }
        }
    }

    @Published
    var labelRegistry = RowBuilderRegistry() {
        willSet {
            for property in allObjects where property.label != nil {
                property.label = nil
            }
        }
    }

    @Published
    var detailRegistry = RowBuilderRegistry() {
        willSet {
            for property in allObjects where property.detail != nil {
                property.detail = nil
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

    func icon(for property: Property) -> AnyView? {
        iconRegistry.makeBody(property, cache: \.$icon)
    }

    func label(for property: Property) -> AnyView? {
        labelRegistry.makeBody(property, cache: \.$label)
    }

    func detail(for property: Property) -> AnyView? {
        detailRegistry.makeBody(property, cache: \.$detail)
    }

    func updateAllObjects(highlight newValue: Bool) {
        allObjects.enumerated().forEach { (offset, property) in
            property.isHighlighted = newValue
        }
    }
}
