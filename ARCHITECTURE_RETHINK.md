# Architecture Rethinking - PropertyCache Design

## Current Problems

### 1. **Per-View Caches (Wrong!)**
```swift
// ❌ WRONG: Each view has its own cache
@State private var cache = PropertyCache()
```
- 10 views = 10 caches
- No sharing between views
- Defeats caching purpose

### 2. **NSLock in MainActor Context (Overkill)**
```swift
// ❌ OVERKILL: NSLock for single-threaded SwiftUI
private let lock = NSLock()
```
- All SwiftUI runs on @MainActor
- Lock overhead for no benefit
- Apple recommends actor isolation

### 3. **No Memory Management**
- Cache grows indefinitely
- Dead views leak PropertyIDs
- No pruning strategy

### 4. **Inefficient Token Generation**
```swift
// ❌ SLOW: Creates string just for hashing
token: String(describing: value.rawValue).hashValue
```

### 5. **Context.Data Ignores Cache**
- PropertyWriter caches at view level
- Context.Data recreates everything
- Two different property creation paths

---

## ✅ Proposed Solution

### **Option A: Global @MainActor Cache (Recommended)**

```swift
/// Global property cache - shared across all views
/// All access on @MainActor, no locking needed
@MainActor
final class PropertyCache {
    /// Singleton instance
    static let shared = PropertyCache()
    
    private init() {}
    
    /// Simple dictionary, no locking (MainActor serializes access)
    private var cache: [PropertyID: Property] = [:]
    
    /// Retrieves cached property or creates new one
    func property(
        for id: PropertyID,
        token: AnyHashable,
        value: PropertyValue,
        isHighlighted: Binding<Bool>
    ) -> Property {
        // Check cache with token
        if let cached = cache[id], cached.token == token {
            return cached // ✅ 99% case: reuse
        }
        
        // Create and cache
        let new = Property(id: id, token: token, value: value, isHighlighted: isHighlighted)
        cache[id] = new
        return new
    }
    
    /// Prune dead entries (call when views disappear)
    func prune(keeping activeIDs: Set<PropertyID>) {
        cache = cache.filter { activeIDs.contains($0.key) }
    }
    
    #if DEBUG
    var cacheSize: Int { cache.count }
    #endif
}
```

**Benefits:**
- ✅ Single cache, all views share
- ✅ No locks (MainActor serialization)
- ✅ Simple and fast
- ✅ Memory management via pruning

**Usage:**
```swift
// PropertyWriter.swift
let property = PropertyCache.shared.property(
    for: id,
    token: value.id.hashValue, // Use PropertyValueID.hashValue directly!
    value: value,
    isHighlighted: $isHighlighted
)
```

---

### **Option B: Environment-Injected Cache (More SwiftUI-ish)**

```swift
// Environment key
private struct PropertyCacheKey: EnvironmentKey {
    static let defaultValue = PropertyCache()
}

extension EnvironmentValues {
    var propertyCache: PropertyCache {
        get { self[PropertyCacheKey.self] }
        set { self[PropertyCacheKey.self] = newValue }
    }
}

// PropertyWriter.swift
struct PropertyWriter<S: Shape>: ViewModifier {
    @Environment(\.propertyCache) var cache // ✅ Injected, testable
    
    private var properties: [PropertyType: Set<Property>] {
        // ... use cache.property()
    }
}

// PropertyInspector creates cache once
struct PropertyInspector<Content: View>: View {
    @StateObject private var cache = PropertyCache() // ✅ One per inspector tree
    
    var body: some View {
        content
            .environment(\.propertyCache, cache)
    }
}
```

**Benefits:**
- ✅ One cache per inspector tree (not per view)
- ✅ Testable (inject mock cache)
- ✅ SwiftUI-idiomatic
- ✅ Scoped lifetime

---

### **Option C: Actor-Based Cache (Thread-Safe, Modern)**

```swift
/// Thread-safe cache using Swift Concurrency
actor PropertyCache {
    /// Singleton
    static let shared = PropertyCache()
    
    private var cache: [PropertyID: Property] = [:]
    
    func property(
        for id: PropertyID,
        token: AnyHashable,
        value: PropertyValue,
        isHighlighted: Binding<Bool>
    ) async -> Property {
        if let cached = cache[id], cached.token == token {
            return cached
        }
        
        let new = Property(id: id, token: token, value: value, isHighlighted: isHighlighted)
        cache[id] = new
        return new
    }
}
```

**Benefits:**
- ✅ True thread safety (Swift Concurrency)
- ✅ No manual locking
- ✅ Future-proof

**Drawbacks:**
- ❌ Requires `await` (async context)
- ❌ Not compatible with SwiftUI body (synchronous)

---

## Recommended Approach

**Use Option A (Global @MainActor Cache) because:**

1. **Simplest** - No locks, no complexity
2. **Fastest** - Direct dictionary access
3. **SwiftUI-compatible** - Synchronous API
4. **Single source of truth** - All views share one cache
5. **Easy to test** - Can reset cache between tests

### Implementation Changes

#### 1. Update PropertyCache.swift
```swift
import SwiftUI

@MainActor
final class PropertyCache {
    static let shared = PropertyCache()
    private init() {}
    
    private var cache: [PropertyID: Property] = [:]
    
    func property(
        for id: PropertyID,
        token: AnyHashable,
        value: PropertyValue,
        isHighlighted: Binding<Bool>
    ) -> Property {
        if let cached = cache[id], cached.token == token {
            return cached
        }
        
        let new = Property(id: id, token: token, value: value, isHighlighted: isHighlighted)
        cache[id] = new
        return new
    }
    
    func prune(keeping activeIDs: Set<PropertyID>) {
        cache = cache.filter { activeIDs.contains($0.key) }
    }
    
    #if DEBUG
    func clearAll() { cache.removeAll() }
    var cacheSize: Int { cache.count }
    #endif
}
```

#### 2. Update PropertyWriter.swift
```swift
struct PropertyWriter<S: Shape>: ViewModifier {
    // ❌ Remove this
    // @State private var cache = PropertyCache()
    
    private var properties: [PropertyType: Set<Property>] {
        // ✅ Use singleton
        let property = PropertyCache.shared.property(
            for: id,
            token: value.id.hashValue, // More efficient!
            value: value,
            isHighlighted: $isHighlighted
        )
    }
}
```

#### 3. Better Token Generation
```swift
// Instead of:
token: String(describing: value.rawValue).hashValue // ❌ Slow

// Use PropertyValueID directly:
token: value.id.hashValue // ✅ Fast (already computed in PropertyValue.init)
```

#### 4. Add Cache Pruning
```swift
// Context.Data.swift
func updateObjects(_ dict: [PropertyType: Set<Property>]) {
    _allObjects = dict
    
    // Prune dead entries
    let activeIDs = Set(dict.values.flatMap { $0.map(\.id) })
    PropertyCache.shared.prune(keeping: activeIDs)
    
    makeProperties()
}
```

---

## Performance Comparison

### Current (Per-View Cache)
- 10 views with 5 properties each
- 10 caches × 5 entries = 50 total cache entries
- Cache miss on first render of each view
- **Memory:** 50 Property objects

### Proposed (Global Cache)
- 10 views with 5 properties each
- 1 cache × 5 unique entries = 5 total cache entries
- Cache hit after first property creation
- **Memory:** 5 Property objects (90% reduction!)

---

## Testing Strategy

### Unit Tests
```swift
@MainActor
final class PropertyCacheTests: XCTestCase {
    override func setUp() {
        PropertyCache.shared.clearAll()
    }
    
    func testSharedInstanceAcrossViews() {
        let id = PropertyID(...)
        let value = PropertyValue(42)
        
        // First view creates property
        let prop1 = PropertyCache.shared.property(for: id, token: value.id.hashValue, ...)
        
        // Second view reuses same property
        let prop2 = PropertyCache.shared.property(for: id, token: value.id.hashValue, ...)
        
        XCTAssertTrue(prop1 === prop2) // ✅ Same instance
    }
}
```

---

## Migration Path

1. ✅ **Phase 1:** Update PropertyCache to @MainActor singleton
2. ✅ **Phase 2:** Update PropertyWriter to use singleton
3. ✅ **Phase 3:** Use PropertyValueID.hashValue for token (faster)
4. ✅ **Phase 4:** Add cache pruning in Context.Data
5. ✅ **Phase 5:** Update all tests
6. ✅ **Phase 6:** Measure performance improvement

---

## Questions to Consider

1. **Should Context.Data also use PropertyCache?**
   - Currently makeProperties() recreates Property objects
   - Could use cache for consistency
   - But Context.Data gets properties from PropertyWriter (already cached)

2. **Should we use Environment injection instead of singleton?**
   - Pros: More testable, scoped lifetime
   - Cons: More boilerplate, needs environment setup

3. **Do we need pruning, or is unbounded growth acceptable?**
   - Typical app: 10-100 properties max
   - Memory: ~1KB per Property
   - Unbounded: 100 properties = 100KB (negligible)
   - But good practice to prune on view disappearance

---

## Recommendation: **Implement Option A** 🎯

The global @MainActor singleton is the best fit because:
- ✅ Matches SwiftUI's MainActor execution model
- ✅ Zero overhead (no locks, no async)
- ✅ Maximum cache sharing across views
- ✅ Simple to implement and maintain
- ✅ Easy to test (clearAll() in setUp)

**This is the Apple-recommended pattern for SwiftUI state management.**
