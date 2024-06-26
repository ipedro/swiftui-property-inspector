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

        private var _allObjects = [PropertyType: Set<Property>]()

        private var _searchQuery = ""

        @Published
        var properties = [Property]()

        var allProperties = [Property]()

        var filters = Set<Filter<PropertyType>>()

        @Published
        var iconRegistry = RowViewBuilderRegistry()

        @Published
        var labelRegistry = RowViewBuilderRegistry()

        @Published
        var detailRegistry = RowViewBuilderRegistry()

        var allObjects: [PropertyType: Set<Property>] {
            get { _allObjects }
            set {
                guard _allObjects != newValue else { return }
                objectWillChange.send()
                _allObjects = newValue
                makeProperties()
            }
        }

        var searchQuery: String {
            get { _searchQuery }
            set {
                guard _searchQuery != newValue else { return }
                objectWillChange.send()
                _searchQuery = newValue
                makeProperties()
            }
        }

        init() {
            setupDebouncing()
        }

        private func isOn(filter: Filter<PropertyType>) -> Bool {
            if let index = filters.firstIndex(of: filter) {
                return filters[index].isOn
            }
            return false
        }

        func isOn(filter: Filter<PropertyType>) -> Binding<Bool> {
            Binding { [unowned self] in
                if let index = self.filters.firstIndex(of: filter) {
                    return self.filters[index].isOn
                }
                return false
            } set: { [unowned self] newValue in
                if let index = self.filters.firstIndex(of: filter) {
                    self.objectWillChange.send()
                    self.filters[index].isOn = newValue
                    self._allObjects[filter.wrappedValue]?.forEach { prop in
                        if prop.isHighlighted {
                            prop.isHighlighted = false
                        }
                    }
                    self.makeProperties()
                }
            }
        }

        private func setupDebouncing() {
            Just(_searchQuery)
                .removeDuplicates()
                .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
                .sink(receiveValue: { [unowned self] newValue in
                    self.makeProperties()
                })
                .store(in: &cancellables)
        }

        private func isFilterEnabled(_ type: PropertyType) -> Bool? {
            for filter in filters where filter.wrappedValue == type {
                return filter.isOn
            }
            return nil
        }

        private func makeProperties() {
            var all = Set<Property>()
            var properties = Set<Property>()
            var filters = Set<Filter<PropertyType>>()

            for (type, set) in _allObjects {
                let searchResult = search(in: set)
                if !searchResult.isEmpty {
                    filters.insert(
                        Filter(
                            type,
                            isOn: isFilterEnabled(type) ?? true
                        )
                    )
                }
                all.formUnion(set)
                properties.formUnion(searchResult)
            }

            self.filters = filters
            self.allProperties = Array(all)
            self.properties = filter(in: Array(properties)).sorted()
        }

        private func search(in properties: Set<Property>) -> Set<Property> {
            guard !_searchQuery.isEmpty else {
                return properties
            }

            let query = _searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

            guard query.count > 1 else {
                return properties
            }

            return properties.filter {
                if $0.stringValue.localizedCaseInsensitiveContains(query) { return true }
                if $0.stringValueType.localizedStandardContains(query) { return true }
                return $0.id.location.description.localizedStandardContains(query)
            }
        }

        private func filter(in properties: [Property]) -> [Property] {
            let activeTypes = Set(filters.filter({ $0.isOn }).map(\.wrappedValue))
            
            guard activeTypes.count != filters.count else {
                return properties
            }

            let result = properties.filter {
                activeTypes.contains($0.value.type)
            }
            return result
        }
    }
}
