import Foundation
import SwiftUI

struct PropertyInspectorRow<Icon: View, Label: View, Detail: View>: View, Equatable {
    static func == (lhs: PropertyInspectorRow<Icon, Label, Detail>, rhs: PropertyInspectorRow<Icon, Label, Detail>) -> Bool {
        lhs.id == rhs.id
    }

    var id: Int
    @Binding
    var isOn: Bool
    var hideIcon: Bool
    var icon: Icon
    var label: Label
    var detail: Detail

    @Environment(\.rowLabelFont)
    private var labelFont

    @Environment(\.rowDetailFont)
    private var detailFont

    var body: some View {
        #if VERBOSE
            PropertyInspectorRow._printChanges()
        #endif
        return Toggle(isOn: $isOn, label: content).toggleStyle(
            PropertyToggleStyle()
        )
        .foregroundStyle(.secondary)
        .padding(.vertical, 1)
        .listRowBackground(
            isOn ? Color(uiColor: .tertiarySystemBackground) : .clear
        )
    }

    private func content() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label.foregroundStyle(.primary)
            detail.font(detailFont)
        }
        .allowsTightening(true)
        .multilineTextAlignment(.leading)
        .contentShape(Rectangle())
        .safeAreaInset(edge: .leading, alignment: .firstTextBaseline) {
            if !hideIcon {
                icon.scaledToFit().frame(width: 25)
            }
        }
        .font(labelFont)
    }
}

#Preview {
    PropertyInspectorRow(
        id: 0,
        isOn: .constant(true),
        hideIcon: false,
        icon: Image(systemName: "circle"),
        label: Text(verbatim: "Some text"),
        detail: Text(verbatim: "Some detail")
    )
}

#Preview {
    PropertyInspectorRow(
        id: 0,
        isOn: .constant(true),
        hideIcon: true,
        icon: Image(systemName: "circle"),
        label: Text(verbatim: "Some text"),
        detail: Text(verbatim: "Some detail")
    )
}
