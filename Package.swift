// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "swiftui-property-inspector",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "PropertyInspector",
            targets: ["PropertyInspector"]),
        .library(
            name: "PropertyInspectorExamples",
            targets: ["PropertyInspectorExamples"]),
    ],
    targets: [
        .target(
            name: "PropertyInspector"
        ),
        .target(
            name: "PropertyInspectorExamples",
            dependencies: ["PropertyInspector"],
            path: "Sources/Examples"
        ),
    ]
)
