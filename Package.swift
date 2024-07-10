// swift-tools-version: 5.7

import PackageDescription

let isRemoteCheckout = Context.packageDirectory.contains("Library/Developer/Xcode/DerivedData/")

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
            name: "PropertyInspector",
            swiftSettings: {
                if isRemoteCheckout {
                    []
                } else {
                    [.define("VERBOSE")]
                }
            }()
        ),
        .target(
            name: "PropertyInspectorExamples",
            dependencies: ["PropertyInspector"],
            path: "Sources/Examples"
        ),
    ]
)
