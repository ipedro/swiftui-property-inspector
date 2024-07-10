import Foundation
import SwiftUI

// MARK: - List Style

/**
 `_ListPropertyInspector` provides a SwiftUI view modifier that applies a list-style presentation to property inspectors.

 This style organizes properties into a list, using specified list styles and row backgrounds, suitable for inspections within a non-modal, integrated list environment.

 - Parameters:
   - `listStyle`: The style of the list, conforming to `ListStyle`. Typical styles include `.plain`, `.grouped`, and `.insetGrouped`, depending on the desired visual effect.
   - `listRowBackground`: The view used as the background for each row in the list, conforming to `View`. This could be a simple `Color` or more complex custom views.
   - `title`: An optional title for the list; if not provided, defaults to `nil`.
   - `contentPadding`: A Boolean value that indicates whether the content should have padding. Defaults to `false`.

 - Returns: A view modifier that configures the appearance and behavior of a property inspector using the specified list style.

 ## Usage

 You don't instantiate `_ListPropertyInspector` directly. Instead, use it when initializing your ``PropertyInspector`` to apply a list-style layout. Here's an example configuration:

 ```swift
 var body: some View {
     PropertyInspector(
         "Optional Title",
         listStyle: .plain, // optonal
         label: {
             // Your view components here
             MyListView()
         }
     )
 }
 ```
 ## Performance Considerations

 Utilizing complex views as `listRowBackground` may impact performance, especially with very long lists.

 - seeAlso: ``_SheetPropertyInspector`` and ``_InlinePropertyInspector``
*/
public struct _ListPropertyInspector<Style: ListStyle, RowBackground: View>: _PropertyInspectorStyle {
    var title: LocalizedStringKey?
    var listStyle: Style
    var listRowBackground: RowBackground?
    var contentPadding: Bool

    @EnvironmentObject
    private var context: Context.Data

    private var emptyMessage: String {
        context.searchQuery.isEmpty ?
        "Empty" :
        "No results for '\(context.searchQuery)'"
    }

    public func body(content: Content) -> some View {
        List {
            Section {
                PropertyInspectorRows().listRowBackground(listRowBackground)
            } header: {
                VStack(spacing: .zero) {
                    content
                        .environment(\.textCase, nil)
                        .environment(\.font, nil)
                        .padding(contentPadding ? .vertical : [])
                        .padding(contentPadding ? .vertical : [])

                    Header(data: title)
                }
                .frame(maxWidth: .infinity)
            }

            if context.properties.isEmpty {
                Text(emptyMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowSeparatorTint(.clear)
                    .multilineTextAlignment(.center)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 150
                    )
            }

        }
        .listStyle(listStyle)
        .blendMode(context.properties.isEmpty ? .multiply : .normal)
    }
}
