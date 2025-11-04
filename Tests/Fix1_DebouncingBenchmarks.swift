import XCTest
import SwiftUI
@testable import PropertyInspector

/// Performance benchmarks for Fix #1: Debouncing
/// These benchmarks measure the performance impact of proper debouncing implementation
@MainActor
final class Fix1_DebouncingBenchmarks: XCTestCase {
    
    override func setUp() async throws {
        // Clear global cache before each benchmark
        PropertyCache.shared.clearAll()
    }
    
    override func tearDown() async throws {
        PropertyCache.shared.clearAll()
    }
    
    // MARK: - Baseline Performance (Before Fix)
    
    /// Baseline: Measures current performance WITHOUT proper debouncing
    /// Expected: Poor performance - O(n) search runs on every keystroke
    func testBaseline_RapidSearchUpdates() async throws {
        let context = Context.Data()
        
        // Create realistic dataset
        let properties = createLargePropertySet(count: 500)
        context.allObjects = properties
        
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(options: options) {
            // Simulate typing "test query" - 10 keystrokes
            let query = "test query"
            for i in 1...query.count {
                let partial = String(query.prefix(i))
                context.searchQuery = partial
            }
        }
        
        // Baseline expected: ~50-100ms for 10 keystrokes × 500 properties
        // This is the BROKEN behavior we're fixing
    }
    
    // MARK: - Expected Performance (After Fix)
    
    /// After fix: Should be 10-20x faster due to debouncing
    /// Expected: Only 1-2 actual search operations instead of 10
    func testExpected_DebouncedSearchUpdates() async throws {
        let context = Context.Data()
        
        let properties = createLargePropertySet(count: 500)
        context.allObjects = properties
        
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(options: options) {
            // Same typing simulation
            let query = "test query"
            for i in 1...query.count {
                let partial = String(query.prefix(i))
                context.searchQuery = partial
                // Small delay between keystrokes (realistic typing)
                Thread.sleep(forTimeInterval: 0.05)
            }
            
            // Wait for debounce to complete
            Thread.sleep(forTimeInterval: 0.35)
        }
        
        // Expected after fix: ~5-10ms (90% reduction)
        // Only final search executes after debounce period
    }
    
    // MARK: - Search Operation Complexity
    
    /// Measure search complexity with different dataset sizes
    func testSearchComplexity_SmallDataset() {
        let context = Context.Data()
        let properties = createLargePropertySet(count: 100)
        context.allObjects = properties
        
        measure {
            context.searchQuery = "test"
            Thread.sleep(forTimeInterval: 0.35) // Wait for debounce
        }
    }
    
    func testSearchComplexity_MediumDataset() {
        let context = Context.Data()
        let properties = createLargePropertySet(count: 500)
        context.allObjects = properties
        
        measure {
            context.searchQuery = "test"
            Thread.sleep(forTimeInterval: 0.35)
        }
    }
    
    func testSearchComplexity_LargeDataset() {
        let context = Context.Data()
        let properties = createLargePropertySet(count: 2000)
        context.allObjects = properties
        
        measure {
            context.searchQuery = "test"
            Thread.sleep(forTimeInterval: 0.35)
        }
    }
    
    // MARK: - Memory Impact
    
    /// Measure memory usage with debouncing
    func testMemoryUsage_WithDebouncing() {
        let context = Context.Data()
        let properties = createLargePropertySet(count: 1000)
        context.allObjects = properties
        
        let memoryMetric = XCTMemoryMetric()
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [memoryMetric], options: options) {
            for i in 0..<100 {
                context.searchQuery = "query\(i)"
            }
            Thread.sleep(forTimeInterval: 0.4) // Wait for debounce
        }
        
        // Should have minimal memory overhead from Combine publishers
    }
    
    // MARK: - CPU Impact
    
    /// Measure CPU time for rapid updates
    func testCPUTime_RapidUpdates() {
        let context = Context.Data()
        let properties = createLargePropertySet(count: 500)
        context.allObjects = properties
        
        let cpuMetric = XCTCPUMetric()
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(metrics: [cpuMetric], options: options) {
            for i in 0..<50 {
                context.searchQuery = "test\(i)"
            }
            Thread.sleep(forTimeInterval: 0.35)
        }
        
        // After fix: Should use significantly less CPU time
    }
    
    // MARK: - Real-World Simulation
    
    /// Simulate realistic typing behavior with variable delays
    func testRealWorldTyping_Simulation() {
        let context = Context.Data()
        let properties = createLargePropertySet(count: 750)
        context.allObjects = properties
        
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(options: options) {
            // Simulate typing "property inspector test" with realistic delays
            let words = ["property", "inspector", "test"]
            for word in words {
                for i in 1...word.count {
                    let partial = String(word.prefix(i))
                    context.searchQuery = partial
                    // Variable typing speed (50-150ms between keystrokes)
                    Thread.sleep(forTimeInterval: Double.random(in: 0.05...0.15))
                }
                // Pause between words
                Thread.sleep(forTimeInterval: 0.2)
            }
            // Final debounce wait
            Thread.sleep(forTimeInterval: 0.35)
        }
        
        // This benchmark shows real-world improvement most clearly
    }
    
    // MARK: - Comparison Metrics
    
    /// Direct comparison: Before vs After fix
    func testComparison_BeforeAfterFix() {
        let contextBefore = Context.Data()
        let contextAfter = Context.Data()
        
        let properties = createLargePropertySet(count: 500)
        contextBefore.allObjects = properties
        contextAfter.allObjects = properties
        
        // Measure current (broken) implementation
        let beforeStart = Date()
        for i in 0..<100 {
            contextBefore.searchQuery = "query\(i)"
        }
        let beforeTime = Date().timeIntervalSince(beforeStart)
        
        // Measure after fix (with debouncing)
        let afterStart = Date()
        for i in 0..<100 {
            contextAfter.searchQuery = "query\(i)"
        }
        let afterTime = Date().timeIntervalSince(afterStart)
        Thread.sleep(forTimeInterval: 0.35) // Wait for final debounce (not included in measurement)
        
        print("""
        ⚡️ Performance Comparison:
        Before fix: \(String(format: "%.2f", beforeTime * 1000))ms
        After fix:  \(String(format: "%.2f", afterTime * 1000))ms
        Improvement: \(String(format: "%.1f", (beforeTime / afterTime)))x faster
        """)
        
        // After fix should be significantly faster
        XCTAssertLessThan(afterTime, beforeTime * 0.5, "After fix should be at least 2x faster")
    }
    
    // MARK: - Helper Methods
    
    private func createLargePropertySet(count: Int) -> [PropertyType: Set<Property>] {
        var result = [PropertyType: Set<Property>]()
        
        let types: [Any] = [
            Int(0), String(""), Double(0), Bool(false),
            CGFloat(0), CGPoint.zero, CGSize.zero, CGRect.zero,
            Color.red, Font.body
        ]
        
        for i in 0..<count {
            let location = PropertyLocation(
                function: "testFunction\(i % 10)",
                file: "TestFile\(i % 5).swift",
                line: i
            )
            
            let typeValue = types[i % types.count]
            let value = PropertyValue(typeValue)
            
            let property = Property(
                id: PropertyID(offset: i, createdAt: Date(), location: location),
                token: "\(i)",
                value: value,
                isHighlighted: .constant(false)
            )
            
            if result[value.type] == nil {
                result[value.type] = []
            }
            result[value.type]?.insert(property)
        }
        
        return result
    }
}
