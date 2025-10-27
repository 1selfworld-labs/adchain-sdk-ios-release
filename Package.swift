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
    targets: [
        .binaryTarget(
            name: "AdchainSDK",
            path: "AdchainSDK.xcframework"
        )
    ]
)
