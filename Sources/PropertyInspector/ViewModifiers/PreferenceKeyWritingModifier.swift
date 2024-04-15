//  Copyright (c) 2024 Pedro Almeida
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import SwiftUI

extension View {
    func setPreference<K: PreferenceKey>(_ key: K.Type, value: K.Value) -> some View {
        modifier(PreferenceKeyWritingModifier<K>(value: value))
    }

    func setPreference<K: PreferenceKey, D, C: View>(_ key: K.Type, @ViewBuilder body: @escaping (D) -> C) -> some View where K.Value == ViewBuilderRegistry {
        let id = ObjectIdentifier(D.self)

        let body = ViewBuilderRegistry.ViewBuilder(id: id) { value in
            if let castedValue = value as? D {
                return AnyView(body(castedValue))
            }
            return nil
        }

        return modifier(PreferenceKeyWritingModifier<K>(value: ViewBuilderRegistry([id: body])))
    }
}

struct PreferenceKeyWritingModifier<K: PreferenceKey>: ViewModifier {
    let value: K.Value

    func body(content: Content) -> some View {
        content.background(
            Spacer().preference(key: K.self, value: value)
        )
    }
}
