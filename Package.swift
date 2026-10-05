// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftAccessibilityChecker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "swift-accessibility-checker",
            targets: ["swift-accessibility-checker"]
        ),
        .executable(
            name: "swift-accessibility-checker-gui",
            targets: ["swift-accessibility-checker-gui"]
        ),
        .plugin(
            name: "SwiftAccessibilityCheckerPlugin",
            targets: ["SwiftAccessibilityCheckerPlugin"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "602.0.0"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-testing.git",
            revision: "swift-6.2.4-RELEASE"
        )
    ],
    targets: [
        .target(
            name: "SwiftAccessibilityCheckerCore"
        ),
        .target(
            name: "SwiftAccessibilityCheckerAnalyzer",
            dependencies: [
                "SwiftAccessibilityCheckerCore",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        ),
        .target(
            name: "SwiftAccessibilityCheckerReporter",
            dependencies: [
                "SwiftAccessibilityCheckerCore"
            ]
        ),
        .executableTarget(
            name: "swift-accessibility-checker",
            dependencies: [
                "SwiftAccessibilityCheckerAnalyzer",
                "SwiftAccessibilityCheckerCore",
                "SwiftAccessibilityCheckerReporter"
            ],
            path: "Sources/SwiftAccessibilityCheckerCLI"
        ),
        .executableTarget(
            name: "swift-accessibility-checker-gui",
            dependencies: [
                "SwiftAccessibilityCheckerAnalyzer",
                "SwiftAccessibilityCheckerCore",
                "SwiftAccessibilityCheckerReporter"
            ],
            path: "Sources/SwiftAccessibilityCheckerGUI"
        ),
        .plugin(
            name: "SwiftAccessibilityCheckerPlugin",
            capability: .buildTool(),
            dependencies: [
                "swift-accessibility-checker"
            ]
        ),
        .testTarget(
            name: "SwiftAccessibilityCheckerTests",
            dependencies: [
                "SwiftAccessibilityCheckerAnalyzer",
                "SwiftAccessibilityCheckerCore",
                "SwiftAccessibilityCheckerReporter",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
