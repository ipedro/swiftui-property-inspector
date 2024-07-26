import Foundation
import SwiftUI

extension View {
    func setPreference<K: PreferenceKey>(_ key: K.Type, value: K.Value) -> some View {
        modifier(PreferenceWriter<K>(value: value))
    }

    func setPreference<K: PreferenceKey, D, C: View>(_ key: K.Type, @ViewBuilder body: @escaping (D) -> C) -> some View where K.Value == RowViewBuilderRegistry {
        let builder = RowViewBuilder(body: body)
        return modifier(
            PreferenceWriter<K>(value: RowViewBuilderRegistry(builder))
        )
    }
}

struct PreferenceWriter<K: PreferenceKey>: ViewModifier {
    let value: K.Value

    func body(content: Content) -> some View {
        content.background(
            Spacer().preference(key: K.self, value: value)
        )
    }
}
