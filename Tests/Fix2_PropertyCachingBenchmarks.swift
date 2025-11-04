import XCTest
import SwiftUI
@testable import PropertyInspector

/// Performance benchmarks for Fix #2: Property Caching
/// 
/// Measures the performance improvement from using PropertyCache to reuse Property objects
/// instead of recreating them on every view body update.
/// Baseline: Without caching (creating new Property objects each time)
/// Optimized: With PropertyCache (reusing cached instances)
///
/// **Updated:** Now benchmarks the global @MainActor singleton pattern
@MainActor
final class Fix2_PropertyCachingBenchmarks: XCTestCase {
    
    override func setUp() async throws {
        // Clear cache before each benchmark
        PropertyCache.shared.clearAll()
    }
    
    // MARK: - Single Property Benchmarks
    
    func testBaseline_SinglePropertyWithoutCache() {
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value = PropertyValue( 42)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate 1000 view body updates WITHOUT caching
            for _ in 0..<1000 {
                _ = Property(id: id, token: 42, value: value, isHighlighted: isHighlighted)
            }
        }
    }
    
    func testOptimized_SinglePropertyWithCache() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let value = PropertyValue( 42)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate 1000 view body updates WITH caching
            for _ in 0..<1000 {
                _ = cache.property(for: id, token: 42, value: value, isHighlighted: isHighlighted)
            }
        }
    }
    
    // MARK: - Multiple Properties Benchmarks
    
    func testBaseline_MultiplePropertiesWithoutCache() {
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate 100 view body updates with 10 properties each
            for _ in 0..<100 {
                for offset in 0..<10 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( offset * 10)
                    _ = Property(id: id, token: offset * 10, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
    
    func testOptimized_MultiplePropertiesWithCache() {
        let cache = PropertyCache.shared
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate 100 view body updates with 10 properties each
            for _ in 0..<100 {
                for offset in 0..<10 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( offset * 10)
                    _ = cache.property(for: id, token: offset * 10, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
    
    // MARK: - Realistic View Update Benchmarks
    
    func testBaseline_RealisticViewUpdatesWithoutCache() {
        let location = PropertyLocation(function: "testView", file: "TestView.swift", line: 10)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate realistic scenario: View with 5 properties, updating 200 times
            for _ in 0..<200 {
                for offset in 0..<5 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( ["title", "count", "isActive", "progress", "message"][offset])
                    let token = String(describing: value.rawValue).hashValue
                    _ = Property(id: id, token: token, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
    
    func testOptimized_RealisticViewUpdatesWithCache() {
        let cache = PropertyCache.shared
        let location = PropertyLocation(function: "testView", file: "TestView.swift", line: 10)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate realistic scenario: View with 5 properties, updating 200 times
            for _ in 0..<200 {
                for offset in 0..<5 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( ["title", "count", "isActive", "progress", "message"][offset])
                    let token = String(describing: value.rawValue).hashValue
                    _ = cache.property(for: id, token: token, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
    
    // MARK: - Token Change Benchmarks
    
    func testBaseline_FrequentValueChangesWithoutCache() {
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate value changing frequently (e.g., counter, timer)
            for i in 0..<1000 {
                let value = PropertyValue( i)
                _ = Property(id: id, token: i, value: value, isHighlighted: isHighlighted)
            }
        }
    }
    
    func testOptimized_FrequentValueChangesWithCache() {
        let cache = PropertyCache.shared
        let id = PropertyID(offset: 0, createdAt: Date(), location: PropertyLocation(function: "test", file: "test", line: 1))
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate value changing frequently (e.g., counter, timer)
            for i in 0..<1000 {
                let value = PropertyValue( i)
                _ = cache.property(for: id, token: i, value: value, isHighlighted: isHighlighted)
            }
        }
    }
    
    // MARK: - Mixed Scenario Benchmarks
    
    func testBaseline_MixedStableAndChangingWithoutCache() {
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate 100 updates with 3 stable properties and 2 changing properties
            for updateIndex in 0..<100 {
                // 3 stable properties (title, label, color)
                for offset in 0..<3 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( "stable_\(offset)")
                    let token = String(describing: value.rawValue).hashValue
                    _ = Property(id: id, token: token, value: value, isHighlighted: isHighlighted)
                }
                
                // 2 changing properties (count, progress)
                for offset in 3..<5 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( updateIndex * (offset - 2))
                    let token = String(describing: value.rawValue).hashValue
                    _ = Property(id: id, token: token, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
    
    func testOptimized_MixedStableAndChangingWithCache() {
        let cache = PropertyCache.shared
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate 100 updates with 3 stable properties and 2 changing properties
            for updateIndex in 0..<100 {
                // 3 stable properties (title, label, color) - these should be cached
                for offset in 0..<3 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( "stable_\(offset)")
                    let token = String(describing: value.rawValue).hashValue
                    _ = cache.property(for: id, token: token, value: value, isHighlighted: isHighlighted)
                }
                
                // 2 changing properties (count, progress) - these get updated
                for offset in 3..<5 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( updateIndex * (offset - 2))
                    let token = String(describing: value.rawValue).hashValue
                    _ = cache.property(for: id, token: token, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
    
    // MARK: - Large Property Collection Benchmarks
    
    func testBaseline_LargePropertyCollectionWithoutCache() {
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate complex view with 50 properties, updating 20 times
            for _ in 0..<20 {
                for offset in 0..<50 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( "property_\(offset)")
                    let token = String(describing: value.rawValue).hashValue
                    _ = Property(id: id, token: token, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
    
    func testOptimized_LargePropertyCollectionWithCache() {
        let cache = PropertyCache.shared
        let location = PropertyLocation(function: "test", file: "test", line: 1)
        let isHighlighted = Binding.constant(false)
        
        measure {
            // Simulate complex view with 50 properties, updating 20 times
            for _ in 0..<20 {
                for offset in 0..<50 {
                    let id = PropertyID(offset: offset, createdAt: Date(), location: location)
                    let value = PropertyValue( "property_\(offset)")
                    let token = String(describing: value.rawValue).hashValue
                    _ = cache.property(for: id, token: token, value: value, isHighlighted: isHighlighted)
                }
            }
        }
    }
}
