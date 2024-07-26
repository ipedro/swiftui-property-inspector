import Foundation
import SwiftUI

struct RowViewBuilder: Hashable, Identifiable {
    let id: PropertyType
    let body: (Property) -> AnyView?

    init<D, C: View>(@ViewBuilder body: @escaping (_ data: D) -> C) {
        id = ID(D.self)
        self.body = { property in
            guard let castedValue = property.value.rawValue as? D else {
                return nil
            }
            return AnyView(body(castedValue))
        }
    }

    static func == (lhs: RowViewBuilder, rhs: RowViewBuilder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
