import XCTest
import Combine
@testable import PropertyInspector

/// Tests for Fix #1: Debouncing Implementation
/// Issue: Current implementation uses Just() which doesn't debounce
/// Expected: Should use debounce(for:scheduler:) on a real publisher
@MainActor
final class Fix1_DebouncingTests: XCTestCase {
    var sut: Context.Data!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        // Clear global cache before each test
        PropertyCache.shared.clearAll()
        sut = Context.Data()
        cancellables = []
    }
    
    override func tearDown() async throws {
        cancellables?.removeAll()
        cancellables = nil
        sut = nil
        PropertyCache.shared.clearAll()
    }
    
    // MARK: - Debouncing Behavior Tests (After Fix #1)
    
    /// After Fix #1: searchQuery changes are properly debounced
    func testSearchQueryDebounces() async throws {
        var updateCount = 0
        
        sut.$properties
            .dropFirst() // Skip initial value
            .sink { _ in
                updateCount += 1
            }
            .store(in: &cancellables)
        
        // Rapid changes - should be debounced to single update
        sut.searchQuery = "a"
        sut.searchQuery = "ab"
        sut.searchQuery = "abc"
        
        // Wait briefly (less than debounce interval)
        try await Task.sleep(for: .milliseconds(50))
        
        // No updates yet (debouncing in effect)
        XCTAssertEqual(updateCount, 0, "Should debounce - no immediate updates")
        
        // Wait for debounce to complete (300ms + buffer)
        try await Task.sleep(for: .milliseconds(350))
        
        // Only 1 update after debounce
        XCTAssertEqual(updateCount, 1, "Should fire once after debounce interval")
    }
    
    // MARK: - Expected Behavior Tests
    
    /// After fix: Should debounce rapid changes and only fire once
    func testExpected_SearchDebounces() async throws {
        var updateCount = 0
        let expectation = XCTestExpectation(description: "Debounced update")
        
        sut.$properties
            .dropFirst() // Skip initial value
            .sink { _ in
                updateCount += 1
                if updateCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Rapid changes - should be debounced
        sut.searchQuery = "a"
        try await Task.sleep(for: .milliseconds(50))
        sut.searchQuery = "ab"
        try await Task.sleep(for: .milliseconds(50))
        sut.searchQuery = "abc"
        
        // Wait for debounce period (300ms as per Apple's docs)
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // After fix: Should only fire once
        XCTAssertEqual(updateCount, 1, "After fix: Should debounce to single update")
    }
    
    /// After fix: Debounce interval should match Apple's recommendation (300ms)
    func testExpected_DebounceInterval() async throws {
        let startTime = Date()
        var updateTime: Date?
        let expectation = XCTestExpectation(description: "Debounce timing")
        
        sut.$properties
            .dropFirst()
            .sink { _ in
                updateTime = Date()
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Single change
        sut.searchQuery = "test"
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        if let updateTime = updateTime {
            let elapsed = updateTime.timeIntervalSince(startTime)
            // Should wait ~300ms before firing
            XCTAssertGreaterThanOrEqual(elapsed, 0.3, "Should wait at least 300ms")
            XCTAssertLessThan(elapsed, 0.5, "Should not wait too long")
        } else {
            XCTFail("Update never fired")
        }
    }
    
    /// After fix: Multiple rapid changes should only result in one final update
    func testExpected_RapidFireDebouncing() async throws {
        var finalQuery: String = ""
        let expectation = XCTestExpectation(description: "Final query")
        
        sut.$properties
            .dropFirst()
            .sink { _ in
                finalQuery = self.sut.searchQuery
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Rapid fire - only last value should propagate
        let queries = ["a", "ab", "abc", "abcd", "abcde"]
        for query in queries {
            sut.searchQuery = query
            try await Task.sleep(for: .milliseconds(50))
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(finalQuery, "abcde", "Should process final value only")
    }
    
    // MARK: - Edge Cases
    
    /// Empty query should still debounce
    func testEmptyQueryDebounces() async throws {
        var updateCount = 0
        let expectation = XCTestExpectation(description: "Empty query debounce")
        
        sut.$properties
            .dropFirst()
            .sink { _ in
                updateCount += 1
                if updateCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Set some queries then clear
        sut.searchQuery = "test"
        try await Task.sleep(for: .milliseconds(50))
        sut.searchQuery = ""
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(updateCount, 1, "Empty query should still debounce")
    }
    
    /// Identical queries should be deduplicated
    func testIdenticalQueriesDeduped() async throws {
        var updateCount = 0
        
        sut.$properties
            .dropFirst()
            .sink { _ in
                updateCount += 1
            }
            .store(in: &cancellables)
        
        // Set same query multiple times
        sut.searchQuery = "test"
        try await Task.sleep(for: .milliseconds(50))
        sut.searchQuery = "test"
        try await Task.sleep(for: .milliseconds(50))
        sut.searchQuery = "test"
        
        try await Task.sleep(for: .milliseconds(400))
        
        // Should only fire once (removeDuplicates should work)
        XCTAssertEqual(updateCount, 1, "Identical queries should be deduplicated")
    }
    
    // MARK: - Performance Impact Tests
    
    /// Measure search performance with debouncing
    func testSearchPerformanceWithDebouncing() async throws {
        // Create large dataset
        let mockProperties = createMockProperties(count: 1000)
        sut.allObjects = mockProperties
        
        measure {
            // Rapid changes - should be debounced
            for i in 0..<100 {
                sut.searchQuery = "query\(i)"
            }
        }
        
        // After fix: Should be significantly faster due to debouncing
        // Baseline: ~100 expensive search operations
        // After fix: ~1-5 search operations (depending on timing)
    }
    
    // MARK: - Helper Methods
    
    private func createMockProperties(count: Int) -> [PropertyType: Set<Property>] {
        var result = [PropertyType: Set<Property>]()
        
        for i in 0..<count {
            let location = PropertyLocation(
                function: "testFunc",
                file: "test.swift",
                line: i
            )
            let value = PropertyValue(i)
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
