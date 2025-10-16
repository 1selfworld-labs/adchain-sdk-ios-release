// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AdchainSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AdchainSDK",
            targets: ["AdchainSDK"]
        ),
    ],
    dependencies: [
        // GzipSwift is already statically linked in the XCFramework
        // No external dependencies needed
    ],
    targets: [
        .binaryTarget(
            name: "AdchainSDK",
            path: "AdchainSDK.xcframework"
        ),
    ]
)