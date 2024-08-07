import Combine
import SwiftUI

extension Context {
    final class Data: ObservableObject {
        private var cancellables = Set<AnyCancellable>()

        private var _allObjects = [PropertyType: Set<Property>]()

        private var _searchQuery = ""

        var allProperties = [Property]()

        var filters = Set<Filter<PropertyType>>()

        @Published
        var properties = [Property]() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Properties")
                    for property in properties {
                        print("\t- \(property)")
                    }
                #endif
            }
        }

        @Published
        var iconRegistry = RowViewBuilderRegistry() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Icons \(iconRegistry)")
                #endif
            }
        }

        @Published
        var labelRegistry = RowViewBuilderRegistry() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Labels \(labelRegistry)")
                #endif
            }
        }

        @Published
        var detailRegistry = RowViewBuilderRegistry() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Details \(iconRegistry)")
                #endif
            }
        }

        var allObjects: [PropertyType: Set<Property>] {
            get { _allObjects }
            set {
                guard _allObjects != newValue else { return }
                _allObjects = newValue
                makeProperties()
            }
        }

        var searchQuery: String {
            get { _searchQuery }
            set {
                guard _searchQuery != newValue else { return }
                _searchQuery = newValue
                makeProperties()
            }
        }

        init() {
            setupDebouncing()
        }

        private func isOn(filter: Filter<PropertyType>) -> Bool {
            if let index = filters.firstIndex(of: filter) {
                filters[index].isOn
            } else {
                false
            }
        }

        func toggleFilter(_ filter: Filter<PropertyType>) -> Binding<Bool> {
            Binding { [unowned self] in
                if let index = filters.firstIndex(of: filter) {
                    filters[index].isOn
                } else {
                    false
                }
            } set: { [unowned self] newValue in
                if let index = self.filters.firstIndex(of: filter) {
                    filters[index].isOn = newValue
                    _allObjects[filter.wrappedValue]?.forEach { prop in
                        if prop.isHighlighted {
                            prop.isHighlighted = false
                        }
                    }
                    makeProperties()
                }
            }
        }

        var toggleAllFilters: Binding<Bool> {
            let allSelected = !filters.map(\.isOn).contains(false)
            return Binding {
                allSelected
            } set: { [unowned self] newValue in
                for filter in filters {
                    filter.isOn = newValue
                }
                for set in _allObjects.values {
                    for prop in set where prop.isHighlighted {
                        prop.isHighlighted = false
                    }
                }
                makeProperties()
            }
        }

        private func setupDebouncing() {
            Just(_searchQuery)
                .removeDuplicates()
                .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
                .sink(receiveValue: { [unowned self] _ in
                    makeProperties()
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

            withAnimation(.inspectorDefault) {
                self.filters = filters
                self.allProperties = Array(all)
                self.properties = filter(in: Array(properties)).sorted()
            }
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
            let activeTypes = Set(filters.filter { $0.isOn }.map(\.wrappedValue))

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
