// swift-tools-version:6.0
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
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.1"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftExtension",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics") // SE-0246 Accepted but not Implemented into Swift STD due to compiler issues
            ],
            swiftSettings: []
        ),
        .target(
            name: "FoundationExtension",
            dependencies: ["SwiftExtension"],
            swiftSettings: []
        ),
        .target(
            name: "CoreGraphicsExtension",
            dependencies: ["SwiftExtension", "FoundationExtension"],
            swiftSettings: []
        ),
        .target(
            name: "UIKitExtension",
            dependencies: ["SwiftExtension", "CoreGraphicsExtension"],
            swiftSettings: []
        ),
        .target(
            name: "SpriteKitExtension",
            dependencies: ["UIKitExtension"],
            swiftSettings: []
        ),
        .target(
            name: "SwiftUIExtension",
            dependencies: ["UIKitExtension", "CoreGraphicsExtension", "GeneralExtensions"],
            swiftSettings: []
        ),
        .target(
            name: "GeneralExtensions",
            dependencies: [],
            swiftSettings: []
        ),
        .target(
            name: "Extension",
            dependencies: ["SwiftExtension", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions"],
            swiftSettings: []
        ),
        .testTarget(
            name: "ExtensionTests",
            dependencies: ["SwiftExtension", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions", "Extension"]),
    ],
    swiftLanguageModes: [
        .v5,
        .v6
    ]
)
