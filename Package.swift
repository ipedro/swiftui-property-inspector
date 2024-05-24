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
            name: "Examples",
            targets: ["Examples"]),
    ],
    targets: [
        .target(
            name: "PropertyInspector"
        ),
        .target(
            name: "Examples",
            dependencies: ["PropertyInspector"]
        ),
    ]
)
