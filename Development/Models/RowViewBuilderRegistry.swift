import Foundation
import SwiftUI

struct RowViewBuilderRegistry: Hashable, CustomStringConvertible {
    private var data: [PropertyType: RowViewBuilder]

    private let cache = HashableDictionary<PropertyValueID, HashableBox<AnyView>>()

    init(_ values: RowViewBuilder...) {
        data = values.reduce(into: [:]) { partialResult, builder in
            partialResult[builder.id] = builder
        }
    }

    var description: String {
        "\(Self.self)\(data.keys.map { "\n\t-\($0.rawValue)" }.joined())"
    }

    var isEmpty: Bool { data.isEmpty }

    var identifiers: [PropertyType] {
        Array(data.keys)
    }

    subscript(id: PropertyType) -> RowViewBuilder? {
        get {
            data[id]
        }
        set {
            if data[id] != newValue {
                data[id] = newValue
            }
        }
    }

    mutating func merge(_ other: RowViewBuilderRegistry) {
        data.merge(other.data) { content, _ in
            content
        }
    }

    func merged(_ other: RowViewBuilderRegistry) -> Self {
        var copy = self
        copy.merge(other)
        return copy
    }

    func makeBody(property: Property) -> AnyView? {
        if let cached = resolveFromCache(property: property) {
            #if VERBOSE
                print("[PropertyInspector]", "♻️", property.stringValue, "resolved from cache")
            #endif
            return cached
        } else if let body = createBody(property: property) {
            #if VERBOSE
                print("[PropertyInspector]", "🆕", property.stringValue, "created new view")
            #endif
            return body
        }
        return nil
    }

    private func resolveFromCache(property: Property) -> AnyView? {
        if let cached = cache[property.value.id] {
            return cached.value
        }
        return nil
    }

    #if DEBUG
        private func createBody(property: Property) -> AnyView? {
            var matches = [PropertyType: AnyView]()

            for id in identifiers {
                if let view = data[id]?.body(property) {
                    matches[id] = view
                }
            }

            if matches.keys.count > 1 {
                let matchingTypes = matches.keys.map { String(describing: $0.rawValue) }
                print(
                    "[PropertyInspector]",
                    "⚠️ Warning:",
                    "Undefined behavior.",
                    "Multiple row builders",
                    "match '\(property.stringValueType)' declared in '\(property.id.location)':",
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
