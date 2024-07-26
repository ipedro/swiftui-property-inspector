import Foundation

/// `PropertyLocation` provides detailed information about the source location of a property within the code.
/// This includes the function, file, and line number where the property is used or modified, which is particularly useful for debugging and logging purposes.
final class PropertyLocation: Identifiable, Comparable, CustomStringConvertible {
    /// A unique identifier for the location, composed of the file path, line number, and function name.
    let id: String

    /// The name of the function where the location is recorded.
    let function: String

    /// The full path of the file where the location is recorded.
    let file: String

    /// The line number in the file where the location is recorded.
    let line: Int

    /// A human-readable description of the location, typically formatted as "filename:line".
    let description: String

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
    static func < (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
    }

    /// Determines if two `PropertyLocation` instances are equal based on their identifiers.
    /// - Returns: `true` if both locations have the same identifier, otherwise `false`.
    static func == (lhs: PropertyLocation, rhs: PropertyLocation) -> Bool {
        lhs.id == rhs.id
    }
}
