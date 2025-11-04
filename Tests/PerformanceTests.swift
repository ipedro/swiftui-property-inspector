import XCTest
import SwiftUI
@testable import PropertyInspector

/// Performance benchmarks to track improvements and prevent regressions
@MainActor
final class PerformanceTests: XCTestCase {
    
    // MARK: - Search Performance
    
    func testSearchPerformance() async throws {
        let context = Context.Data()
        
        // Create large dataset
        let mockProperties = createLargePropertySet(count: 1000)
        context.allObjects = mockProperties
        
        measure {
            context.searchQuery = "test"
            context.searchQuery = "value"
            context.searchQuery = "property"
        }
    }
    
    func testSearchDebouncePerformance() async throws {
        let context = Context.Data()
        let mockProperties = createLargePropertySet(count: 500)
        context.allObjects = mockProperties
        
        measure {
            // Rapid fire changes - should be debounced
            for i in 0..<100 {
                context.searchQuery = "query\(i)"
            }
        }
    }
    
    // MARK: - Filter Performance
    
    func testFilterOperationPerformance() {
        let context = Context.Data()
        let mockProperties = createMixedTypeProperties(typesCount: 20, propertiesPerType: 50)
        context.allObjects = mockProperties
        
        measure {
            // Toggle all filters multiple times
            for _ in 0..<10 {
                context.toggleAllFilters.wrappedValue = false
                context.toggleAllFilters.wrappedValue = true
            }
        }
    }
    
    // MARK: - Property Creation Performance
    
    func testPropertyCreationPerformance() {
        let values = (0..<1000).map { PropertyValue("test\($0)") }
        let location = PropertyLocation(function: "test", file: "test.swift", line: 1)
        
        measure {
            _ = PropertyWriter(data: values, location: location)
        }
    }
    
    // MARK: - Cache Performance
    
    func testCacheLookupPerformance() {
        var registry = RowViewBuilderRegistry()
        let builder = RowViewBuilder { (value: String) in
            Text(value)
        }
        registry[builder.id] = builder
        
        let properties = (0..<1000).map { i in
            createMockProperty(value: "test\(i)")
        }
        
        // First pass - populate cache
        for property in properties {
            _ = registry.makeBody(property: property)
        }
        
        // Second pass - should hit cache
        measure {
            for property in properties {
                _ = registry.makeBody(property: property)
            }
        }
    }
    
    // MARK: - Property Comparison Performance
    
    func testPropertyComparisonPerformance() {
        let properties = createLargePropertyArray(count: 1000)
        
        measure {
            let sorted = properties.sorted()
            XCTAssertEqual(sorted.count, properties.count)
        }
    }
    
    // MARK: - String Conversion Performance
    
    func testStringConversionPerformance() {
        let values: [Any] = (0..<1000).map { i -> Any in
            if i % 3 == 0 { return "string\(i)" }
            if i % 3 == 1 { return i }
            return true
        }
        
        measure {
            for value in values {
                _ = String(describing: value)
            }
        }
    }
    
    // MARK: - Animation State Performance
    
    func testHighlightTogglePerformance() {
        let properties = createLargePropertyArray(count: 500)
        
        measure {
            for property in properties {
                property.isHighlighted = true
                property.isHighlighted = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLargePropertySet(count: Int) -> [PropertyType: Set<Property>] {
        var result: [PropertyType: Set<Property>] = [:]
        let type = PropertyType(String.self)
        var set = Set<Property>()
        
        for i in 0..<count {
            let value = PropertyValue("test\(i)")
            let id = PropertyID(
                offset: i,
                createdAt: Date(),
                location: PropertyLocation(function: "test", file: "test.swift", line: i % 100)
            )
            let property = Property(
                id: id,
                token: i,
                value: value,
                isHighlighted: .constant(false)
            )
            set.insert(property)
        }
        
        result[type] = set
        return result
    }
    
    private func createMixedTypeProperties(typesCount: Int, propertiesPerType: Int) -> [PropertyType: Set<Property>] {
        var result: [PropertyType: Set<Property>] = [:]
        
        for typeIndex in 0..<typesCount {
            let type: PropertyType
            let valueGenerator: (Int) -> PropertyValue
            
            switch typeIndex % 3 {
            case 0:
                type = PropertyType(String.self)
                valueGenerator = { PropertyValue("string\($0)") }
            case 1:
                type = PropertyType(Int.self)
                valueGenerator = { PropertyValue($0) }
            default:
                type = PropertyType(Bool.self)
                valueGenerator = { PropertyValue($0 % 2 == 0) }
            }
            
            var set = Set<Property>()
            for i in 0..<propertiesPerType {
                let value = valueGenerator(i)
                let id = PropertyID(
                    offset: i,
                    createdAt: Date(),
                    location: PropertyLocation(function: "test", file: "test\(typeIndex).swift", line: i)
                )
                let property = Property(
                    id: id,
                    token: i,
                    value: value,
                    isHighlighted: .constant(false)
                )
                set.insert(property)
            }
            result[type] = set
        }
        
        return result
    }
    
    private func createLargePropertyArray(count: Int) -> [Property] {
        (0..<count).map { i in
            let value = PropertyValue("test\(i)")
            let id = PropertyID(
                offset: i,
                createdAt: Date(),
                location: PropertyLocation(function: "test", file: "test.swift", line: i % 100)
            )
            return Property(
                id: id,
                token: i,
                value: value,
                isHighlighted: .constant(false)
            )
        }
    }
    
    private func createMockProperty(value: Any) -> Property {
        let propValue = PropertyValue(value)
        let id = PropertyID(
            offset: 0,
            createdAt: Date(),
            location: PropertyLocation(function: "test", file: "test.swift", line: 1)
        )
        return Property(
            id: id,
            token: String(describing: value).hashValue,
            value: propValue,
            isHighlighted: .constant(false)
        )
    }
}
