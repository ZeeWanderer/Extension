// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Extension",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Extension",
            //type: .static,
            targets: ["SwiftExtension", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions", "Extension"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftExtension",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics") // SE-0246 Accepted but not Implemented into Swift STD due to compiler issues
            ]),
        .target(
            name: "FoundationExtension",
            dependencies: ["SwiftExtension"],
            swiftSettings: [.unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"])]),
        .target(
            name: "CoreGraphicsExtension",
            dependencies: ["SwiftExtension", "FoundationExtension"],
            swiftSettings: [.unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"])]),
        .target(
            name: "UIKitExtension",
            dependencies: ["SwiftExtension"],
            swiftSettings: [.unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"])]),
        .target(
            name: "SpriteKitExtension",
            dependencies: ["UIKitExtension"],
            swiftSettings: [.unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"])]),
        .target(
            name: "SwiftUIExtension",
            dependencies: ["UIKitExtension", "CoreGraphicsExtension"],
            swiftSettings: [.unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"])]),
        .target(
            name: "GeneralExtensions",
            dependencies: [],
            swiftSettings: [.unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"])]),
        .target(
            name: "Extension",
            dependencies: ["SwiftExtension", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions"],
            swiftSettings: [.unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"])]),
        .testTarget(
            name: "ExtensionTests",
            dependencies: ["SwiftExtension", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions"]),
    ]
)
