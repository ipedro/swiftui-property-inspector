import XCTest
import SwiftUI
@testable import PropertyInspector

@MainActor
final class RowViewBuilderRegistryTests: XCTestCase {
    var sut: RowViewBuilderRegistry!
    
    override func setUp() async throws {
        sut = RowViewBuilderRegistry()
    }
    
    override func tearDown() async throws {
        sut = nil
    }
    
    // MARK: - Builder Registration Tests
    
    func testBuilderRegistration() {
        let builder = RowViewBuilder { (value: String) in
            Text(value)
        }
        
        sut[builder.id] = builder
        
        XCTAssertFalse(sut.isEmpty, "Registry should not be empty after adding builder")
        XCTAssertEqual(sut.identifiers.count, 1, "Should have 1 identifier")
    }
    
    func testMultipleBuilderRegistration() {
        let stringBuilder = RowViewBuilder { (value: String) in
            Text(value)
        }
        let intBuilder = RowViewBuilder { (value: Int) in
            Text("\(value)")
        }
        
        sut[stringBuilder.id] = stringBuilder
        sut[intBuilder.id] = intBuilder
        
        XCTAssertEqual(sut.identifiers.count, 2, "Should have 2 identifiers")
    }
    
    func testBuilderOverwrite() {
        let builder1 = RowViewBuilder { (value: String) in
            Text(value)
        }
        let builder2 = RowViewBuilder { (value: String) in
            Text("Override: \(value)")
        }
        
        sut[builder1.id] = builder1
        sut[builder2.id] = builder2
        
        // Same type should overwrite
        XCTAssertEqual(sut.identifiers.count, 1, "Should only have 1 identifier for same type")
    }
    
    // MARK: - Cache Tests
    
    func testCacheHit() {
        let builder = RowViewBuilder { (value: String) in
            Text(value)
        }
        sut[builder.id] = builder
        
        let property = createMockProperty(value: "test")
        
        // First call - creates view and caches
        let view1 = sut.makeBody(property: property)
        XCTAssertNotNil(view1)
        
        // Second call - should hit cache
        let view2 = sut.makeBody(property: property)
        XCTAssertNotNil(view2)
        
        // Views should be cached (same instance)
        // Note: This is hard to verify without exposing cache internals
    }
    
    func testCacheMiss() {
        let builder = RowViewBuilder { (value: String) in
            Text(value)
        }
        sut[builder.id] = builder
        
        let property1 = createMockProperty(value: "test1")
        let property2 = createMockProperty(value: "test2")
        
        let view1 = sut.makeBody(property: property1)
        let view2 = sut.makeBody(property: property2)
        
        XCTAssertNotNil(view1)
        XCTAssertNotNil(view2)
    }
    
    func testTypeMismatch() {
        let stringBuilder = RowViewBuilder { (value: String) in
            Text(value)
        }
        sut[stringBuilder.id] = stringBuilder
        
        // Try to use with Int property
        let intProperty = createMockProperty(value: 42)
        let view = sut.makeBody(property: intProperty)
        
        XCTAssertNil(view, "Should return nil for type mismatch")
    }
    
    // MARK: - Merge Tests
    
    func testMerge() {
        let stringBuilder = RowViewBuilder { (value: String) in
            Text(value)
        }
        sut[stringBuilder.id] = stringBuilder
        
        var other = RowViewBuilderRegistry()
        let intBuilder = RowViewBuilder { (value: Int) in
            Text("\(value)")
        }
        other[intBuilder.id] = intBuilder
        
        sut.merge(other)
        
        XCTAssertEqual(sut.identifiers.count, 2, "Should have merged both builders")
    }
    
    func testMergeWithConflict() {
        let builder1 = RowViewBuilder { (value: String) in
            Text("First: \(value)")
        }
        sut[builder1.id] = builder1
        
        var other = RowViewBuilderRegistry()
        let builder2 = RowViewBuilder { (value: String) in
            Text("Second: \(value)")
        }
        other[builder2.id] = builder2
        
        sut.merge(other)
        
        // Should keep the first builder (existing takes precedence)
        XCTAssertEqual(sut.identifiers.count, 1, "Conflict should result in single builder")
    }
    
    // MARK: - Helper Methods
    
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
