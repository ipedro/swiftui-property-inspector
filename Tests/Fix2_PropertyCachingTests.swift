import Testing
import SwiftUI
@testable import PropertyInspector

/// Tests for Fix #2: Property Caching implementation
/// 
/// Verifies that PropertyCache correctly reuses Property objects instead of recreating them
/// on every view body update, following Apple's pattern from WWDC2025-306.
///
/// **Updated:** Now tests the global @MainActor singleton pattern using Swift Testing
@MainActor
@Suite("Property Caching")
struct PropertyCachingTests {
    
    init() {
        // Clear cache before each test to ensure isolation
        PropertyCache.shared.clearAll()
    }
    
    // MARK: - Property Reuse Tests
    
    @Test("Reuses property instance for same ID and token")
    func reusesInstanceForSameID() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value = PropertyValue(42)
        let isHighlighted = Binding.constant(false)
        
        let property1 = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        let property2 = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        
        // Should return THE SAME instance (reference equality)
        #expect(property1 === property2, "PropertyCache should reuse the same Property instance for identical ID+token")
    }
    
    @Test("Creates new property instance for different ID")
    func createsNewInstanceForDifferentID() {
        let cache = PropertyCache.shared
        let id1 = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let id2 = PropertyID(offset: 1, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value = PropertyValue(42)
        let isHighlighted = Binding.constant(false)
        
        let property1 = cache.property(for: id1, token: 42, value: value, isHighlighted: isHighlighted)
        let property2 = cache.property(for: id2, token: 42, value: value, isHighlighted: isHighlighted)
        
        // Should return DIFFERENT instances (different IDs)
        #expect(property1 !== property2, "PropertyCache should create different Property instances for different IDs")
    }
    
    @Test("Creates new property instance when token changes")
    func createsNewInstanceForDifferentToken() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value1 = PropertyValue(42)
        let value2 = PropertyValue(100)
        let isHighlighted = Binding.constant(false)
        
        let property1 = cache.property(for: id, token: 42, value: value1, isHighlighted: isHighlighted)
        let property2 = cache.property(for: id, token: 100, value: value2, isHighlighted: isHighlighted)
        
        // Should return DIFFERENT instances (token changed = value changed)
        #expect(property1 !== property2, "PropertyCache should create new Property instance when token changes")
    }
    
    // MARK: - Property Updates Tests
    
    @Test("Updates property value when token changes")
    func updatesValueWhenTokenChanges() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value1 = PropertyValue(42)
        let value2 = PropertyValue(100)
        let isHighlighted = Binding.constant(false)
        
        let property1 = cache.property(for: id, token: 42, value: value1, isHighlighted: isHighlighted)
        let property2 = cache.property(for: id, token: 100, value: value2, isHighlighted: isHighlighted)
        
        // Should update to new value
        #expect(property1.value.rawValue as? Int == 42)
        #expect(property2.value.rawValue as? Int == 100)
    }
    
    @Test("Maintains property value when token stays same")
    func maintainsValueWhenTokenSame() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value = PropertyValue(42)
        let isHighlighted = Binding.constant(false)
        
        let property1 = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        
        // Call multiple times with same token
        _ = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        _ = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        _ = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        
        let property2 = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        
        // Should maintain same instance and value
        #expect(property1 === property2)
        #expect(property2.value.rawValue as? Int == 42)
    }
    
    // MARK: - Multiple Properties Tests
    
    @Test("Manages multiple properties efficiently")
    func managesMultipleProperties() {
        let cache = PropertyCache.shared
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        // Create PropertyID instances ONCE (they need to be the same instances for caching)
        let ids = (0..<10).map { offset in
            PropertyID(offset: offset, createdAt: Date(), location: location)
        }
        
        // Create 10 different properties
        let properties = ids.map { id in
            let offset = ids.firstIndex(where: { $0 === id })!
            let value = PropertyValue(offset * 10)
            return cache.property(for: id, token: offset * 10, value: value, isHighlighted: isHighlighted)
        }
        
        // Request them again with SAME PropertyID instances - should get same Property instances
        let cachedProperties = ids.map { id in
            let offset = ids.firstIndex(where: { $0 === id })!
            let value = PropertyValue(offset * 10)
            return cache.property(for: id, token: offset * 10, value: value, isHighlighted: isHighlighted)
        }
        
        // Verify all are reused
        for (original, cached) in zip(properties, cachedProperties) {
            #expect(original === cached, "PropertyCache should reuse all properties")
        }
    }
    
    // MARK: - Highlight Binding Tests
    
    @Test("Shares highlight binding across property instances")
    func sharesHighlightBinding() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value = PropertyValue(42)
        let isHighlighted = Binding.constant(false)
        
        let property1 = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        let property2 = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        
        // Should share same binding
        #expect(property1 === property2)
        #expect(property1.isHighlighted == property2.isHighlighted)
    }
    
    // MARK: - Thread Safety Tests
    
    @Test("Handles concurrent access safely with MainActor isolation")
    func threadSafe() async {
        let cache = PropertyCache.shared
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        // Simulate concurrent access from multiple view updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask { @MainActor in
                    let id = PropertyID(offset: i % 10, createdAt: Date(), location: location)
                    let value = PropertyValue(i)
                    _ = cache.property(for: id, token: i, value: value, isHighlighted: isHighlighted)
                }
            }
        }
        
        // If we reach here without crashes, thread safety is working
        // No assertion needed - test passes by completing successfully
    }
    
    // MARK: - Expected Behavior Tests
    
    @Test("Cache reduces property creation by 99% for stable values")
    func cacheReducesPropertyCreation() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value = PropertyValue(42)
        let isHighlighted = Binding.constant(false)
        
        // First call creates
        let property1 = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
        
        // Subsequent 99 calls should reuse (simulating 100 view body updates)
        var allSameInstance = true
        for _ in 0..<99 {
            let property = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
            if property !== property1 {
                allSameInstance = false
                break
            }
        }
        
        #expect(allSameInstance, "PropertyCache should reuse same instance across 100 body updates (99% reduction)")
    }
    
    @Test("Token-based invalidation creates new instances only when values change")
    func tokenBasedInvalidation() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let isHighlighted = Binding.constant(false)
        
        // Create property with token 1
        let property1 = cache.property(for: id, token: 1, value: PropertyValue("A"), isHighlighted: isHighlighted)
        
        // Reuse with same token (10 times)
        for _ in 0..<10 {
            let property = cache.property(for: id, token: 1, value: PropertyValue("A"), isHighlighted: isHighlighted)
            #expect(property === property1, "Should reuse with same token")
        }
        
        // Change token (value changed)
        let property2 = cache.property(for: id, token: 2, value: PropertyValue("B"), isHighlighted: isHighlighted)
        #expect(property2 !== property1, "Should create new instance when token changes")
        
        // Reuse with new token (10 times)
        for _ in 0..<10 {
            let property = cache.property(for: id, token: 2, value: PropertyValue("B"), isHighlighted: isHighlighted)
            #expect(property === property2, "Should reuse with new token")
        }
    }
}
