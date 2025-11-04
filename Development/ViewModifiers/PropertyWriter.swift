import Foundation
import SwiftUI

struct PropertyWriter<S: Shape>: ViewModifier {
    var data: [PropertyValue]
    var location: PropertyLocation
    var shape: S

    init(data: [PropertyValue], shape: S, location: PropertyLocation) {
        self.data = data
        self.shape = shape
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
    
    @State
    private var cache = PropertyCache()

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
            PropertyHiglighter(isOn: $isHighlighted, shape: shape)
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
            
            // ✅ Use cache to avoid recreating Property objects
            let property = cache.property(
                for: id,
                token: String(describing: value.rawValue).hashValue,
                value: value,
                isHighlighted: $isHighlighted
            )
            set.insert(property)
            dict[key] = set
        }

        return result
    }
}
