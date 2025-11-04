import Foundation
import SwiftUI

struct PropertyPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue = [PropertyType: Set<Property>]()
    static func reduce(value: inout [PropertyType: Set<Property>], nextValue: () -> [PropertyType: Set<Property>]) {
        value.merge(nextValue()) { lhs, rhs in
            lhs.union(rhs)
        }
    }
}

struct TitlePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = LocalizedStringKey("Properties")
    static func reduce(value _: inout LocalizedStringKey, nextValue _: () -> LocalizedStringKey) {}
}

struct RowDetailPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}

struct RowIconPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}

struct RowLabelPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}
