import Foundation
import SwiftUI

// MARK: - Inline Style

/**
 `_InlinePropertyInspector` provides a SwiftUI view modifier that applies an inline-style presentation to property inspectors.

 This style integrates property listings directly within the surrounding content, using a minimalistic approach suitable for inline detail presentation.

 - Parameters:
   - title: An optional title for the inline presentation; if not provided, defaults to `nil`.
   - listRowBackground: The view used as the background for each row, conforming to `View`. Typically a `Color` or transparent effects are used to blend seamlessly with the surrounding content.
   - contentPadding: A Boolean value that indicates whether the content should have padding. Defaults to `true`.

 - Returns: A view modifier that configures the appearance and behavior of a property inspector using the specified inline style.

 ## Usage

 `_InlinePropertyInspector` should be used when you want to integrate property details directly within your UI without a distinct separation. Here's how to configure it:

 ```swift
 var body: some View {
     PropertyInspector(
         "Optional Title",
         listRowBackground: nil, // optional
         label: {
             // Inline content, typically detailed views or forms
             MyDetailView()
         }
     )
 }
 ```

 ## Performance Considerations

 Since ``_InlinePropertyInspector`` is designed for minimalistic integration, it generally has low impact on performance.

 - seeAlso: ``_SheetPropertyInspector`` and ``_ListPropertyInspector``.
 */
public struct _InlinePropertyInspector: _PropertyInspectorStyle {
    public func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            LazyVStack(alignment: .leading, spacing: 15) {
                PropertyInspectorRows()
            }
            .padding()
        }
    }
}
