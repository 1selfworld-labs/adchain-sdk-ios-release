// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AdchainSDK",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "AdchainSDK", type: .dynamic, targets: ["AdchainSDK"])
    ],
    targets: [
        .target(
            name: "AdchainSDK",
            path: "AdchainSDK/Sources"
        )
    ]
)
