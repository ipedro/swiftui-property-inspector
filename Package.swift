// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "swiftui-property-inspector",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "PropertyInspector",
            targets: ["PropertyInspector"]),
    ],
    targets: [
        .target(
            name: "PropertyInspector",
            path: ".",
            sources: ["PropertyInspector.swift"]
        ),
    ]
)
