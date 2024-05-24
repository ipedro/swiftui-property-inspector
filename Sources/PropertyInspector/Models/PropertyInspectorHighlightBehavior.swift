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
