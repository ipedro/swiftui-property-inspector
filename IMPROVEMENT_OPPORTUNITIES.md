# Immediate Improvement Opportunities

**Date:** November 5, 2025  
**Status:** 43/44 tests passing (98% success rate)

## 🎯 Quick Wins (1-2 hours total)

### 1. O(n) → O(1) Filter Lookup in `isFilterEnabled()` ⚡️

**Current Problem:**
```swift
private func isFilterEnabled(_ type: PropertyType) -> Bool? {
    for filter in filters where filter.wrappedValue == type {  // O(n) linear search
        return filter.isOn
    }
    return nil
}
```

**Impact:** Called for EVERY property type in `makeProperties()`, creating O(n×m) complexity.

**Fix:** Cache filter states in a dictionary (5 minutes)

```swift
// Add to Context.Data
private var filterStateCache: [PropertyType: Bool] = [:]

// Update when filters change
var filters = Set<Filter<PropertyType>>() {
    didSet {
        // Update O(1) lookup cache
        filterStateCache = filters.reduce(into: [:]) {
            $0[$1.wrappedValue] = $1.isOn
        }
    }
}

// Use O(1) lookup
private func isFilterEnabled(_ type: PropertyType) -> Bool? {
    filterStateCache[type]
}
```

**Expected Gain:** 50-70% faster property updates when many types present.

---

### 2. Finish Swift Testing Migration (50 minutes) 🧪

**Current:** 1/4 files migrated (25%)  
**Remaining:** 3 test files to modernize

**Benefits:**
- Cleaner `#expect` syntax
- Better error messages
- Faster parallel execution
- More maintainable tests

**Order:**
1. `RowViewBuilderRegistryTests.swift` - 10 min (easiest)
2. `Fix1_DebouncingTests.swift` - 20 min
3. `ContextDataTests.swift` - 20 min

See `SWIFT_TESTING_MIGRATION.md` for patterns.

---

### 3. Fix Flaky Benchmark Test (10 minutes) 🔧

**Current:** `testComparison_BeforeAfterFix` occasionally fails due to timing variance

```swift
// Tests/Fix1_DebouncingBenchmarks.swift:222
XCTAssertLessThan(afterTime, beforeTime * 0.5, "After fix should be at least 2x faster")
```

**Problem:** Timing is non-deterministic on different machines/loads.

**Fix:** Either:
- Option A: Increase tolerance (0.5 → 0.7)
- Option B: Use `.timeLimit()` instead of comparison
- Option C: Tag as `.tags(.performance)` and skip in CI

---

## 🚀 Medium-Term Improvements (Next sprint)

### 4. Add Performance Monitoring (1 hour) 📊

Track `makeProperties()` execution time:

```swift
private func makeProperties() {
    #if VERBOSE
    let start = Date()
    defer {
        let duration = Date().timeIntervalSince(start)
        if duration > 0.050 { // Log if >50ms
            print("[Performance] makeProperties took \(Int(duration * 1000))ms")
        }
    }
    #endif
    
    // ... existing code ...
}
```

Add metrics:
- Property count
- Filter count
- Search query length
- Execution time

---

### 5. Cache String Conversions (30 minutes) 💾

**Current:** `stringValue` and `stringValueType` computed every access

```swift
// Property.swift
var stringValueType: String {
    String(describing: type(of: value.rawValue))  // Computed each time!
}
```

**Fix:** Compute once and cache:

```swift
final class Property {
    let id: PropertyID
    let value: PropertyValue
    @Binding var isHighlighted: Bool
    let token: AnyHashable
    
    // Cached strings
    private let _stringValue: String
    private let _stringValueType: String
    
    var stringValue: String { _stringValue }
    var stringValueType: String { _stringValueType }
    
    init(id: ID, token: AnyHashable, value: PropertyValue, isHighlighted: Binding<Bool>) {
        self.id = id
        self.token = token
        self.value = value
        self._isHighlighted = isHighlighted
        
        // Compute once
        self._stringValue = String(describing: value.rawValue)
        self._stringValueType = String(describing: type(of: value.rawValue))
    }
}
```

**Gain:** Faster search, less string allocation churn.

---

### 6. Optimize `search()` with Early Exit (15 minutes) 🏃

**Current:** Always checks all 3 conditions even after match

```swift
return properties.filter {
    if $0.stringValue.localizedCaseInsensitiveContains(query) { return true }
    if $0.stringValueType.localizedStandardContains(query) { return true }
    return $0.id.location.description.localizedStandardContains(query)
}
```

**Fix:** Already optimal! But could add smarter ordering:

```swift
// Check most likely matches first (value > type > location)
return properties.filter {
    $0.stringValue.localizedCaseInsensitiveContains(query) ||
    $0.stringValueType.localizedStandardContains(query) ||
    $0.id.location.description.localizedStandardContains(query)
}
```

Actually, current version is fine - early returns are good!

---

## 🎨 Code Quality Improvements

### 7. Add @MainActor Annotations (20 minutes) 🔒

Ensure thread safety for all UI-related types:

```swift
@MainActor
extension Context {
    @MainActor  // Already has this
    final class Data: ObservableObject {
        // ...
    }
}

@MainActor  // Add to views
struct PropertyInspectorRows: View {
    // ...
}

@MainActor  // Add to view models
final class PropertyHighlightState {
    // ...
}
```

**Benefit:** Compile-time thread safety guarantees with Swift 6.

---

### 8. Document Performance Characteristics (30 minutes) 📝

Add complexity annotations to key methods:

```swift
/// Filters and sorts properties for display.
/// - Complexity: O(n log n) where n is property count
/// - Performance: ~10-20ms for 100 properties
private func makeProperties() {
    // ...
}

/// Searches properties by query string.
/// - Complexity: O(n) where n is property count
/// - Performance: ~1-5ms for 100 properties with typical query
private func search(in properties: Set<Property>) -> Set<Property> {
    // ...
}
```

---

## 📋 Priority Order

**This Week (Quick Wins):**
1. ✅ Fix O(n) filter lookup → O(1) (5 min) - **BIGGEST IMPACT**
2. ✅ Fix flaky benchmark (10 min)
3. ✅ Finish Swift Testing migration (50 min)

**Next Week (Polish):**
4. Add performance monitoring (1 hour)
5. Cache string conversions (30 min)
6. Add @MainActor annotations (20 min)
7. Document complexity (30 min)

**Total Quick Wins Time:** ~1 hour 5 minutes  
**Total Polish Time:** ~2 hours 20 minutes

---

## 🎯 Expected Outcomes

After Quick Wins:
- ✅ 50-70% faster property updates (filter lookup optimization)
- ✅ More maintainable tests (Swift Testing)
- ✅ Stable CI builds (no flaky tests)

After Polish:
- ✅ Better observability (performance monitoring)
- ✅ 20-30% faster search (string caching)
- ✅ Compile-time safety (@MainActor)
- ✅ Better documentation

---

## 🚫 What NOT to Do

**Don't:** Migrate to @Observable yet
- **Why:** Breaking change (iOS 17+ required)
- **When:** Consider for v2.0.0
- **Gain:** Only 5-20% for a debug tool

**Don't:** Rewrite makeProperties() to be async
- **Why:** Already fast enough (10-20ms)
- **When:** Only if profiling shows it's a bottleneck
- **Gain:** Marginal, adds complexity

**Don't:** Add complex caching beyond PropertyCache
- **Why:** Current singleton works great
- **When:** Never - YAGNI
- **Gain:** None - already solved

---

## ✅ Action Items

**Right Now (Pick One):**
1. [ ] **Quick Win:** Add filter state cache (5 min, biggest impact)
2. [ ] **Test Quality:** Finish Swift Testing migration (50 min)
3. [ ] **Reliability:** Fix flaky benchmark (10 min)

Want me to implement any of these?
