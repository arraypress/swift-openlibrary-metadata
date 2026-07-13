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
