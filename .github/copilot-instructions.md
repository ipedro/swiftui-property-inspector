# SwiftUI Property Inspector - AI Coding Instructions

## Project Overview
This is a **Swift Package Manager (SPM) library** for SwiftUI that provides runtime property inspection capabilities. The package uses a unique dual-mode architecture with automatic source concatenation for distribution.

## Critical Architecture: Dual-Mode Build System

### Development vs Distribution Structure
The package has TWO distinct build configurations controlled by `Package.swift`:

**Development Mode** (local development):
- Sources in `Development/` directory (modular structure)
- Multiple Swift files organized by feature
- SwiftLint plugin enabled with `.swiftlint.yml` config
- `VERBOSE` Swift compilation flag enabled for debug prints

**Distribution Mode** (when consumed as dependency):
- Single concatenated file: `PropertyInspector.swift` (2162 lines)
- Auto-generated on push to `main` via GitHub Actions (`.github/workflows/merge-sources.yml`)
- **NEVER edit `PropertyInspector.swift` directly** - it has `// auto-generated file, do not edit directly` header
- All edits must be made in `Development/` directory

### Build System Detection
```swift
let isDevelopment = !Context.packageDirectory.contains(".build/checkouts/") 
                   && !Context.packageDirectory.contains("SourcePackages/checkouts/")
```

## Core Architecture Patterns

### Property Collection via SwiftUI Preferences
The library uses SwiftUI's preference system to bubble property data up the view hierarchy:

1. **Property Writers** (`PropertyWriter` ViewModifier) attach property data to views via `.inspectProperty()`
2. **Preference Keys** (`PropertyPreferenceKey`, `RowIconPreferenceKey`, etc.) aggregate data from child views
3. **Context Modifier** (`Context.Data` ObservableObject) collects and publishes all property data
4. **Inspector Styles** consume the context to render property lists

**Key Data Flow:**
```
View.inspectProperty() → PropertyWriter → PreferenceKey → Context.Data → PropertyInspectorRows
```

### Type-Safe Property Registration System
Uses `RowViewBuilder` and `RowViewBuilderRegistry` for type-specific customization:

```swift
// Custom icon for Int properties
.propertyInspectorRowIcon(for: Int.self) { data in
    Image(systemName: "\(data).circle.fill")
}
```

The registry uses type erasure (`AnyView`) to store heterogeneous view builders indexed by `PropertyType`.

### Highlight Behavior & Linking
Multiple properties inspected together share highlight state:
```swift
.inspectProperty(style, tapCount) // Links these properties' highlights
```

This is implemented via shared `@Binding<Bool>` in `Property` class, coordinated by `PropertyHiglighter` ViewModifier.

## File Organization Conventions

### Development Directory Structure
- `Development/PropertyInspector.swift` - Main public API
- `Development/PropertyInspector+View.swift` - View extension methods
- `Development/Models/` - Core data models (Property, PropertyID, PropertyValue, etc.)
- `Development/ViewModifiers/` - SwiftUI modifiers (Context, PropertyWriter, PreferenceWriter)
- `Development/Styles/` - PropertyInspectorStyle implementations (Inline, List, Sheet)
- `Development/Environment/` - Environment keys and preference keys
- `Development/Views/` - Reusable view components
- `Development/Protocols/` - Protocol definitions
- `Examples/` - Demo app showing library usage

### Naming Conventions
- Internal protocols prefixed with underscore: `_PropertyInspectorStyle`
- Environment keys suffixed: `ViewInspectabilityKey`
- Preference keys suffixed: `PropertyPreferenceKey`
- Context nested types: `Context.Data`, `Context.Filter`

## Development Workflows

### Making Code Changes
1. **Always edit files in `Development/` directory**
2. Run SwiftLint locally (plugin runs automatically on build)
3. Test changes in development mode before pushing
4. On push to `main`, GitHub Actions automatically:
   - Concatenates all `Development/*.swift` files
   - Removes SwiftLint directives
   - Sorts and deduplicates imports
   - Prepends LICENSE as comments
   - Commits `PropertyInspector.swift`

### Testing During Development
- Use `Examples/Examples.swift` with `#Preview` for quick iteration
- Examples target depends on PropertyInspector target
- In dev mode, changes immediately reflect in examples

### Build Commands
```bash
# Build package
swift build

# Run tests (if defined)
swift test

# Build documentation (DocC hosted at GitHub Pages)
# See .github/workflows/generate-documentation.yml
```

## SwiftUI-Specific Patterns

### Conditional Compilation
Uses `#if VERBOSE` extensively for debug logging in development:
```swift
#if VERBOSE
    Self._printChanges()
#endif
```

### Performance Considerations
- `PropertyInspectorRow` uses `.equatable()` for optimization
- Context uses debouncing for search queries (see `Context.Data.setupDebouncing()`)
- Preference keys use `reduce()` to merge child values efficiently

### Environment Customization
- `isInspectable` - globally disable inspection
- `rowDetailFont`, `rowLabelFont` - typography customization
- Styles are applied via `ViewModifier` conforming to `_PropertyInspectorStyle`

## Key Public APIs

### Core Functions
- `.inspectProperty(_ values: Any...)` - Attach properties to view (with automatic location tracking via `#function`, `#file`, `#line`)
- `.inspectSelf()` - Inspect the view itself
- `.propertyInspectorHidden()` - Exclude view from inspection
- `.propertyInspectorRowIcon(for:icon:)` - Custom icon for type
- `.propertyInspectorRowLabel(for:label:)` - Custom label for type
- `.propertyInspectorRowDetail(for:detail:)` - Custom detail for type

### Initialization
```swift
PropertyInspector(listStyle: .plain) { /* content */ }
```

## Dependencies & Tooling
- **SwiftLint**: Development-only (v0.55.1+), configured in `.swiftlint.yml`
- **SwiftFormat**: Development-only (v0.54.0+), no config file present
- **DocC**: For documentation generation
- **Minimum Requirements**: iOS 15.0+, macOS 12+, Swift 5.7+

## MCP Tools Integration
**ALWAYS check `.vscode/mcp.json`** for available Xcode build tools before using terminal commands.

The project uses **xcodebuildmcp** MCP server providing 50+ Xcode automation tools:
- Building: `build_sim`, `build_macos`, `build_device`, `build_run_sim`, `build_run_macos`
- Testing: `test_sim`, `test_macos`, `test_device`, `swift_package_test`
- Simulators: `boot_sim`, `list_sims`, `open_sim`, `erase_sims`
- App Management: `install_app_sim`, `launch_app_sim`, `stop_app_sim`, `launch_app_logs_sim`
- UI Testing: `describe_ui`, `tap`, `swipe`, `type_text`, `screenshot`, `gesture`
- Debugging: `start_sim_log_cap`, `stop_sim_log_cap`, `screenshot`, `record_sim_video`
- Project Info: `discover_projs`, `list_schemes`, `show_build_settings`

**Configuration** (`.vscode/mcp.json`):
```json
{
  "servers": {
    "xcodebuildmcp": {
      "command": "npx",
      "args": ["-y", "xcodebuildmcp@latest"],
      "env": {
        "WORKSPACE_ROOT": "${workspaceFolder}",
        "PROJECT_PATH": "${workspaceFolder}/Package.swift",
        "SCHEME": "Showcase"
      }
    }
  }
}
```

**Best Practices:**
- **PREFER MCP tools over terminal commands** - they're faster and more reliable
- Use `build_run_sim` to build and run in one step instead of separate commands
- Use `launch_app_logs_sim` to automatically capture console output when launching
- Use `describe_ui` to get precise element coordinates before `tap` or `swipe`
- Use `list_sims` to find available simulators before running tests
- Use `swift_package_test` for running Swift Package tests instead of xcodebuild directly

**Example Workflows:**

Build and run Examples in simulator:
```
1. list_sims() to find iPhone 16
2. boot_sim(simulatorName: "iPhone 16") 
3. build_run_sim(workspacePath: "./Package.swift", scheme: "PropertyInspector-Examples")
```

Run tests with logs:
```
1. swift_package_test(packagePath: ".", filter: "ContextDataTests")
2. Or: test_sim(projectPath: "./Package.swift", scheme: "PropertyInspector", simulatorName: "iPhone 16")
```

UI Testing workflow:
```
1. screenshot(simulatorUuid: "...") to capture current state
2. describe_ui(simulatorUuid: "...") to get element coordinates
3. tap(simulatorUuid: "...", x: 100, y: 200) to interact
4. screenshot(simulatorUuid: "...") to verify result
```

## Testing Strategy
- **Unit Tests**: `Tests/` directory with 40+ tests (requires iOS simulator)
- **Performance Tests**: Baseline benchmarks in `Tests/PerformanceTests.swift`
- **Integration Tests**: Examples app serves as manual integration testing
- **CI/CD**: Automated tests run via `.github/workflows/tests.yml`

### Running Tests Locally
**Preferred method** (using MCP tools):
```
swift_package_test(packagePath: ".")
```

**Alternative** (traditional):
```bash
swift test --destination 'platform=iOS Simulator,name=iPhone 16'
```

**Performance benchmarks only**:
```
swift_package_test(packagePath: ".", filter: "PerformanceTests")
```

## Important Notes
- Property tracking uses source location (`PropertyLocation`) for unique identification
- `Property` is a reference type (class) for shared mutable highlight state
- All public symbols documented with DocC-style comments
- Library designed for debugging/development tools, not production UI
