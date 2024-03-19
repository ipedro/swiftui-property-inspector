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
    ],
    targets: [
        .target(
            name: "PropertyInspector",
            path: ".",
            sources: ["PropertyInspector.swift"]
        ),
    ]
)
