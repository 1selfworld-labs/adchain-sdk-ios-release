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
        .package(url: "https://github.com/1024jp/GzipSwift", from: "6.0.0")
        // Note: adjoe uses PlaytimeWeb (web-based) on iOS, no SDK dependency needed
    ],
    targets: [
        .target(
            name: "AdchainSDK",
            dependencies: [
                .product(name: "Gzip", package: "GzipSwift")
            ],
            path: "AdchainSDK/Sources"
        ),
        // .testTarget(
        //     name: "AdchainSDKTests",
        //     dependencies: ["AdchainSDK"],
        //     path: "Tests/AdchainSDKTests"
        // ),
    ]
)