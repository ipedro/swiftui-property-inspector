import Foundation
import SwiftUI

struct PropertyPreferenceKey: PreferenceKey {
    static var defaultValue = [PropertyType: Set<Property>]()
    static func reduce(value: inout [PropertyType: Set<Property>], nextValue: () -> [PropertyType: Set<Property>]) {
        value.merge(nextValue()) { lhs, rhs in
            lhs.union(rhs)
        }
    }
}

struct TitlePreferenceKey: PreferenceKey {
    static let defaultValue = LocalizedStringKey("Properties")
    static func reduce(value: inout LocalizedStringKey, nextValue: () -> LocalizedStringKey) {}
}

struct RowDetailPreferenceKey: PreferenceKey {
    static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}

struct RowIconPreferenceKey: PreferenceKey {
    static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}

struct RowLabelPreferenceKey: PreferenceKey {
    static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}
