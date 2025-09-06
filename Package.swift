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
    dependencies: [],
    targets: [
        .target(
            name: "AdchainSDK",
            dependencies: [],
            path: "AdchainSDK/Sources"
        ),
        // .testTarget(
        //     name: "AdchainSDKTests",
        //     dependencies: ["AdchainSDK"],
        //     path: "Tests/AdchainSDKTests"
        // ),
    ]
)