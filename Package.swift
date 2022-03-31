// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "enclave",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "enclave",
            targets: ["enclave"]),
        .library(
            name: "EnclaveKit",
            targets: ["EnclaveKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .executableTarget(
            name: "enclave",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "EnclaveKit")
            ]),
        .target(name: "EnclaveKit")
    ]
)
