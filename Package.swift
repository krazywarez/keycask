// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "keycask",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KeycaskCore", targets: ["KeycaskCore"]),
        .executable(name: "keycask", targets: ["keycask"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto", from: "3.15.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.0"),
    ],
    targets: [
        .target(
            name: "KeycaskCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
            ]
        ),
        .executableTarget(
            name: "keycask",
            dependencies: [
                "KeycaskCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "KeycaskCoreTests", dependencies: ["KeycaskCore"]),
        .testTarget(name: "KeycaskCLITests", dependencies: ["keycask"]),
    ]
)
