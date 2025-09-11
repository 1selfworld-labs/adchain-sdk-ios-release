#!/bin/bash

# Closed Source Package 생성 (바이너리처럼 동작)
set -e

VERSION="1.0.0"
TEMP_DIR="/tmp/adchain-closed-source"

echo "🔒 Creating Closed Source Package"
echo "================================="

# 1. 준비
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}

# 2. 바이너리 타겟을 위한 Package.swift
cat > ${TEMP_DIR}/Package.swift << 'EOF'
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AdchainSDK",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "AdchainSDK", targets: ["AdchainSDK"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "AdchainSDK",
            url: "https://github.com/1selfworld-labs/adchain-sdk-ios-release/releases/download/1.0.0/AdchainSDK.xcframework.zip",
            checksum: "CHECKSUM_WILL_BE_UPDATED"
        )
    ]
)
EOF

# 3. README
cat > ${TEMP_DIR}/README.md << 'EOF'
# AdchainSDK for iOS

**Closed Source Binary Distribution**

## Installation

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", from: "1.0.0")
]
```

### CocoaPods
```ruby
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
```

## Binary Framework

This package distributes a pre-compiled binary framework.
Source code is not included.

© 2024 1selfworld Labs. All rights reserved.
EOF

# 4. Podspec for Binary
cat > ${TEMP_DIR}/AdchainSDK.podspec << 'EOF'
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "1.0.0"
  spec.summary      = "AdChain SDK - Binary Framework"
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary" }
  spec.author       = "1selfworld Labs"
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "1.0.0" }
  
  # Download pre-compiled XCFramework
  spec.source       = { 
    :http => "https://github.com/1selfworld-labs/adchain-sdk-ios-release/releases/download/1.0.0/AdchainSDK.xcframework.zip"
  }
  spec.vendored_frameworks = "AdchainSDK.xcframework"
  spec.swift_version = "5.5"
end
EOF

echo "
================================
📦 Closed Source Package Ready
================================

Location: ${TEMP_DIR}

이 방식은:
1. GitHub Release에 XCFramework.zip 업로드
2. Package.swift가 바이너리를 다운로드
3. 소스코드 완전 숨김

하지만 먼저 XCFramework를 만들어야 합니다.
Xcode GUI에서 직접 만드는 것을 추천합니다.
"