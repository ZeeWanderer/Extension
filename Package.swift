// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Extension",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Extension",
            type: .static,
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
            dependencies: ["SwiftExtension"]),
        .target(
            name: "CoreGraphicsExtension",
            dependencies: ["SwiftExtension"]),
        .target(
            name: "UIKitExtension",
            dependencies: ["SwiftExtension"]),
        .target(
            name: "SpriteKitExtension",
            dependencies: ["UIKitExtension"]),
        .target(
            name: "SwiftUIExtension",
            dependencies: ["UIKitExtension"]),
        .target(
            name: "GeneralExtensions",
            dependencies: []),
        .target(
            name: "Extension",
            dependencies: ["SwiftExtension", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions"]),
        .testTarget(
            name: "ExtensionTests",
            dependencies: ["SwiftExtension", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions"]),
    ]
)
