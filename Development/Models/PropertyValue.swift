import Foundation

struct PropertyValue: Identifiable {
    let id: PropertyValueID
    let rawValue: Any
    var type: PropertyType { id.type }

    init<T>(_ value: T) {
        self.id = ID(value)
        self.rawValue = value
    }

    init(_ other: PropertyValue) {
        self = other
    }
}

struct PropertyValueID: Hashable {
    let hashValue: Int
    let type: PropertyType

    init<T>(_ value: T) {
        hashValue = String(describing: value).hashValue
        type = PropertyType(value)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
        hasher.combine(type)
    }
}
