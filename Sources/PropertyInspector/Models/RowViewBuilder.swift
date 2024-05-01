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

struct RowViewBuilder: Hashable, Identifiable {
    struct ID: Hashable {
        let typeID: ObjectIdentifier
        let type: Any.Type

        init<D>(_ data: D.Type = D.self) {
            self.typeID = ObjectIdentifier(data)
            self.type = data
        }

        static func == (lhs: RowViewBuilder.ID, rhs: RowViewBuilder.ID) -> Bool {
            lhs.typeID == rhs.typeID
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(typeID)
        }
    }

    let id: ID
    let body: (Property) -> AnyView?

    init<D, C: View>(@ViewBuilder body: @escaping (D) -> C) {
        self.id = ID(D.self)
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