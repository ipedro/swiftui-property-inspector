# Swift Testing Migration Guide

**Status:** Partial migration complete  
**Migrated:** 1/4 test files (+ all benchmarks staying with XCTest)

## Why Swift Testing?

Modern testing framework with better syntax and features:
- ✅ `#expect` instead of `XCTAssert*` - cleaner, more expressive
- ✅ `@Test("description")` - test names as display strings
- ✅ `@Suite` - better organization and grouping
- ✅ Struct-based tests - simpler than class-based XCTest
- ✅ Better parallel execution support
- ✅ More readable error messages

## Migration Pattern

### 1. Import & Structure Change

**Before (XCTest):**
```swift
import XCTest
@testable import PropertyInspector

@MainActor
final class MyTests: XCTestCase {
    var sut: MyType!
    
    override func setUp() async throws {
        sut = MyType()
    }
    
    override func tearDown() async throws {
        sut = nil
    }
```

**After (Swift Testing):**
```swift
import Testing
@testable import PropertyInspector

@MainActor
@Suite("My Test Suite")
struct MyTests {
    init() {
        // Setup code here (runs before each test)
        PropertyCache.shared.clearAll()
    }
    
    // For mutable SUT, create helper:
    func makeSUT() -> MyType {
        MyType()
    }
```

### 2. Test Function Changes

**Before:**
```swift
func testSomething() {
    XCTAssertEqual(value, 42)
    XCTAssertTrue(condition)
    XCTAssertNotNil(optional)
}
```

**After:**
```swift
@Test("Something works correctly")
func something() {  // Drop "test" prefix
    #expect(value == 42)
    #expect(condition)
    #expect(optional != nil)
}
```

### 3. Assertion Mapping

| XCTest | Swift Testing |
|--------|---------------|
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertNotEqual(a, b)` | `#expect(a != b)` |
| `XCTAssertTrue(condition)` | `#expect(condition)` |
| `XCTAssertFalse(condition)` | `#expect(!condition)` |
| `XCTAssertNil(value)` | `#expect(value == nil)` |
| `XCTAssertNotNil(value)` | `#expect(value != nil)` |
| `XCTAssertGreaterThan(a, b)` | `#expect(a > b)` |
| `XCTAssertLessThan(a, b)` | `#expect(a < b)` |
| `XCTAssert(a === b)` | `#expect(a === b)` |
| `XCTAssert(a !== b)` | `#expect(a !== b)` |

### 4. Async Tests

**Before:**
```swift
func testAsync() async throws {
    let expectation = XCTestExpectation(description: "completes")
    // ... async work
    await fulfillment(of: [expectation], timeout: 1.0)
}
```

**After:**
```swift
@Test("Async operation completes")
func asyncOperation() async throws {
    // Swift Testing handles async naturally
    let result = await someAsyncFunction()
    #expect(result.isValid)
}
```

### 5. Parametrized Tests (Bonus!)

Swift Testing supports parametrized tests natively:

```swift
@Test("Property cache works with various types", arguments: [
    42,
    "hello",
    true,
    3.14
])
func cacheWorksWithType<T>(value: T) {
    let property = PropertyValue(value)
    #expect(property.rawValue as? T == value)
}
```

## Migration Status

### ✅ Migrated Files

1. **Fix2_PropertyCachingTests.swift** (10 tests)
   - All assertions converted to `#expect`
   - Struct-based with init() setup
   - Test names as display strings
   - All passing ✓

### ⏳ Pending Migration

2. **ContextDataTests.swift** (8 tests)
   - Needs: Combine publisher testing patterns
   - Needs: Async expectation conversion
   - Complexity: Medium (has debouncing tests)

3. **Fix1_DebouncingTests.swift** (7 tests)
   - Needs: Similar async patterns as ContextDataTests
   - Complexity: Medium

4. **RowViewBuilderRegistryTests.swift** (8 tests)
   - Needs: Mutable SUT pattern (use makeSUT() helper)
   - Complexity: Low (straightforward conversion)

### 🔒 Staying with XCTest

**All Benchmark Files:**
- Fix2_PropertyCachingBenchmarks.swift (12 benchmarks)
- Fix1_DebouncingBenchmarks.swift (9 benchmarks)

**Reason:** Swift Testing doesn't have `measure()` equivalent yet. XCTest's performance testing APIs are still the best tool for benchmarks.

## Example: Complete Migration

See `Tests/Fix2_PropertyCachingTests.swift` for a fully migrated example.

### Key Changes Made:
```swift
// 1. Import change
- import XCTest
+ import Testing

// 2. Class → Struct
- final class Fix2_PropertyCachingTests: XCTestCase {
+ @Suite("Property Caching")
+ struct PropertyCachingTests {

// 3. Setup change
-     override func setUp() async throws {
+     init() {
          PropertyCache.shared.clearAll()
-     }

// 4. Test function
-     func testPropertyCache_ReusesInstanceForSameID() {
+     @Test("Reuses property instance for same ID and token")
+     func reusesInstanceForSameID() {
          // ... test code ...
-         XCTAssertTrue(property1 === property2, "...")
+         #expect(property1 === property2, "...")
      }
```

## Running Tests

```bash
# Run all tests (including migrated Swift Testing tests)
swift test

# Run specific suite
swift test --filter PropertyCachingTests

# Run specific test
swift test --filter PropertyCachingTests.reusesInstanceForSameID

# List all tests
swift test list
```

## Benefits We're Seeing

1. **Cleaner Syntax:** `#expect(a == b)` reads better than `XCTAssertEqual(a, b)`
2. **Better Names:** Test names as strings mean we can use spaces and full descriptions
3. **Simpler Structure:** No need for class, setUp/tearDown split
4. **Better Errors:** Swift Testing gives more context when tests fail

## Next Steps

To complete migration:

1. **Migrate RowViewBuilderRegistryTests** (easiest)
   - Pattern: Use `makeSUT()` helper for mutable registry
   - Estimated time: 10 minutes

2. **Migrate Fix1_DebouncingTests** (medium)
   - Pattern: Convert XCTestExpectation to async/await
   - Estimated time: 20 minutes

3. **Migrate ContextDataTests** (medium)
   - Pattern: Similar to debouncing tests
   - Estimated time: 20 minutes

Total remaining effort: ~50 minutes

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [WWDC2023: Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2023/10179/)
- [Migration Guide](https://developer.apple.com/documentation/testing/migratingfromxctest)
