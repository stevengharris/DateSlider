// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DateSlider",
    platforms: [
        .macOS(.v14),
        .macCatalyst(.v17),
        .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "DateSlider", targets: ["DateSlider"]),
    ],
    dependencies: [
      .package(
        url: "https://github.com/apple/swift-collections.git",
        .upToNextMinor(from: "1.0.5")
      )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DateSlider",
            dependencies: [
              .product(name: "Collections", package: "swift-collections")
            ],
            path: "DateSlider"
        )
    ]
)
