// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenLibraryMetadata",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "OpenLibraryMetadata",
            targets: ["OpenLibraryMetadata"]
        ),
    ],
    targets: [
        .target(
            name: "OpenLibraryMetadata",
            dependencies: []
        ),
        .testTarget(
            name: "OpenLibraryMetadataTests",
            dependencies: ["OpenLibraryMetadata"]
        ),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
