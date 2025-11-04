import XCTest
import SwiftUI
import Combine
@testable import PropertyInspector

@MainActor
final class ContextDataTests: XCTestCase {
    var sut: Context.Data!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        sut = Context.Data()
        cancellables = []
    }
    
    override func tearDown() async throws {
        cancellables = nil
        sut = nil
    }
    
    // MARK: - Search Debouncing Tests
    
    func testSearchDebouncing() async throws {
        let expectation = XCTestExpectation(description: "Search debounced")
        var callCount = 0
        
        sut.$properties
            .dropFirst() // Skip initial value
            .sink { _ in
                callCount += 1
                if callCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Rapid fire search queries
        sut.searchQuery = "a"
        sut.searchQuery = "ab"
        sut.searchQuery = "abc"
        sut.searchQuery = "abcd"
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Should only trigger once due to debouncing
        XCTAssertEqual(callCount, 1, "Search should be debounced")
    }
    
    func testSearchWithEmptyQuery() {
        let mockProperties = createMockProperties(count: 5)
        sut.allObjects = mockProperties
        
        sut.searchQuery = ""
        
        XCTAssertEqual(sut.properties.count, 5, "Empty search should return all properties")
    }
    
    func testSearchWithSingleCharacter() {
        let mockProperties = createMockProperties(count: 5)
        sut.allObjects = mockProperties
        
        sut.searchQuery = "a"
        
        // Current implementation returns all properties for single char
        // This is a known issue - should be documented
        XCTAssertEqual(sut.properties.count, 5)
    }
    
    func testSearchWithMultipleCharacters() {
        let mockProperties = createMockPropertiesWithValues(values: ["apple", "banana", "cherry"])
        sut.allObjects = mockProperties
        
        sut.searchQuery = "app"
        
        XCTAssertEqual(sut.properties.count, 1, "Should find 'apple'")
    }
    
    // MARK: - Filter Tests
    
    func testFilterToggle() {
        let mockProperties = createMockPropertiesWithTypes(types: ["String", "Int"])
        sut.allObjects = mockProperties
        
        XCTAssertEqual(sut.filters.count, 2, "Should have 2 filters")
        
        let stringFilter = sut.filters.first { String(describing: $0.wrappedValue.rawValue) == "String" }
        XCTAssertNotNil(stringFilter)
        
        if let filter = stringFilter {
            let binding = sut.toggleFilter(filter)
            binding.wrappedValue = false
            
            XCTAssertFalse(filter.isOn, "Filter should be disabled")
        }
    }
    
    func testToggleAllFilters() {
        let mockProperties = createMockPropertiesWithTypes(types: ["String", "Int", "Bool"])
        sut.allObjects = mockProperties
        
        let toggleAll = sut.toggleAllFilters
        toggleAll.wrappedValue = false
        
        for filter in sut.filters {
            XCTAssertFalse(filter.isOn, "All filters should be disabled")
        }
        
        toggleAll.wrappedValue = true
        
        for filter in sut.filters {
            XCTAssertTrue(filter.isOn, "All filters should be enabled")
        }
    }
    
    // MARK: - Property Management Tests
    
    func testPropertyUpdate() {
        let mockProperties = createMockProperties(count: 3)
        
        sut.allObjects = mockProperties
        
        XCTAssertEqual(sut.properties.count, 3)
        XCTAssertEqual(sut.allProperties.count, 3)
    }
    
    func testDuplicatePropertyPrevention() {
        let mockProperties = createMockProperties(count: 3)
        
        sut.allObjects = mockProperties
        let firstCount = sut.properties.count
        
        // Set same properties again
        sut.allObjects = mockProperties
        let secondCount = sut.properties.count
        
        XCTAssertEqual(firstCount, secondCount, "Duplicate update should not change count")
    }
    
    // MARK: - Helper Methods
    
    private func createMockProperties(count: Int) -> [PropertyType: Set<Property>] {
        var result: [PropertyType: Set<Property>] = [:]
        let type = PropertyType(String.self)
        var set = Set<Property>()
        
        for i in 0..<count {
            let value = PropertyValue("Test \(i)")
            let id = PropertyID(
                offset: i,
                createdAt: Date(),
                location: PropertyLocation(function: "test", file: "test.swift", line: i)
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
    
    private func createMockPropertiesWithValues(values: [String]) -> [PropertyType: Set<Property>] {
        var result: [PropertyType: Set<Property>] = [:]
        let type = PropertyType(String.self)
        var set = Set<Property>()
        
        for (i, value) in values.enumerated() {
            let propValue = PropertyValue(value)
            let id = PropertyID(
                offset: i,
                createdAt: Date(),
                location: PropertyLocation(function: "test", file: "test.swift", line: i)
            )
            let property = Property(
                id: id,
                token: value.hashValue,
                value: propValue,
                isHighlighted: .constant(false)
            )
            set.insert(property)
        }
        
        result[type] = set
        return result
    }
    
    private func createMockPropertiesWithTypes(types: [String]) -> [PropertyType: Set<Property>] {
        var result: [PropertyType: Set<Property>] = [:]
        
        for (i, typeName) in types.enumerated() {
            let type: PropertyType
            let value: PropertyValue
            
            switch typeName {
            case "String":
                type = PropertyType(String.self)
                value = PropertyValue("test")
            case "Int":
                type = PropertyType(Int.self)
                value = PropertyValue(42)
            case "Bool":
                type = PropertyType(Bool.self)
                value = PropertyValue(true)
            default:
                continue
            }
            
            let id = PropertyID(
                offset: i,
                createdAt: Date(),
                location: PropertyLocation(function: "test", file: "test.swift", line: i)
            )
            let property = Property(
                id: id,
                token: i,
                value: value,
                isHighlighted: .constant(false)
            )
            
            var set = result[type] ?? Set<Property>()
            set.insert(property)
            result[type] = set
        }
        
        return result
    }
}
