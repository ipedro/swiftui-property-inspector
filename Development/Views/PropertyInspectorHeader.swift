import SwiftUI

struct PropertyInspectorHeader: View {
    var data: LocalizedStringKey

    init?(data: LocalizedStringKey?) {
        guard let data else { return nil }
        self.data = data
    }

    @EnvironmentObject
    private var context: Context.Data

    var body: some View {
        VStack(spacing: 4) {
            title()
            let filters = context.filters.sorted()

            if !filters.isEmpty {
                PropertyInspectorFilters(
                    data: filters,
                    toggleAll: context.toggleAllFilters,
                    title: \.wrappedValue.description,
                    isOn: context.toggleFilter(_:)
                )
            }
        }
        .multilineTextAlignment(.leading)
        .environment(\.textCase, nil)
        .foregroundStyle(.primary)
    }

    private var accessoryTitle: String {
        if context.properties.isEmpty {
            return ""
        }
        let count = context.properties.count
        let allCount = context.allProperties.count
        if count != allCount {
            return "\(count) of \(allCount) items"
        }
        return "\(count) items"
    }

    @ViewBuilder
    private func title() -> some View {
        let formattedText = Text(data)
            .font(.title.weight(.medium))
            .lineLimit(1)

        if #available(iOS 16.0, *), !context.properties.isEmpty {
            Toggle(sources: context.properties, isOn: \.$isHighlighted) {
                HStack(alignment: .firstTextBaseline) {
                    formattedText

                    Text(accessoryTitle)
                        .contentTransition(.numericText())
                        .font(.footnote.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .foregroundStyle(.secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(.ultraThickMaterial)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(
                PropertyToggleStyle(
                    alignment: .firstTextBaseline,
                    symbolName: { _ in
                        "arrow.triangle.2.circlepath.circle.fill"
                    }
                )
            )
        } else {
            formattedText.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
