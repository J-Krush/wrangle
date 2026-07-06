// swift-tools-version:5.9

// Vendored, trimmed manifest — see VENDOR.md. Upstream's manifest also
// declares fuzzing/benchmark/CLI targets and their remote dependencies;
// Wrangle only consumes the SwiftTerm library target.

import PackageDescription

let package = Package(
    name: "SwiftTerm",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftTerm",
            targets: ["SwiftTerm"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftTerm",
            path: "Sources/SwiftTerm",
            exclude: ["Mac/README.md"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
