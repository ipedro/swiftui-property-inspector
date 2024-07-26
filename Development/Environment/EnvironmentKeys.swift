import Foundation
import SwiftUI

struct ViewInspectabilityKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

struct RowDetailFontKey: EnvironmentKey {
    static let defaultValue: Font = .caption
}

struct RowLabelFontKey: EnvironmentKey {
    static let defaultValue: Font = .callout
}

extension EnvironmentValues {
    var rowDetailFont: Font {
        get { self[RowDetailFontKey.self] }
        set { self[RowDetailFontKey.self] = newValue }
    }

    var rowLabelFont: Font {
        get { self[RowLabelFontKey.self] }
        set { self[RowLabelFontKey.self] = newValue }
    }

    var isInspectable: Bool {
        get { self[ViewInspectabilityKey.self] }
        set { self[ViewInspectabilityKey.self] = newValue }
    }
}
