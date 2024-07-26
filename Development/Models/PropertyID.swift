import Foundation

final class PropertyID {
    private let _uuid = UUID()

    /// The location of the property within the source code, provided for better traceability and debugging.
    let location: PropertyLocation

    let createdAt: Date

    /// A computed string that provides a sortable representation of the property based on its location and offset.
    private let sortString: String

    init(
        offset: Int,
        createdAt: Date,
        location: PropertyLocation
    ) {
        self.location = location
        self.createdAt = createdAt
        sortString = [
            location.id,
            String(createdAt.timeIntervalSince1970),
            String(offset)
        ].joined(separator: "_")
    }
}

extension PropertyID: Hashable {
    /// Compares two `Property` instances for equality, considering both their unique identifiers and highlight states.
    static func == (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs._uuid == rhs._uuid
    }

    /// Contributes to the hashability of the property, incorporating its unique identifier into the hash.
    func hash(into hasher: inout Hasher) {
        hasher.combine(_uuid)
    }
}

extension PropertyID: Comparable {
    /// Determines if one `ID` should precede another in a sorted list, based on a composite string that includes their location and value.
    static func < (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }
}
