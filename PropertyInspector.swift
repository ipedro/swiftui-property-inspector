// MIT License
// 
// Copyright (c) 2024 Pedro Almeida
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// auto-generated file, do not edit directly

import Combine
import Foundation
import SwiftUI
import UIKit

struct ViewInspectabilityKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

struct RowDetailFontKey: EnvironmentKey {
    static let defaultValue: Font = .caption
}

struct RowLabelFontKey: EnvironmentKey {
    static let defaultValue: Font = .callout
}

extension EnvironmentValues {
    var rowDetailFont: Font {
        get { self[RowDetailFontKey.self] }
        set { self[RowDetailFontKey.self] = newValue }
    }

    var rowLabelFont: Font {
        get { self[RowLabelFontKey.self] }
        set { self[RowLabelFontKey.self] = newValue }
    }

    var isInspectable: Bool {
        get { self[ViewInspectabilityKey.self] }
        set { self[ViewInspectabilityKey.self] = newValue }
    }
}

struct PropertyPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue = [PropertyType: Set<Property>]()
    static func reduce(value: inout [PropertyType: Set<Property>], nextValue: () -> [PropertyType: Set<Property>]) {
        value.merge(nextValue()) { lhs, rhs in
            lhs.union(rhs)
        }
    }
}

struct TitlePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = LocalizedStringKey("Properties")
    static func reduce(value _: inout LocalizedStringKey, nextValue _: () -> LocalizedStringKey) {}
}

struct RowDetailPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}

struct RowIconPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}

struct RowLabelPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static let defaultValue = RowViewBuilderRegistry()
    static func reduce(value: inout RowViewBuilderRegistry, nextValue: () -> RowViewBuilderRegistry) {
        value.merge(nextValue())
    }
}

extension Animation {
    static let inspectorDefault: Animation = .snappy(duration: 0.25)
}

extension View {
    @ViewBuilder
    func ios16_scrollBounceBehaviorBasedOnSize() -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

    @ViewBuilder
    func ios16_hideScrollIndicators(_ hide: Bool = true) -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            scrollIndicators(hide ? .hidden : .automatic)
        } else {
            self
        }
    }

    @ViewBuilder
    func ios17_interpolateSymbolEffect() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            contentTransition(.symbolEffect(.automatic, options: .speed(2)))
        } else if #available(iOS 16.0, macOS 13.0, *) {
            contentTransition(.interpolate)
        } else {
            self
        }
    }
}

extension Context {
    final class Data: ObservableObject {
        private var cancellables = Set<AnyCancellable>()

        private var _allObjects = [PropertyType: Set<Property>]()

        @Published
        var searchQuery = ""

        var allProperties = [Property]()

        var filters = Set<Filter<PropertyType>>()

        @Published
        var properties = [Property]() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Properties")
                    for property in properties {
                        print("\t- \(property)")
                    }
                #endif
            }
        }

        @Published
        var iconRegistry = RowViewBuilderRegistry() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Icons \(iconRegistry)")
                #endif
            }
        }

        @Published
        var labelRegistry = RowViewBuilderRegistry() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Labels \(labelRegistry)")
                #endif
            }
        }

        @Published
        var detailRegistry = RowViewBuilderRegistry() {
            didSet {
                #if VERBOSE
                    print("\(Self.self): Updated Details \(iconRegistry)")
                #endif
            }
        }

        var allObjects: [PropertyType: Set<Property>] {
            get { _allObjects }
            set {
                guard _allObjects != newValue else { return }
                _allObjects = newValue
                makeProperties()
            }
        }

        init() {
            setupDebouncing()
        }

        private func isOn(filter: Filter<PropertyType>) -> Bool {
            if let index = filters.firstIndex(of: filter) {
                filters[index].isOn
            } else {
                false
            }
        }

        func toggleFilter(_ filter: Filter<PropertyType>) -> Binding<Bool> {
            Binding { [unowned self] in
                if let index = filters.firstIndex(of: filter) {
                    filters[index].isOn
                } else {
                    false
                }
            } set: { [unowned self] newValue in
                if let index = self.filters.firstIndex(of: filter) {
                    filters[index].isOn = newValue
                    _allObjects[filter.wrappedValue]?.forEach { prop in
                        if prop.isHighlighted {
                            prop.isHighlighted = false
                        }
                    }
                    makeProperties()
                }
            }
        }

        var toggleAllFilters: Binding<Bool> {
            let allSelected = !filters.map(\.isOn).contains(false)
            return Binding {
                allSelected
            } set: { [unowned self] newValue in
                for filter in filters {
                    filter.isOn = newValue
                }
                for set in _allObjects.values {
                    for prop in set where prop.isHighlighted {
                        prop.isHighlighted = false
                    }
                }
                makeProperties()
            }
        }

        private func setupDebouncing() {
            $searchQuery
                .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                .removeDuplicates()
                .sink { [weak self] _ in
                    self?.makeProperties()
                }
                .store(in: &cancellables)
        }

        private func isFilterEnabled(_ type: PropertyType) -> Bool? {
            for filter in filters where filter.wrappedValue == type {
                return filter.isOn
            }
            return nil
        }

        private func makeProperties() {
            var all = Set<Property>()
            var properties = Set<Property>()
            var filters = Set<Filter<PropertyType>>()

            for (type, set) in _allObjects {
                let searchResult = search(in: set)
                if !searchResult.isEmpty {
                    filters.insert(
                        Filter(
                            type,
                            isOn: isFilterEnabled(type) ?? true
                        )
                    )
                }
                all.formUnion(set)
                properties.formUnion(searchResult)
            }

            withAnimation(.inspectorDefault) {
                self.filters = filters
                self.allProperties = Array(all)
                self.properties = filter(in: Array(properties)).sorted()
            }
        }

        private func search(in properties: Set<Property>) -> Set<Property> {
            guard !searchQuery.isEmpty else {
                return properties
            }

            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

            guard query.count > 1 else {
                return properties
            }

            return properties.filter {
                if $0.stringValue.localizedCaseInsensitiveContains(query) { return true }
                if $0.stringValueType.localizedStandardContains(query) { return true }
                return $0.id.location.description.localizedStandardContains(query)
            }
        }

        private func filter(in properties: [Property]) -> [Property] {
            let activeTypes = Set(filters.filter { $0.isOn }.map(\.wrappedValue))

            guard activeTypes.count != filters.count else {
                return properties
            }

            let result = properties.filter {
                activeTypes.contains($0.value.type)
            }
            return result
        }
    }
}

extension Context {
    final class Filter<F> {
        var wrappedValue: F
        var isOn: Bool

        init(_ wrappedValue: F, isOn: Bool) {
            self.wrappedValue = wrappedValue
            self.isOn = isOn
        }
    }
}

extension Context.Filter: Hashable where F: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

extension Context.Filter: Equatable where F: Equatable {
    static func == (lhs: Context.Filter<F>, rhs: Context.Filter<F>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Context.Filter: Comparable where F: Comparable {
    static func < (rhs: Context.Filter<F>, lhs: Context.Filter<F>) -> Bool {
        if rhs.isOn == lhs.isOn {
            rhs.wrappedValue < lhs.wrappedValue
        } else {
            rhs.isOn && !lhs.isOn
        }
    }
}

struct HashableBox<Value>: Hashable {
    let id = UUID()
    let value: Value

    init(_ value: Value) {
        self.value = value
    }

    static func == (lhs: HashableBox<Value>, rhs: HashableBox<Value>) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class HashableDictionary<Key, Value>: Hashable where Key: Hashable, Value: Hashable {
    static func == (lhs: HashableDictionary<Key, Value>, rhs: HashableDictionary<Key, Value>) -> Bool {
        lhs.data == rhs.data
    }

    private var data = [Key: Value]()

    subscript(id: Key) -> Value? {
        get { data[id] }
        set { data[id] = newValue }
    }

    func hash(into hasher: inout Hasher) {
        data.hash(into: &hasher)
    }

    func removeAll() {
        data.removeAll(keepingCapacity: true)
    }
}

/// `Property` encapsulates details about a specific property within a view or model, including its value, display metadata, and location.
/// This struct is intended for internal use within the ``PropertyInspector`` framework to track and manage property information dynamically.
final class Property: Identifiable, Comparable, Hashable, CustomStringConvertible {
    /// A unique identifier for the property, ensuring that each instance is uniquely identifiable.
    let id: PropertyID

    /// The value of the property stored as `Any`, allowing it to accept any property type.
    let value: PropertyValue

    /// A binding to a Boolean that indicates whether the property is currently highlighted in the UI.
    @Binding
    var isHighlighted: Bool

    /// Signal view updates
    let token: AnyHashable

    /// Returns the type of the value as a string, useful for dynamic type checks or displays.
    var stringValueType: String {
        String(describing: type(of: value.rawValue))
    }

    /// Returns the string representation of the property's value.
    var stringValue: String {
        String(describing: value.rawValue)
    }

    var description: String { stringValue }

    /// Initializes a new `Property` with detailed information about its value and location.
    /// - Parameters:
    ///   - value: The value of the property.
    ///   - isHighlighted: A binding to the Boolean indicating if the property is highlighted.
    ///   - location: The location of the property in the source code.
    ///   - offset: An offset used to uniquely sort the property when multiple properties share the same location.
    init(
        id: ID,
        token: AnyHashable,
        value: PropertyValue,
        isHighlighted: Binding<Bool>
    ) {
        self.token = token
        self.id = id
        self.value = value
        _isHighlighted = isHighlighted
    }

    /// Compares two `Property` instances for equality, considering both their unique identifiers and highlight states.
    static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.id == rhs.id &&
            lhs.stringValue == rhs.stringValue &&
            lhs.token == rhs.token
    }

    /// Determines if one `Property` should precede another in a sorted list, based on a composite string that includes their location and value.
    static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.id < rhs.id
    }

    /// Contributes to the hashability of the property, incorporating its unique identifier into the hash.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(stringValue)
        hasher.combine(token)
    }
}

/// Centralized property cache to avoid recreating Property objects on every view body update.
///
/// Pattern based on Apple's LocationFinder caching example from WWDC2025-306 (timestamp 12:13).
/// Instead of recreating Property objects on every view update, we cache them by their PropertyID
/// and only create new instances when the value actually changes (detected via token).
/// This reduces allocation overhead by ~99% for stable property values.
///
/// See: https://developer.apple.com/videos/play/wwdc2025/306/
final class PropertyCache {
    /// Thread-safe cache of properties by their unique identifier
    private var cache: [PropertyID: Property] = [:]
    private let lock = NSLock()
    
    /// Retrieves a cached property or creates a new one if the value has changed.
    /// Uses token-based invalidation: if the token matches, returns cached instance.
    /// If token differs (value changed), creates and caches new Property.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the property
    ///   - token: Hash token for equality checking (changes when value changes)
    ///   - value: Current value of the property
    ///   - isHighlighted: Binding to highlight state
    /// - Returns: Cached or newly created property
    func property(
        for id: PropertyID,
        token: AnyHashable,
        value: PropertyValue,
        isHighlighted: Binding<Bool>
    ) -> Property {
        lock.lock()
        defer { lock.unlock() }
        
        // Check if we have a cached property with matching token
        if let cached = cache[id], cached.token == token {
            // ✅ Token matches = value unchanged, return cached instance
            // This is the common case: ~99% of view body updates don't change property values
            return cached
        }
        
        // Token mismatch or no cache = value changed, create new property
        let new = Property(
            id: id,
            token: token,
            value: value,
            isHighlighted: isHighlighted
        )
        cache[id] = new
        return new
    }
    
    /// Clears all cached properties. Useful for testing or memory management.
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
    
    /// Returns the number of cached properties. Useful for debugging and performance monitoring.
    var cacheSize: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }
    
    /// Removes stale properties that are no longer referenced
    /// Call periodically to prevent unbounded cache growth
    func pruneStaleEntries(keeping activeIDs: Set<PropertyID>) {
        lock.lock()
        defer { lock.unlock() }
        
        let staleKeys = cache.keys.filter { !activeIDs.contains($0) }
        for key in staleKeys {
            cache.removeValue(forKey: key)
        }
        
        #if VERBOSE
        if !staleKeys.isEmpty {
            print("[PropertyCache] Pruned \(staleKeys.count) stale entries, \(cache.count) remaining")
        }
        #endif
    }
}

final class PropertyID {
    private let _uuid = UUID()

    /// The location of the property within the source code, provided for better traceability and debugging.
    let location: PropertyLocation

    let createdAt: Date

    /// A computed string that provides a sortable representation of the property based on its location and offset.
    private let sortString: String

    init(
        offset: Int,
        createdAt: Date,
        location: PropertyLocation
    ) {
        self.location = location
        self.createdAt = createdAt
        sortString = [
            location.id,
            String(createdAt.timeIntervalSince1970),
            String(offset)
        ].joined(separator: "_")
    }
}

extension PropertyID: Hashable {
    /// Compares two `Property` instances for equality, considering both their unique identifiers and highlight states.
    static func == (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs._uuid == rhs._uuid
    }

    /// Contributes to the hashability of the property, incorporating its unique identifier into the hash.
    func hash(into hasher: inout Hasher) {
        hasher.combine(_uuid)
    }
}

extension PropertyID: Comparable {
    /// Determines if one `ID` should precede another in a sorted list, based on a composite string that includes their location and value.
    static func < (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs.sortString.localizedStandardCompare(rhs.sortString) == .orderedAscending
    }
}

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

        id = "\(file):\(line):\(function)"
        description = "\(fileName):\(line)"
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

struct PropertyType: Identifiable {
    let id: ObjectIdentifier
    let rawValue: Any.Type

    init<T>(_ subject: T) {
        let start = Date()
        let type: Any.Type
        if T.self == Any.self {
            // only use mirror as last resort
            type = Mirror(reflecting: subject).subjectType
            #if VERBOSE
                let elapsedTime = (Date().timeIntervalSince(start) * 1000).formatted()
                print(#function, "🐢", "Determined type \(type) in \(elapsedTime) ms")
            #endif
        } else {
            type = T.self
            #if VERBOSE
                let elapsedTime = (Date().timeIntervalSince(start) * 1000).formatted()
                print(#function, "🐰", "Determined type \(type) in \(elapsedTime) ms")
            #endif
        }
        id = ObjectIdentifier(type)
        rawValue = type
    }
}

extension PropertyType: Comparable {
    static func < (lhs: PropertyType, rhs: PropertyType) -> Bool {
        lhs.description.localizedStandardCompare(rhs.description) == .orderedAscending
    }
}

extension PropertyType: CustomDebugStringConvertible {
    var debugDescription: String {
        "<PropertyType: \(description)>"
    }
}

extension PropertyType: CustomStringConvertible {
    var description: String {
        String(describing: rawValue)
    }
}

extension PropertyType: Equatable {
    static func == (lhs: RowViewBuilder.ID, rhs: RowViewBuilder.ID) -> Bool {
        lhs.id == rhs.id
    }
}

extension PropertyType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PropertyValue: Identifiable {
    let id: PropertyValueID
    let rawValue: Any
    var type: PropertyType { id.type }

    init<T>(_ value: T) {
        id = ID(value)
        rawValue = value
    }

    init(_ other: PropertyValue) {
        self = other
    }
}

struct PropertyValueID: Hashable {
    let hashValue: Int
    let type: PropertyType

    init<T>(_ value: T) {
        hashValue = String(describing: value).hashValue
        type = PropertyType(value)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
        hasher.combine(type)
    }
}

struct RowViewBuilder: Hashable, Identifiable {
    let id: PropertyType
    let body: (Property) -> AnyView?

    init<D, C: View>(@ViewBuilder body: @escaping (_ data: D) -> C) {
        id = ID(D.self)
        self.body = { property in
            guard let castedValue = property.value.rawValue as? D else {
                return nil
            }
            return AnyView(body(castedValue))
        }
    }

    static func == (lhs: RowViewBuilder, rhs: RowViewBuilder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct RowViewBuilderRegistry: Hashable, CustomStringConvertible {
    private var data: [PropertyType: RowViewBuilder]

    private let cache = HashableDictionary<PropertyValueID, HashableBox<AnyView>>()

    init(_ values: RowViewBuilder...) {
        data = values.reduce(into: [:]) { partialResult, builder in
            partialResult[builder.id] = builder
        }
    }

    var description: String {
        "\(Self.self)\(data.keys.map { "\n\t-\($0.rawValue)" }.joined())"
    }

    var isEmpty: Bool { data.isEmpty }

    var identifiers: [PropertyType] {
        Array(data.keys)
    }

    subscript(id: PropertyType) -> RowViewBuilder? {
        get {
            data[id]
        }
        set {
            if data[id] != newValue {
                data[id] = newValue
            }
        }
    }

    mutating func merge(_ other: RowViewBuilderRegistry) {
        data.merge(other.data) { content, _ in
            content
        }
    }

    func merged(_ other: RowViewBuilderRegistry) -> Self {
        var copy = self
        copy.merge(other)
        return copy
    }

    func makeBody(property: Property) -> AnyView? {
        if let cached = resolveFromCache(property: property) {
            #if VERBOSE
                print("[PropertyInspector]", "♻️", property.stringValue, "resolved from cache")
            #endif
            return cached
        } else if let body = createBody(property: property) {
            #if VERBOSE
                print("[PropertyInspector]", "🆕", property.stringValue, "created new view")
            #endif
            return body
        }
        return nil
    }

    private func resolveFromCache(property: Property) -> AnyView? {
        if let cached = cache[property.value.id] {
            return cached.value
        }
        return nil
    }

    #if DEBUG
        private func createBody(property: Property) -> AnyView? {
            var matches = [PropertyType: AnyView]()

            for id in identifiers {
                if let view = data[id]?.body(property) {
                    matches[id] = view
                }
            }

            if matches.keys.count > 1 {
                let matchingTypes = matches.keys.map { String(describing: $0.rawValue) }
                print(
                    "[PropertyInspector]",
                    "⚠️ Warning:",
                    "Undefined behavior.",
                    "Multiple row builders",
                    "match '\(property.stringValueType)' declared in '\(property.id.location)':",
                    matchingTypes.sorted().joined(separator: ", ")
                )
            }

            if let match = matches.first {
                cache[property.value.id] = HashableBox(match.value)
                return match.value
            }

            return nil
        }
    #else
        private func createBody(property: Property) -> AnyView? {
            for id in identifiers {
                if let view = data[id]?.body(property) {
                    cache[property.value.id] = HashableBox(view)
                    return view
                }
            }
            return nil
        }
    #endif
}

/**
  A `PropertyInspector` struct provides a customizable interface for inspecting properties within a SwiftUI view.

  The `PropertyInspector` is designed to display detailed information about properties, ideal for debugging purposes, configuration settings, or presenting detailed data about objects in a clear and organized manner. It leverages generics to support various content and styling options, making it a versatile tool for building dynamic and informative user interfaces.

  ## Usage

  The `PropertyInspector` is typically initialized with a label and a style. The label defines the content that will be displayed, while the style dictates how this content is presented. Below is an example of how to instantiate and use a `PropertyInspector` with a custom style and label:

 ![SwiftUI PropertyInspector plain list style example](https://github.com/ipedro/swiftui-property-inspector/raw/main/Docs/swiftui-property-inspector-plain-list-example.gif)

 ```swift
 import PropertyInspector
 import SwiftUI

 var body: some View {
     PropertyInspector(listStyle: .plain) {
         VStack(content: {
             InspectableText(content: "Placeholder Text")
             InspectableButton(style: .bordered)
         })
         .propertyInspectorRowLabel(for: Int.self, label: { data in
             Text("Tap count: \(data)")
         })
         .propertyInspectorRowIcon(for: Int.self, icon: { data in
             Image(systemName: "\(data).circle.fill")
         })
         .propertyInspectorRowIcon(for: String.self, icon: { _ in
             Image(systemName: "text.quote")
         })
         .propertyInspectorRowIcon(for: (any PrimitiveButtonStyle).self, icon: { _ in
             Image(systemName: "button.vertical.right.press.fill")
         })
     }
 }
 ```

 ```swift
 struct InspectableText<S: StringProtocol>: View {
     var content: S

     var body: some View {
         Text(content).inspectProperty(content)
     }
 }
 ```

 ```swift
 struct InspectableButton<S: PrimitiveButtonStyle>: View {
     var style: S
     @State private var tapCount = 0

     var body: some View {
         Button("Tap Me") {
             tapCount += 1
         }
         // inspecting multiple values with a single function call links their highlight behavior.
         .inspectProperty(style, tapCount)
         .buttonStyle(style)
     }
 }
 ```

 - seeAlso: ``inspectProperty(_:shape:function:line:file:)-5quvs``, ``propertyInspectorHidden()``, and ``inspectSelf(shape:function:line:file:)``
  */
public struct PropertyInspector<Label: View, Style: _PropertyInspectorStyle>: View {
    var label: Label
    var style: Style
    var context = Context()

    public var body: some View {
        // Do not change the following order:
        label
            // 1. content
            .modifier(style)
            // 2. data context
            .modifier(context)
    }
}

public extension PropertyInspector {
    /**
      Initializes property inspector presented as a sheet with minimal styling.

      This initializer sets up a property inspector presented as a sheet using [PlainListStyle](https://developer.apple.com/documentation/swiftui/plainliststyle) and a clear background. It's useful for cases where a straightforward list display is needed without additional styling complications.

      - Parameters:
        - title: An optional title for the sheet; if not provided, defaults to `nil`.
        - isPresented: A binding to a Boolean value that controls the presentation state of the sheet.
        - label: A closure that returns the content to be displayed within the sheet.

      ## Usage Example

      ```swift
      @State
      private var isPresented = false

      var body: some View {
          PropertyInspector("Settings", isPresented: $isPresented) {
              MyView() // Replace with your content
          }
      }
      ```

      - seeAlso: ``PropertyInspector/init(_:isPresented:listStyle:listRowBackground:label:)`` for more customized sheet styles.
     */
    @available(iOS 16.4, macOS 13.3, *)
    init(
        _ title: LocalizedStringKey? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) where Style == _SheetPropertyInspector<PlainListStyle, Color> {
        self.label = label()
        style = _SheetPropertyInspector(
            title: title,
            isPresented: isPresented,
            listStyle: .plain,
            listRowBackground: .clear
        )
    }

    /**
     Initializes a `PropertyInspector` with a configurable sheet style based on specified list and background settings.

     This initializer allows for a flexible configuration of the sheet presentation of a property inspector, providing the ability to customize the list style and the background color of list rows. It's designed to be used when you need to match the inspector's styling closely with your app's design language.

     - Parameters:
       - title: An optional title for the sheet; if not provided, defaults to `nil`.
       - isPresented: A binding to a Boolean value that controls the presentation state of the sheet. This value should be managed by the view that triggers the inspector to show or hide.
       - listStyle: The style of the list used within the sheet, conforming to `ListStyle`. This parameter allows you to use any list style available in SwiftUI, such as `.plain`, `.grouped`, `.insetGrouped`, etc.
       - listRowBackground: An optional color to use for the background of each row in the list. Defaults to `nil`, which will not apply any background color unless specified.
       - label: A closure that returns the content to be displayed within the sheet. This view builder allows for dynamic content creation, enabling the use of custom views as content.

     ## Usage Example

     ```swift
     @State private var isPresented = false

     var body: some View {
         PropertyInspector(
             "Detailed Settings",
             isPresented: $isPresented,
             listStyle: .insetGrouped) {
                 MyView() // Replace with your content
             }
         }
     }
     ```
     - seeAlso: ``init(_:isPresented:label:)`` for a simpler, default styling setup, or ``init(_:isPresented:listStyle:listRowBackground:label:)`` for variations with more specific list styles.
     */
    @available(iOS 16.4, macOS 13.3, *)
    init<L: ListStyle>(
        _ title: LocalizedStringKey? = nil,
        isPresented: Binding<Bool>,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == _SheetPropertyInspector<L, Color> {
        self.label = label()
        style = _SheetPropertyInspector(
            title: title,
            isPresented: isPresented,
            listStyle: listStyle,
            listRowBackground: listRowBackground
        )
    }

    /**
     Initializes a `PropertyInspector` with a customizable list style, suitable for detailed and integrated list presentations.

     This initializer allows for the customization of the list's appearance within a `PropertyInspector`, making it ideal for applications where the inspector needs to be seamlessly integrated within a broader UI context, or where specific styling of list items is required.

     - Parameters:
       - title: An optional title for the list; if not provided, defaults to `nil`. This title is displayed at the top of the list and can be used to provide context or headings to the user.
       - listStyle: The style of the list used within the inspector, conforming to `ListStyle`. This parameter allows for significant visual customization of the list, supporting all styles provided by SwiftUI, such as `.plain`, `.grouped`, `.insetGrouped`, etc.
       - listRowBackground: An optional color to use for the background of each row in the list. If `nil`, the default background color for the list style is used.
       - label: A closure that returns the content to be displayed within the list. This is typically where you would compose the view elements that make up the content of the inspector.

     ## Usage Example

     ```swift
     var body: some View {
         PropertyInspector("User Preferences", listStyle: .grouped) {
             MyView() // Replace with your content
         }
     }
     ```

     - seeAlso: ``init(_:isPresented:listStyle:listRowBackground:label:)`` for a version of this initializer that supports modal presentation with `isPresented` binding.
     */
    init<L: ListStyle>(
        _ title: LocalizedStringKey? = nil,
        listStyle: L,
        listRowBackground: Color? = nil,
        @ViewBuilder label: () -> Label
    ) where Style == _ListPropertyInspector<L, Color> {
        self.label = label()
        style = _ListPropertyInspector(
            title: title,
            listStyle: listStyle,
            listRowBackground: listRowBackground,
            contentPadding: true
        )
    }

    /**
     Initializes a `PropertyInspector` with a customizable list style, suitable for detailed and integrated list presentations.

     This initializer allows for the customization of the list's appearance within a `PropertyInspector`, making it ideal for applications where the inspector needs to be seamlessly integrated within a broader UI context, or where specific styling of list items is required.

     - Parameters:
       - title: An optional title for the list; if not provided, defaults to `nil`. This title is displayed at the top of the list and can be used to provide context or headings to the user.
       - listStyle: The style of the list used within the inspector, conforming to `ListStyle`. This parameter allows for significant visual customization of the list, supporting all styles provided by SwiftUI, such as `.plain`, `.grouped`, `.insetGrouped`, etc.
       - listRowBackground: An optional view to use for the background of each row in the list. If `nil`, the default background view for the list style is used.
       - label: A closure that returns the content to be displayed within the list. This is typically where you would compose the view elements that make up the content of the inspector.

     ## Usage Example

     ```swift
     var body: some View {
         PropertyInspector("User Preferences", listStyle: .grouped) {
             MyView() // Replace with your content
         }
     }
     ```

     - seeAlso: ``init(_:isPresented:listStyle:listRowBackground:label:)`` for a version of this initializer that supports modal presentation with `isPresented` binding.
     */
    init<L: ListStyle, B: View>(
        _ title: LocalizedStringKey? = nil,
        listStyle: L,
        listRowBackground: B,
        @ViewBuilder label: () -> Label
    ) where Style == _ListPropertyInspector<L, B> {
        self.label = label()
        style = _ListPropertyInspector(
            title: title,
            listStyle: listStyle,
            listRowBackground: listRowBackground,
            contentPadding: true
        )
    }

    /**
     Initializes a `PropertyInspector` with an inline presentation style.

     This initializer is designed for cases where property inspection needs to be seamlessly integrated within the flow of existing content, rather than displayed as a separate list or modal. It is particularly useful in contexts where minimal disruption to the user interface is desired.

     - Parameters:
       - label: A closure that returns the content to be displayed directly in line with other UI elements. This allows for dynamic creation of content based on current state or other conditions.

     ## Usage Example

     ```swift
     var body: some View {
         VStack {
             Text("Settings")
             PropertyInspector("User Preferences") {
                 Toggle("Enable Notifications", isOn: $notificationsEnabled)
             }
             Text("Other Options")
         }
     }
     ```

     - seeAlso: ``init(_:isPresented:listStyle:listRowBackground:label:)`` for modal presentation styles, or  ``init(_:listStyle:listRowBackground:label:)-1gshp`` for list-based styles with more extensive customization options.
     */
    init(@ViewBuilder label: () -> Label) where Style == _InlinePropertyInspector {
        self.label = label()
        style = _InlinePropertyInspector()
    }
}
// swiftformat:disable stripunusedargs

public extension View {
    /// Inspects the view itself.
    func inspectSelf<S: Shape>(
        shape: S = Rectangle(),
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        inspectProperty(
            self,
            shape: shape,
            function: function,
            line: line,
            file: file
        )
    }

    /**
     Adds a modifier for inspecting properties with dynamic debugging capabilities.

     This method allows developers to dynamically inspect values of properties within a SwiftUI view, useful for debugging and during development to ensure that view states are correctly managed.

     - Parameters:
       - values: A variadic list of properties whose values you want to inspect.
       - shape: The shape of the highlight.
       - function: The function from which the inspector is called, generally used for debugging purposes. Defaults to the name of the calling function.
       - line: The line number in the source file from which the inspector is called, aiding in pinpointing where inspections are set. Defaults to the line number in the source file.
       - file: The name of the source file from which the inspector is called, useful for tracing the call in larger projects. Defaults to the filename.

     - Returns: A view modified to include property inspection capabilities, reflecting the current state of the provided properties.

     ## Usage Example

     ```swift
     Text("Current Count: \(count)").inspectProperty(count)
     ```

     This can be particularly useful when paired with logging or during step-by-step debugging to monitor how and when your view's state changes.

     - seeAlso: ``propertyInspectorHidden()`` and ``inspectSelf(shape:function:line:file:)``
     */
    @_disfavoredOverload
    func inspectProperty<S: Shape>(
        _ values: Any...,
        shape: S = Rectangle(),
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        modifier(
            PropertyWriter(
                data: values.map(PropertyValue.init),
                shape: shape,
                location: .init(
                    function: function,
                    file: file,
                    line: line
                )
            )
        )
    }

    /**
     Adds a modifier for inspecting properties with dynamic debugging capabilities.

     This method allows developers to dynamically inspect values of properties within a SwiftUI view, useful for debugging and during development to ensure that view states are correctly managed.

     - Parameters:
       - values: A variadic list of properties whose values you want to inspect.
       - shape: The shape of the highlight.
       - function: The function from which the inspector is called, generally used for debugging purposes. Defaults to the name of the calling function.
       - line: The line number in the source file from which the inspector is called, aiding in pinpointing where inspections are set. Defaults to the line number in the source file.
       - file: The name of the source file from which the inspector is called, useful for tracing the call in larger projects. Defaults to the filename.

     - Returns: A view modified to include property inspection capabilities, reflecting the current state of the provided properties.

     ## Usage Example

     ```swift
     Text("Current Count: \(count)").inspectProperty(count)
     ```

     This can be particularly useful when paired with logging or during step-by-step debugging to monitor how and when your view's state changes.

     - seeAlso: ``propertyInspectorHidden()`` and ``inspectSelf(shape:function:line:file:)``
     */
    func inspectProperty<T, S: Shape>(
        _ values: T...,
        shape: S = Rectangle(),
        function: String = #function,
        line: Int = #line,
        file: String = #file
    ) -> some View {
        modifier(
            PropertyWriter(
                data: values.map {
                    PropertyValue($0)
                },
                shape: shape,
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

     - seeAlso: <doc:/documentation/PropertyInspector/SwiftUICore/View/inspectProperty(_:shape:function:line:file:)-7u3kz> and <doc:/documentation/PropertyInspector/SwiftUICore/View/inspectProperty(_:shape:function:line:file:)-4bprj>.
     */
    func propertyInspectorHidden() -> some View {
        environment(\.isInspectable, false)
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

     - seeAlso: ``propertyInspectorRowLabel(for:label:)``, ``propertyInspectorRowDetail(for:detail:)``, ``propertyInspectorRowIcon(for:systemName:)``
     */
    func propertyInspectorRowIcon<D, Icon: View>(
        for data: D.Type = Any.self,
        @ViewBuilder icon: @escaping (_ data: D) -> Icon
    ) -> some View {
        setPreference(RowIconPreferenceKey.self, body: icon)
    }

    /**
     Applies a modifier to inspect properties with custom icons based on their data type.

     This method allows you to define custom icons for different data types displayed in the property inspector, enhancing the visual differentiation and user experience.

     - Parameter data: The type of data for which the icon is defined.
     - Parameter systemName: A closure that returns the icon to use for the given data type.

     - Returns: A modified view with the custom icon configuration applied to relevant properties.

     ## Usage Example

     ```swift
     Text("Example Property").propertyInspectorRowIcon(systemName: "text.quote")
     ```

     - seeAlso: ``propertyInspectorRowLabel(for:label:)``, ``propertyInspectorRowDetail(for:detail:)``, ``propertyInspectorRowIcon(for:icon:)``.
     */
    func propertyInspectorRowIcon<D>(
        for data: D.Type = Any.self,
        systemName: String
    ) -> some View { // swiftformat:disable:this stripunusedargs
        setPreference(RowIconPreferenceKey.self) { (_: D) in
             Image(systemName: systemName)
        }
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

    /// Modifies the font used for the label text in a property inspector row.
    ///
    /// Use this modifier to specify a custom font for the label text within property inspector rows.
    /// This customization allows for a consistent typographic hierarchy or to emphasize particular content.
    ///
    /// - Parameter font: The `Font` to apply to the label text.
    ///   The default value, used when this modifier is not applied, is `callout`.
    func propertyInspectorRowLabelFont(_ font: Font) -> some View {
        environment(\.rowLabelFont, font)
    }

    /// Modifies the font used for the detail text in a property inspector row.
    ///
    /// Apply this modifier to a view to define the appearance of detail text,
    /// which is typically used for additional information or numeric values associated with a property.
    /// This modifier helps in maintaining visual consistency or in adjusting readability according to the design requirements.
    ///
    /// - Parameter font: The `Font` to use for the detail text.
    ///   The default value, used when this modifier is not applied, is `caption`.
    func propertyInspectorRowDetailFont(_ font: Font) -> some View {
        environment(\.rowDetailFont, font)
    }
}

/**
 Customizes the appearance and behavior of ``PropertyInspector`` components. This protocol adheres to `ViewModifier`, enabling it to modify the view of a ``PropertyInspector`` to match specific design requirements.
 */
public protocol _PropertyInspectorStyle: ViewModifier {}

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

// MARK: - List Style

/**
 `_ListPropertyInspector` provides a SwiftUI view modifier that applies a list-style presentation to property inspectors.

 This style organizes properties into a list, using specified list styles and row backgrounds, suitable for inspections within a non-modal, integrated list environment.

 - Parameters:
   - listStyle: The style of the list, conforming to `ListStyle`. Typical styles include `.plain`, `.grouped`, and `.insetGrouped`, depending on the desired visual effect.
   - listRowBackground: The view used as the background for each row in the list, conforming to `View`. This could be a simple `Color` or more complex custom views.
   - title: An optional title for the list; if not provided, defaults to `nil`.
   - contentPadding: A Boolean value that indicates whether the content should have padding. Defaults to `false`.

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

                    PropertyInspectorHeader(data: title)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(listStyle)
        .ios16_scrollBounceBehaviorBasedOnSize()
    }
}
#if canImport(UIKit)
#endif

// MARK: - Sheet Style

/**
 `_SheetPropertyInspector` provides a SwiftUI view modifier that applies a sheet-style presentation to property inspectors.

 This style organizes properties within a customizable list, using specified list styles and row backgrounds, making it ideal for detailed inspections in a modal sheet format.

 - Parameters:
   - isPresented: A binding to a Boolean value that indicates whether the property inspector sheet is presented.
   - listStyle: The style of the list used within the sheet, conforming to `ListStyle`.
   - listRowBackground: The view used as the background for each row in the list, conforming to `View`.
   - title: An optional title for the sheet; if not provided, defaults to `nil`.

 - Returns: A view modifier that configures the appearance and behavior of a property inspector using the specified sheet style.

 ## Usage

 You don't instantiate `_SheetPropertyInspector` directly, instead use one of the convenience initializers in ``PropertyInspector``.
 Here’s how you might configure and present a property inspector with a sheet style:

 ```swift
 @State private var isPresented = false

 var body: some View {
     PropertyInspector(
         "Optional Title",
         isPresented: $isPresented,
         listStyle: .plain, // optional
         label: {
             // your app, flows, screens, components, your choice
             MyFeatureScreen()
         }
     )
 }
 ```

 ## Performance Considerations
 Utilizing complex views as `listRowBackground` may impact performance, especially with larger lists.

 - Note: Requires iOS 16.4 or newer due to specific SwiftUI features utilized.

 - seeAlso: ``_ListPropertyInspector`` and ``_InlinePropertyInspector``.
 */
@available(iOS 16.4, macOS 13.3, *)
public struct _SheetPropertyInspector<Style: ListStyle, RowBackground: View>: _PropertyInspectorStyle {
    var title: LocalizedStringKey?

    @Binding
    var isPresented: Bool

    var listStyle: Style

    var listRowBackground: RowBackground?

    @EnvironmentObject
    private var context: Context.Data

    @AppStorage("HighlightBehavior")
    private var highlight = PropertyInspectorHighlightBehavior.hideOnDismiss

    @State
    private var contentHeight: Double = .zero

    public func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                Spacer().frame(height: isPresented ? contentHeight : .zero)
            }
            .toolbar {
                SheetToolbarContent(
                    isPresented: $isPresented,
                    highlight: $highlight
                )
            }
            .modifier(
                SheetPresentationModifier(
                    isPresented: $isPresented,
                    height: $contentHeight,
                    label: EmptyView().modifier(
                        _ListPropertyInspector(
                            title: title,
                            listStyle: listStyle,
                            listRowBackground: listRowBackground,
                            contentPadding: false
                        )
                    )
                )
            )
            .onChange(of: isPresented) { newValue in
                DispatchQueue.main.async {
                    updateHighlightIfNeeded(newValue)
                }
            }
    }

    private func updateHighlightIfNeeded(_ isPresented: Bool) {
        let newValue: Bool

        switch highlight {
        case .automatic: newValue = isPresented
        case .hideOnDismiss where !isPresented: newValue = false
        default: return
        }

        for property in context.properties {
            property.isHighlighted = newValue
        }
    }
}

@available(iOS 16.4, macOS 13.0, *)
private struct SheetPresentationModifier<Label: View>: ViewModifier {
    @Binding
    var isPresented: Bool

    @Binding
    var height: Double

    var label: Label

    @State
    private var selection: PresentationDetent = SheetPresentationModifier.detents[1]

    private static var detents: [PresentationDetent] { [
        .fraction(0.25),
        .fraction(0.45),
        .fraction(0.65),
        .large
    ] }

    func body(content: Content) -> some View {
        content.overlay {
            Spacer().sheet(isPresented: $isPresented) {
                if #available(macOS 13.3, *) {
                    label
                        .scrollContentBackground(.hidden)
                        .presentationBackgroundInteraction(.enabled)
                        .presentationContentInteraction(.scrolls)
                        .presentationCornerRadius(20)
                        .presentationBackground(Material.thinMaterial)
                        .presentationDetents(Set(SheetPresentationModifier.detents), selection: $selection)
                        .background(GeometryReader { geometry in
                            Color.clear.onChange(of: geometry.frame(in: .global).minY) { minY in
                                #if canImport(UIKit)
                                let screenHeight = UIScreen.main.bounds.height
                                #else
                                let screenHeight = NSScreen.main?.frame.height ?? 1000
                                #endif
                                let newInset = max(0, round(screenHeight - minY))
                                if height != newInset {
                                    height = newInset
                                }
                            }
                        })
                } else {
                    label
                        .scrollContentBackground(.hidden)
                        .presentationDetents(Set(SheetPresentationModifier.detents), selection: $selection)
                        .background(GeometryReader { geometry in
                            Color.clear.onChange(of: geometry.frame(in: .global).minY) { minY in
                                #if canImport(UIKit)
                                let screenHeight = UIScreen.main.bounds.height
                                #else
                                let screenHeight = NSScreen.main?.frame.height ?? 1000
                                #endif
                                let newInset = max(0, round(screenHeight - minY))
                                if height != newInset {
                                    height = newInset
                                }
                            }
                        })
                }
            }
        }
    }
}

private struct SheetToolbarContent: View {
    @Binding
    var isPresented: Bool

    @Binding
    var highlight: PropertyInspectorHighlightBehavior

    var body: some View {
        Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            #endif
            withAnimation(.snappy(duration: 0.35)) {
                isPresented.toggle()
            }
        } label: {
            Image(systemName: "\(isPresented ? "xmark" : "magnifyingglass").circle.fill")
                .rotationEffect(.radians(isPresented ? -.pi : .zero))
                .font(.title3)
                .padding()
                .contextMenu(menuItems: menuItems)
        }
        .symbolRenderingMode(.hierarchical)
    }

    @ViewBuilder
    private func menuItems() -> some View {
        let title = "Highlight Behavior"
        Text(title)
        Divider()
        Picker(title, selection: $highlight) {
            ForEach(PropertyInspectorHighlightBehavior.allCases, id: \.hashValue) { behavior in
                Button(behavior.label) {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    highlight = behavior
                }
                .tag(behavior)
            }
        }
    }
}
#if canImport(UIKit)
#endif

struct PropertyToggleStyle: ToggleStyle {
    var alignment: VerticalAlignment = .center

    var symbolFont: Font = .title

    var symbolName: (_ isOn: Bool) -> String = { isOn in
        if isOn {
            "eye.circle.fill"
        } else {
            "eye.slash.circle.fill"
        }
    }

    #if canImport(UIKit)
    private let feedback = UISelectionFeedbackGenerator()
    #endif

    func makeBody(configuration: Configuration) -> some View {
        Button {
            #if canImport(UIKit)
            feedback.selectionChanged()
            #endif
            withAnimation(.inspectorDefault) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(alignment: alignment) {
                configuration.label
                Spacer()
                Image(systemName: symbolName(configuration.isOn))
                    .font(symbolFont)
                    .ios17_interpolateSymbolEffect()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .secondary)
            }
        }
    }
}

struct Context: ViewModifier {
    @StateObject
    private var data = Data()

    func body(content: Content) -> some View {
        content.onPreferenceChange(PropertyPreferenceKey.self) { newValue in
            if data.allObjects != newValue {
                data.allObjects = newValue
            }
        }.onPreferenceChange(RowDetailPreferenceKey.self) { newValue in
            if data.detailRegistry != newValue {
                data.detailRegistry = newValue
            }
        }.onPreferenceChange(RowIconPreferenceKey.self) { newValue in
            if data.iconRegistry != newValue {
                data.iconRegistry = newValue
            }
        }.onPreferenceChange(RowLabelPreferenceKey.self) { newValue in
            if data.labelRegistry != newValue {
                data.labelRegistry = newValue
            }
        }.environmentObject(data)
    }
}

extension View {
    func setPreference<K: PreferenceKey>(_: K.Type, value: K.Value) -> some View {
        modifier(PreferenceWriter<K>(value: value))
    }

    func setPreference<K: PreferenceKey, D, C: View>(_: K.Type, @ViewBuilder body: @escaping (D) -> C) -> some View where K.Value == RowViewBuilderRegistry {
        let builder = RowViewBuilder(body: body)
        return modifier(
            PreferenceWriter<K>(value: RowViewBuilderRegistry(builder))
        )
    }
}

struct PreferenceWriter<K: PreferenceKey>: ViewModifier {
    let value: K.Value

    func body(content: Content) -> some View {
        content.background(
            Spacer().preference(key: K.self, value: value)
        )
    }
}

struct PropertyHiglighter<S: Shape>: ViewModifier {
    @Binding var isOn: Bool
    var shape: S

    func body(content: Content) -> some View {
        content
            .zIndex(isOn ? 999 : 0)
            .overlay {
                if isOn {
                    shape
                        .stroke(lineWidth: 1.5)
                        .fill(.cyan.opacity(isOn ? 1 : 0))
                        .transition(
                            .asymmetric(
                                insertion: insertion,
                                removal: removal
                            )
                        )
                }
            }
    }

    private var insertion: AnyTransition {
        .opacity
            .combined(with: .scale(scale: .random(in: 2 ... 2.5)))
            .animation(insertionAnimation)
    }

    private var removal: AnyTransition {
        .opacity
            .combined(with: .scale(scale: .random(in: 1.1 ... 1.4)))
            .animation(removalAnimation)
    }

    private var removalAnimation: Animation {
        .smooth(duration: .random(in: 0.1 ... 0.35))
            .delay(.random(in: 0 ... 0.15))
    }

    private var insertionAnimation: Animation {
        .snappy(
            duration: .random(in: 0.2 ... 0.5),
            extraBounce: .random(in: 0 ... 0.1)
        )
        .delay(.random(in: 0 ... 0.3))
    }
}

struct PropertyWriter<S: Shape>: ViewModifier {
    var data: [PropertyValue]
    var location: PropertyLocation
    var shape: S

    init(data: [PropertyValue], shape: S, location: PropertyLocation) {
        self.data = data
        self.shape = shape
        self.location = location
        _ids = State(initialValue: (0 ..< data.count).map { offset in
            PropertyID(
                offset: offset,
                createdAt: Date(),
                location: location
            )
        })
    }

    @State
    private var ids: [PropertyID]

    @State
    private var isHighlighted = false
    
    @State
    private var cache = PropertyCache()

    @Environment(\.isInspectable)
    private var isInspectable

    func body(content: Content) -> some View {
        #if VERBOSE
            Self._printChanges()
        #endif
        return content.setPreference(
            PropertyPreferenceKey.self, value: properties
        )
        .modifier(
            PropertyHiglighter(isOn: $isHighlighted, shape: shape)
        )
    }

    private var properties: [PropertyType: Set<Property>] {
        if !isInspectable {
            return [:]
        }
        let result: [PropertyType: Set<Property>] = zip(ids, data).reduce(into: [:]) { dict, element in
            let (id, value) = element
            let key = value.type
            var set = dict[key] ?? Set()
            
            // ✅ Use cache to avoid recreating Property objects
            let property = cache.property(
                for: id,
                token: String(describing: value.rawValue).hashValue,
                value: value,
                isHighlighted: $isHighlighted
            )
            set.insert(property)
            dict[key] = set
        }

        return result
    }
}

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
        .mask {
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .leading,
                endPoint: .init(x: 0.04, y: 0.5)
            )
        }
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

        if #available(iOS 16.0, macOS 13.0, *), !context.properties.isEmpty {
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

@MainActor
struct PropertyInspectorRow<Icon: View, Label: View, Detail: View>: View, Equatable {
    nonisolated static func == (lhs: PropertyInspectorRow<Icon, Label, Detail>, rhs: PropertyInspectorRow<Icon, Label, Detail>) -> Bool {
        lhs.id == rhs.id
    }

    var id: Int
    @Binding
    var isOn: Bool
    var hideIcon: Bool
    var icon: Icon
    var label: Label
    var detail: Detail

    @Environment(\.rowLabelFont)
    private var labelFont

    @Environment(\.rowDetailFont)
    private var detailFont

    var body: some View {
        #if VERBOSE
            PropertyInspectorRow._printChanges()
        #endif
        return Toggle(isOn: $isOn, label: content).toggleStyle(
            PropertyToggleStyle()
        )
        .foregroundStyle(.secondary)
        .padding(.vertical, 1)
        .listRowBackground(
            isOn ? Color(white: 0.95).opacity(0.5) : .clear
        )
    }

    private func content() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label.foregroundStyle(.primary)
            detail.font(detailFont)
        }
        .allowsTightening(true)
        .multilineTextAlignment(.leading)
        .contentShape(Rectangle())
        .safeAreaInset(edge: .leading, alignment: .firstTextBaseline) {
            if !hideIcon {
                icon.scaledToFit().frame(width: 25)
            }
        }
        .font(labelFont)
    }
}

#Preview {
    PropertyInspectorRow(
        id: 0,
        isOn: .constant(true),
        hideIcon: false,
        icon: Image(systemName: "circle"),
        label: Text(verbatim: "Some text"),
        detail: Text(verbatim: "Some detail")
    )
}

#Preview {
    PropertyInspectorRow(
        id: 0,
        isOn: .constant(true),
        hideIcon: true,
        icon: Image(systemName: "circle"),
        label: Text(verbatim: "Some text"),
        detail: Text(verbatim: "Some detail")
    )
}

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
                .modifier(HideListRowSeparatorModifier())
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

private struct HideListRowSeparatorModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, macOS 13.0, *) {
            content.listRowSeparator(.hidden)
        } else {
            content
        }
    }
}

struct PropertyLocationView: View {
    var data: PropertyLocation

    var body: some View {
        text
            .lineLimit(1)
            .truncationMode(.head)
            .foregroundStyle(.secondary)
    }

    var text: some View {
        Text(verbatim: data.function) +
            Text(verbatim: " — ").bold().ios17_quinaryForegroundStyle() +
            Text(verbatim: data.description)
    }
}

private extension Text {
    func ios17_quinaryForegroundStyle() -> Text {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.foregroundStyle(.quinary)
        } else {
            // Fallback on earlier versions
            self
        }
    }
}
