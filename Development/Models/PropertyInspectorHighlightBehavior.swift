import SwiftUI

/// An enumeration that defines the behavior of property highlights in the PropertyInspector.
///
/// `PropertyInspectorHighlightBehavior` controls how properties are highlighted when the
/// PropertyInspector is presented and dismissed.
public enum PropertyInspectorHighlightBehavior: String, CaseIterable {
    /// Highlights must be manually managed by the user.
    ///
    /// When using `manual`, any active highlights will remain active even after the inspector is dismissed.
    /// This option gives you full control over the highlighting behavior.
    case manual

    /// Highlights are shown automatically when the inspector is presented and hidden when it is dismissed.
    ///
    /// When using `automatic`, all visible views that contain inspectable properties are highlighted
    /// automatically when the inspector is presented. Any active highlights are hidden automatically
    /// upon dismissal of the inspector.
    case automatic

    /// Highlights are hidden automatically upon dismissal of the inspector.
    ///
    /// When using `hideOnDismiss`, any active highlights are hidden when the inspector is dismissed.
    /// This option ensures that highlights are automatically cleaned up when the inspector is no longer in view.
    case hideOnDismiss

    var label: LocalizedStringKey {
        switch self {
        case .manual:
            "Manual"
        case .automatic:
            "Show / Hide Automatically"
        case .hideOnDismiss:
            "Hide Automatically"
        }
    }
}
