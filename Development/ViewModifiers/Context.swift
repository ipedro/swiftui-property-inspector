import Foundation
import SwiftUI

struct Context: ViewModifier {
    @StateObject
    private var data = Data()

    func body(content: Content) -> some View {
        content.onPreferenceChange(PropertyPreferenceKey.self) { newValue in
            if data.allObjects != newValue {
                data.allObjects = newValue
            }
        }.onPreferenceChange(RowDetailPreferenceKey.self) { newValue in
            if data.detailRegistry != newValue {
                data.detailRegistry = newValue
            }
        }.onPreferenceChange(RowIconPreferenceKey.self) { newValue in
            if data.iconRegistry != newValue {
                data.iconRegistry = newValue
            }
        }.onPreferenceChange(RowLabelPreferenceKey.self) { newValue in
            if data.labelRegistry != newValue {
                data.labelRegistry = newValue
            }
        }.environmentObject(data)
    }
}
