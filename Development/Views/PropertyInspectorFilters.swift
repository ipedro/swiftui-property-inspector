import SwiftUI

struct PropertyInspectorFilters<Filter>: View where Filter: Hashable {
    var data: [Filter]
    
    @Binding

    var toggleAll: Bool

    var title: KeyPath<Filter, String>

    var isOn: (_ data: Filter) -> Binding<Bool>

    @EnvironmentObject
    private var context: Context.Data
    
    var body: some View {
        HStack(spacing: .zero) {
            toggleAllButton
            filterList
        }
        .font(.caption.bold())
        .toggleStyle(.button)
        .controlSize(.mini)
        .tint(.secondary)
        .padding(.vertical, 5)
    }

    private var toggleAllicon: String {
        "line.3.horizontal.decrease\(toggleAll ? ".circle.fill" : "")"
    }

    private var toggleAllAccessibilityLabel: Text {
        Text(toggleAll ? "Deselect All Filters" : "Select All Filters")
    }

    private var toggleAllButton: some View {
        Toggle(
            isOn: $toggleAll,
            label: {
                ZStack {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.title2)
                        .opacity(toggleAll ? 1 : 0)
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.subheadline)
                        .padding(.top, 1)
                        .opacity(toggleAll ? 0 : 1)
                }
                .accessibilityElement()
                .accessibilityLabel(toggleAllAccessibilityLabel)
            }
        )
        .buttonStyle(.plain)
        .tint(.primary)
        .symbolRenderingMode(.hierarchical)
    }

    private var filterList: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(data, id: \.self) { element in
                    Toggle(element[keyPath: title], isOn: isOn(element))
                }
            }
            .padding(
                EdgeInsets(
                    top: 2,
                    leading: 10,
                    bottom: 2,
                    trailing: 0
                )
            )

            .fixedSize(horizontal: false, vertical: true)
            .padding(.trailing, 20)
        }
        .mask({
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .leading,
                endPoint: .init(x: 0.04, y: 0.5)
            )
        })
        .padding(.trailing, -20)
        .animation(.inspectorDefault, value: data)
        .ios16_hideScrollIndicators()
    }
}

#Preview {
    FilterDemo()
}

private struct FilterDemo: View {
    @State var toggleAll = false
    var body: some View {
        PropertyInspectorFilters(
            data: ["test1", "test2", "test3", "test4"],
            toggleAll: $toggleAll,
            title: \.self,
            isOn: { _ in $toggleAll }
        )
    }
}
