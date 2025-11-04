// swift-tools-version: 6.0

import PackageDescription

let isDevelopment = !Context.packageDirectory.contains(".build/checkouts/") && !Context.packageDirectory.contains("SourcePackages/checkouts/")

var targets: [Target] = [.target(
    name: "PropertyInspector-Examples",
    dependencies: ["PropertyInspector"],
    path: "Examples"
)]

if isDevelopment {
    targets.append(
        .target(
            name: "PropertyInspector",
            path: "Development",
            swiftSettings: [
                .define("VERBOSE"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .unsafeFlags(["-Xfrontend", "-warn-concurrency"], .when(configuration: .debug))
            ],
            plugins: [
                .plugin(
                    name: "SwiftLintBuildToolPlugin",
                    package: "SwiftLintPlugins"
                )
            ]
        )
    )
    targets.append(
        .testTarget(
            name: "PropertyInspectorTests",
            dependencies: ["PropertyInspector"],
            path: "Tests",
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-warn-concurrency"], .when(configuration: .debug))
            ]
        )
    )
} else {
    targets.append(
        .target(
            name: "PropertyInspector",
            path: ".",
            sources: ["PropertyInspector.swift"]
        )
    )
}

var dependencies = [Package.Dependency]()
if isDevelopment {
    dependencies.append(
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            from: "0.55.1"
        )
    )
    dependencies.append(
        .package(
            url: "https://github.com/nicklockwood/SwiftFormat",
            from: "0.54.0"
        )
    )
}

let package = Package(
    name: "swiftui-property-inspector",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "PropertyInspector",
            targets: ["PropertyInspector"]
        ),
        .library(
            name: "PropertyInspector-Examples",
            targets: ["PropertyInspector-Examples"]
        )
    ],
    dependencies: dependencies,
    targets: targets,
    swiftLanguageVersions: [.v6]
)
