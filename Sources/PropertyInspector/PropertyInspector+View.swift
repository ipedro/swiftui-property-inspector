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

import Foundation
import SwiftUI

public extension View {
    /// Inspects the view itself.
    func inspectSelf(
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        inspectProperty(self, function: function, line: line, file: file)
    }

     /**
     Adds a modifier for inspecting properties with dynamic debugging capabilities.

     This method allows developers to dynamically inspect values of properties within a SwiftUI view, useful for debugging and during development to ensure that view states are correctly managed.

     - Parameters:
       - values: A variadic list of properties whose values you want to inspect.
       - function: The function from which the inspector is called, generally used for debugging purposes. Defaults to the name of the calling function.
       - line: The line number in the source file from which the inspector is called, aiding in pinpointing where inspections are set. Defaults to the line number in the source file.
       - file: The name of the source file from which the inspector is called, useful for tracing the call in larger projects. Defaults to the filename.

     - Returns: A view modified to include property inspection capabilities, reflecting the current state of the provided properties.

     ## Usage Example

     ```swift
     Text("Current Count: \(count)").inspectProperty(count)
     ```

     This can be particularly useful when paired with logging or during step-by-step debugging to monitor how and when your view's state changes.

     - seeAlso: ``propertyInspectorHidden()`` and ``inspectSelf(function:line:file:)``
     */
    func inspectProperty(
        _ values: Any...,
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        modifier(
            PropertySelector(
                data: values,
                location: .init(
                    function: function,
                    file: file,
                    line: line
                )
            )
        )
    }

    /**
     Hides the view from property inspection.

     Use this method to unconditionally hide nodes from the property inspector, which can be useful in many ways.

     - Returns: A view that no longer shows its properties in the property inspector, effectively hiding them from debugging tools.

     ## Usage Example

     ```swift
     Text("Hello, World!").propertyInspectorHidden()
     ```

     This method can be used to safeguard sensitive information or simply to clean up the debugging output for views that no longer need inspection.

     - seeAlso: ``inspectProperty(_:function:line:file:)``
     */
    func propertyInspectorHidden() -> some View {
        environment(\.propertyInspectorHidden, true)
    }

    /**
     Applies a modifier to inspect properties with custom icons based on their data type.

     This method allows you to define custom icons for different data types displayed in the property inspector, enhancing the visual differentiation and user experience.

     - Parameter data: The type of data for which the icon is defined.
     - Parameter icon: A closure that returns the icon to use for the given data type.

     - Returns: A modified view with the custom icon configuration applied to relevant properties.

     ## Usage Example

     ```swift
     Text("Example Property")
         .propertyInspectorRowIcon(for: String.self) { _ in
             Image(systemName: "text.quote")
         }
     ```

     - seeAlso: ``propertyInspectorRowLabel(for:label:)``, ``propertyInspectorRowDetail(for:detail:)``
     */
    func propertyInspectorRowIcon<D, Icon: View>(
        for data: D.Type = Any.self,
        @ViewBuilder icon: @escaping (_ data: D) -> Icon
    ) -> some View {
        setPreference(RowIconPreferenceKey.self, body: icon)
    }

    /**
     Defines a label for properties based on their data type within the property inspector.

     Use this method to provide custom labels for different data types, which can help in categorizing and identifying properties more clearly in the UI.

     - Parameter data: The type of data for which the label is defined.
     - Parameter label: A closure that returns the label to use for the given data type.

     - Returns: A modified view with the custom label configuration applied to relevant properties.

     ## Usage Example

     ```swift
     Text("Example Property")
         .propertyInspectorRowLabel(for: Int.self) { value in
             Text("Integer: \(value)")
         }
     ```

     - seeAlso: ``propertyInspectorRowIcon(for:icon:)``, ``propertyInspectorRowDetail(for:detail:)``
     */
    func propertyInspectorRowLabel<D, Label: View>(
        for data: D.Type = Any.self,
        @ViewBuilder label: @escaping (_ data: D) -> Label
    ) -> some View {
        setPreference(RowLabelPreferenceKey.self, body: label)
    }

    /**
     Specifies detail views for properties based on their data type within the property inspector.

     This method enables the display of detailed information for properties, tailored to the specific needs of the data type.

     - Parameter data: The type of data for which the detail view is defined.
     - Parameter detail: A closure that returns the detail view for the given data type.

     - Returns: A modified view with the detail view configuration applied to relevant properties.

     ## Usage Example

     ```swift
     Text("Example Property")
         .propertyInspectorRowDetail(for: Date.self) { date in
             Text("Date: \(date, formatter: dateFormatter)")
         }
     ```

     - seeAlso: ``propertyInspectorRowIcon(for:icon:)``, ``propertyInspectorRowLabel(for:label:)``
     */
    func propertyInspectorRowDetail<D, Detail: View>(
        for data: D.Type = Any.self,
        @ViewBuilder detail: @escaping (_ data: D) -> Detail
    ) -> some View {
        setPreference(RowDetailPreferenceKey.self, body: detail)
    }
}
