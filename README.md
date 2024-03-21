# SwiftUI Property Inspector

![Swift Version](https://img.shields.io/badge/swift-5.7-orange.svg)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![SPM Compatible](https://img.shields.io/badge/Swift_Package_Manager-compatible-brightgreen.svg)

<description>

## Features


## Installation

### Swift Package Manager

Add `swiftui-property-inspector` to your project by including it in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/ipedro/swiftui-property-inspector", .upToNextMajor(from: "1.0.0"))
]
```

Then, import `swiftui-property-inspector` in your SwiftUI views to start using it.

## Usage

Here's how to get started with the SwiftUI Property Inspector:

## Contributing

We welcome contributions! If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are warmly welcome.

## License

The `swiftui-property-inspector` package is released under the MIT License. See [LICENSE](LICENSE) for details.
Certainly! Below is a template for a README file that you can use as a starting point. You'll need to fill in or customize the sections according to the specifics of your `PropertyInspector` package.

```markdown
# PropertyInspector

PropertyInspector is a SwiftUI component that provides a powerful and flexible way to inspect and interact with properties dynamically. It's designed for developers who want to create sophisticated debugging tools, enhance the interactivity of their apps, or simply need a detailed view into their data structures.

## Features

- **Dynamic Property Inspection**: Intuitively inspect properties of any type within your SwiftUI views.
- **Customizable UI**: Easily customize icons, labels, and detail views for each property.
- **Sorting Capability**: Sort properties using custom criteria for better organization and accessibility.
- **Search Functionality**: Quickly find properties with a built-in search feature.
- **Environment Customization**: Adjust corner radius for the property highlight view using environment values.

## Requirements

- iOS 16.4+
- Swift 5.5+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add `swiftui-property-inspector` to your project by including it in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/ipedro/swiftui-property-inspector", .upToNextMajor(from: "1.0.0"))
]
```

Then, import `swiftui-property-inspector` in your SwiftUI views to start using it.

## Usage

Here's how to use `PropertyInspector` in your SwiftUI views:

```swift
import SwiftUI
import PropertyInspector

@State private var isInspectorPresented = false

var body: some View {
    PropertyInspector("Properties", MyValueType.self, isPresented: $isInspectorPresented) {
        // Main content view goes here
    } icon: { value in
        Image(systemName: "gear")
    } label: { value in
        Text("Property \(value)")
    } detail: { value in
        Text("Detail for \(value)")
    }
    .sort { lhs, rhs in
        // Sorting logic goes here
        return lhs.propertyName < rhs.propertyName
    }
}
```

### Disabling Inspection

To disable the property inspection:

```swift
var body: some View {
    MyView()
        .inspectingDisabled()
}
```

### Customizing Corner Radius

To customize the corner radius of the property highlight view:

```swift
var body: some View {
    MyView()
        .propertyInspectorCornerRadius(10)
}
```

## Contributing

We welcome contributions! If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are warmly welcome.

## License

The `swiftui-property-picker` package is released under the MIT License. See [LICENSE](LICENSE) for details.
