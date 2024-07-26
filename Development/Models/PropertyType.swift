import Foundation

struct PropertyType: Identifiable {
    let id: ObjectIdentifier
    let rawValue: Any.Type

    init<T>(_ subject: T) {
        let start = Date()
        let type: Any.Type
        if T.self == Any.self {
            // only use mirror as last resort
            type = Mirror(reflecting: subject).subjectType
            #if VERBOSE
                let elapsedTime = (Date().timeIntervalSince(start) * 1000).formatted()
                print(#function, "🐢", "Determined type \(type) in \(elapsedTime) ms")
            #endif
        } else {
            type = T.self
            #if VERBOSE
                let elapsedTime = (Date().timeIntervalSince(start) * 1000).formatted()
                print(#function, "🐰", "Determined type \(type) in \(elapsedTime) ms")
            #endif
        }
        id = ObjectIdentifier(type)
        rawValue = type
    }
}

extension PropertyType: Comparable {
    static func < (lhs: PropertyType, rhs: PropertyType) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }
}

extension PropertyType: CustomDebugStringConvertible {
    var debugDescription: String {
        "<PropertyType: \(description)>"
    }
}

extension PropertyType: CustomStringConvertible {
    var description: String {
        String(describing: rawValue)
    }
}

extension PropertyType: Equatable {
    static func == (lhs: RowViewBuilder.ID, rhs: RowViewBuilder.ID) -> Bool {
        lhs.id == rhs.id
    }
}

extension PropertyType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
