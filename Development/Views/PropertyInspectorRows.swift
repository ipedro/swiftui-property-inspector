import SwiftUI

struct PropertyInspectorRows: View {
    @EnvironmentObject
    private var context: Context.Data

    var body: some View {
        #if VERBOSE
        printChanges()
        #endif
        if context.properties.isEmpty {
            Text(emptyMessage)
                .foregroundStyle(.tertiary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .multilineTextAlignment(.center)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 50,
                    alignment: .bottom
                )
                .padding()
        }
        ForEach(context.properties) { property in
            PropertyInspectorRow(
                id: property.hashValue,
                isOn: property.$isHighlighted,
                hideIcon: context.iconRegistry.isEmpty,
                icon: icon(for: property),
                label: label(for: property),
                detail: detail(for: property)
            )
            .equatable()
        }
    }

    #if VERBOSE
    private func printChanges() -> EmptyView {
        Self._printChanges()
        return EmptyView()
    }
    #endif

    private var emptyMessage: String {
        context.searchQuery.isEmpty ?
            "Nothing to inspect" :
            "No results for '\(context.searchQuery)'"
    }

    @ViewBuilder
    private func icon(for property: Property) -> some View {
        if let icon = context.iconRegistry.makeBody(property: property) {
            icon
        } else if !context.iconRegistry.isEmpty {
            Image(systemName: "info.circle.fill")
        }
    }

    @ViewBuilder
    private func label(for property: Property) -> some View {
        if let label = context.labelRegistry.makeBody(property: property) {
            label
        } else {
            Text(verbatim: property.stringValue)
        }
    }

    @ViewBuilder
    private func detail(for property: Property) -> some View {
        VStack(alignment: .leading) {
            context.detailRegistry.makeBody(property: property)
            Text(verbatim: property.id.location.description).opacity(2 / 3)
        }
    }
}
