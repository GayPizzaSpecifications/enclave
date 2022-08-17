// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "enclave",
    platforms: [
        .macOS(.v11)
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.1.3"))
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
