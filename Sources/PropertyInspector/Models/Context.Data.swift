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

import Combine
import SwiftUI

extension Context {
    final class Data: ObservableObject {
        private var cancellables = Set<AnyCancellable>()

        private var _allObjects = Set<Property>()

        private var _searchQuery = ""

        @Published
        var properties = [Property]()

        @Published
        var iconRegistry = RowViewBuilderRegistry()

        @Published
        var labelRegistry = RowViewBuilderRegistry()

        @Published
        var detailRegistry = RowViewBuilderRegistry()

        var allObjects: Set<Property> {
            get { _allObjects }
            set {
                guard _allObjects != newValue else { return }
                objectWillChange.send()
                _allObjects = newValue
                updateFilteredProperties(searchQuery: _searchQuery, allObjects: newValue)
            }
        }

        var searchQuery: String {
            get { _searchQuery }
            set {
                guard _searchQuery != newValue else { return }
                objectWillChange.send()
                _searchQuery = newValue
                updateFilteredProperties(searchQuery: newValue, allObjects: _allObjects)
            }
        }

        init() {
            setupDebouncing()
        }

        private func setupDebouncing() {
            Just(_searchQuery)
                .removeDuplicates()
                .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
                .sink(receiveValue: { [unowned self] newValue in
                    self.updateFilteredProperties(
                        searchQuery: newValue,
                        allObjects: self._allObjects
                    )
                })
                .store(in: &cancellables)
        }

        private func updateFilteredProperties(searchQuery: String, allObjects: Set<Property>) {
            properties = filterProperties(searchQuery: searchQuery, allObjects: allObjects)
        }

        private func filterProperties(searchQuery: String, allObjects: Set<Property>) -> [Property] {
            guard !searchQuery.isEmpty else {
                return allObjects.sorted()
            }

            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

            guard query.count > 1 else {
                return allObjects.sorted()
            }

            return allObjects.filter {
                if $0.stringValue.localizedCaseInsensitiveContains(query) { return true }
                if $0.stringValueType.localizedStandardContains(query) { return true }
                return $0.id.location.description.localizedStandardContains(query)
            }
            .sorted()
        }
    }
}
