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
    var iconRegistry = PropertyViewBuilderRegistry()

    @Published
    var labelRegistry = PropertyViewBuilderRegistry()

    @Published
    var detailRegistry = PropertyViewBuilderRegistry()

    var properties: [Property] {
        var query = searchQuery
        if query.isEmpty { return allObjects }
        query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count > 1 else { return allObjects }
        return allObjects.filter {
            if $0.stringValue.localizedCaseInsensitiveContains(query) {
                return true
            }
            if $0.stringValueType.localizedStandardContains(query) {
                return true
            }

            return $0.location.description.localizedStandardContains(query)
        }
    }
}
