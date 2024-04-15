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

/// `PropertyLocation` provides detailed information about the source location of a property within the code.
/// This includes the function, file, and line number where the property is used or modified, which is particularly useful for debugging and logging purposes.
public struct PropertyLocation: Identifiable, Comparable, CustomStringConvertible {
    /// A unique identifier for the location, composed of the file path, line number, and function name.
    public let id: String

    /// The name of the function where the location is recorded.
    public let function: String

    /// The full path of the file where the location is recorded.
    public let file: String

    /// The line number in the file where the location is recorded.
    public let line: Int

    /// A human-readable description of the location, typically formatted as "filename:line".
    public let description: String

    /// Initializes a new `PropertyLocation` with the specified source code location details.
    /// - Parameters:
    ///   - function: The name of the function encapsulating the location.
    ///   - file: The full path of the source file.
    ///   - line: The line number in the source file.
    init(function: String, file: String, line: Int) {
        let fileName = URL(string: file)?.lastPathComponent ?? file

        self.id = "\(file):\(line):\(function)"
        self.description = "\(fileName):\(line)"
        self.function = function
        self.file = file
        self.line = line
    }

    /// Compares two `PropertyLocation` instances for ascending order based on their `id`.
    /// - Returns: `true` if the identifier of the first location is less than the second, otherwise `false`.
    public static func < (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
    }

    /// Determines if two `PropertyLocation` instances are equal based on their identifiers.
    /// - Returns: `true` if both locations have the same identifier, otherwise `false`.
    public static func == (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id == rhs.id
    }
}
