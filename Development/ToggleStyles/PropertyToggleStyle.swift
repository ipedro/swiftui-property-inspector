import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PropertyToggleStyle: ToggleStyle {
    var alignment: VerticalAlignment = .center

    var symbolFont: Font = .title

    var symbolName: (_ isOn: Bool) -> String = { isOn in
        if isOn {
            "eye.circle.fill"
        } else {
            "eye.slash.circle.fill"
        }
    }

    #if canImport(UIKit)
    private let feedback = UISelectionFeedbackGenerator()
    #endif

    func makeBody(configuration: Configuration) -> some View {
        Button {
            #if canImport(UIKit)
            feedback.selectionChanged()
            #endif
            withAnimation(.inspectorDefault) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(alignment: alignment) {
                configuration.label
                Spacer()
                Image(systemName: symbolName(configuration.isOn))
                    .font(symbolFont)
                    .ios17_interpolateSymbolEffect()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .secondary)
            }
        }
    }
}
