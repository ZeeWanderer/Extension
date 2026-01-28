// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Extension",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14),
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
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.3"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .macro(
            name: "Macros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "MacrosExtension",
            dependencies: ["Macros", "osExtension"],
            swiftSettings: []
        ),
        .target(
            name: "SwiftExtension",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics") // SE-0246 Accepted but not Implemented into Swift STL due to compiler issues
            ],
            swiftSettings: []
        ),
        .target(
            name: "FoundationExtension",
            dependencies: ["SwiftExtension"],
            swiftSettings: []
        ),
        .target(
            name: "osExtension",
            dependencies: ["FoundationExtension"],
            swiftSettings: []
        ),
        .target(
            name: "ObservationExtension",
            dependencies: ["FoundationExtension"],
            swiftSettings: []
        ),
        .target(
            name: "AccelerateExtension",
            dependencies: ["FoundationExtension"],
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
            dependencies: ["GeneralExtensions", "FoundationExtension", "CoreGraphicsExtension", "UIKitExtension", "osExtension"],
            swiftSettings: []
        ),
        .target(
            name: "GeneralExtensions",
            dependencies: [],
            swiftSettings: []
        ),
        .target(
            name: "Extension",
            dependencies: ["MacrosExtension", "SwiftExtension", "FoundationExtension", "osExtension", "ObservationExtension", "AccelerateExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions"],
            swiftSettings: []
        ),
        .testTarget(
            name: "ExtensionTests",
            dependencies: [
                "SwiftExtension", "FoundationExtension", "osExtension", "ObservationExtension", "AccelerateExtension", "CoreGraphicsExtension", "UIKitExtension", "SpriteKitExtension", "SwiftUIExtension", "GeneralExtensions", "Extension",
            ]),
        .testTarget(
            name: "ExtensionMacroTests",
            dependencies: [
                .target(name: "Macros", condition: .when(platforms: [.macOS])),
                .target(name: "MacrosExtension", condition: .when(platforms: [.macOS])),
                "SwiftExtension", "FoundationExtension", "GeneralExtensions",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax", condition: .when(platforms: [.macOS])),
            ]),
    ],
    swiftLanguageModes: [
        .v5,
        .v6
    ]
)
