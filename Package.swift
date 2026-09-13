// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Nourish",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Nourish", targets: ["Nourish"])
    ],
    targets: [
        .target(
            name: "Nourish",
            path: "Nourish"
        ),
        .testTarget(
            name: "NourishTests",
            dependencies: ["Nourish"],
            path: "NourishTests"
        )
    ]
)
