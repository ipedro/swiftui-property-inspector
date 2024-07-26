import Foundation
import SwiftUI

struct PropertyWriter: ViewModifier {
    var data: [PropertyValue]
    var location: PropertyLocation

    init(data: [PropertyValue], location: PropertyLocation) {
        self.data = data
        self.location = location
        _ids = State(initialValue: (0 ..< data.count).map { offset in
            PropertyID(
                offset: offset,
                createdAt: Date(),
                location: location
            )
        })
    }

    @State
    private var ids: [PropertyID]

    @State
    private var isHighlighted = false

    @Environment(\.isInspectable)
    private var isInspectable

    func body(content: Content) -> some View {
        #if VERBOSE
            Self._printChanges()
        #endif
        return content.setPreference(
            PropertyPreferenceKey.self, value: properties
        )
        .modifier(
            PropertyHiglighter(isOn: $isHighlighted)
        )
    }

    private var properties: [PropertyType: Set<Property>] {
        if !isInspectable {
            return [:]
        }
        let result: [PropertyType: Set<Property>] = zip(ids, data).reduce(into: [:]) { dict, element in
            let (id, value) = element
            let key = value.type
            var set = dict[key] ?? Set()
            set.insert(
                Property(
                    id: id,
                    token: String(describing: value.rawValue).hashValue,
                    value: value,
                    isHighlighted: $isHighlighted
                )
            )
            dict[key] = set
        }

        return result
    }
}
