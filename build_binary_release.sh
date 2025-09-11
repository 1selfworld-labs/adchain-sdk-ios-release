#!/bin/bash

# 바이너리 XCFramework 빌드 및 배포
# 코드를 숨기고 컴파일된 바이너리만 배포

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "❌ Usage: ./build_binary_release.sh <version>"
    echo "Example: ./build_binary_release.sh 1.0.0"
    exit 1
fi

echo "🔒 Building Binary Release (Source Code Hidden)"

# 1. XCFramework 빌드
echo "📦 Building XCFramework..."

FRAMEWORK_NAME="AdchainSDK"
BUILD_DIR="./build"
OUTPUT_DIR="${BUILD_DIR}/output"

rm -rf ${BUILD_DIR}
mkdir -p ${OUTPUT_DIR}

# iOS Device 빌드
xcodebuild archive \
    -workspace . \
    -scheme ${FRAMEWORK_NAME} \
    -archivePath "${BUILD_DIR}/ios-device.xcarchive" \
    -sdk iphoneos \
    -configuration Release \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# iOS Simulator 빌드  
xcodebuild archive \
    -workspace . \
    -scheme ${FRAMEWORK_NAME} \
    -archivePath "${BUILD_DIR}/ios-simulator.xcarchive" \
    -sdk iphonesimulator \
    -configuration Release \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# XCFramework 생성
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/ios-device.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

# 2. 배포용 파일 준비
echo "📄 Preparing distribution files..."

RELEASE_DIR="${BUILD_DIR}/release"
rm -rf ${RELEASE_DIR}
mkdir -p ${RELEASE_DIR}

# XCFramework 복사
cp -r "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework" ${RELEASE_DIR}/

# README 생성 (사용법만)
cat > ${RELEASE_DIR}/README.md << EOF
# AdchainSDK for iOS

## Installation

### Using CocoaPods

\`\`\`ruby
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '${VERSION}'
\`\`\`

### Manual Installation

1. Download the \`AdchainSDK.xcframework\`
2. Drag it into your Xcode project
3. Make sure to select "Embed & Sign"

## Usage

\`\`\`swift
import AdchainSDK

let config = AdchainSdkConfig.Builder(appKey: "your-key", appSecret: "your-secret")
    .setEnvironment(.production)
    .build()

AdchainSdk.shared.initialize(config: config)
\`\`\`

## Requirements

- iOS 14.0+
- Swift 5.5+

## License

Proprietary - All rights reserved
EOF

# LICENSE 파일
cat > ${RELEASE_DIR}/LICENSE << EOF
Copyright (c) 2024 1selfworld Labs
All rights reserved.

This framework is proprietary software.
Redistribution is not permitted without explicit permission.
EOF

# Podspec for Binary
cat > ${RELEASE_DIR}/AdchainSDK.podspec << EOF
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "${VERSION}"
  spec.summary      = "AdChain SDK for iOS"
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary", :text => "All rights reserved" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  
  spec.platform     = :ios, "14.0"
  spec.ios.deployment_target = "14.0"
  
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "#{spec.version}" }
  
  # 바이너리 배포 - 소스코드 없음
  spec.vendored_frameworks = "AdchainSDK.xcframework"
  
  spec.frameworks = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"
  spec.swift_version = "5.5"
end
EOF

# 3. ZIP 파일 생성
cd ${RELEASE_DIR}
zip -r AdchainSDK-${VERSION}.xcframework.zip AdchainSDK.xcframework
cd -

echo "
========================================
✅ Binary Build Complete!
========================================

Files created:
- ${RELEASE_DIR}/AdchainSDK.xcframework (바이너리)
- ${RELEASE_DIR}/AdchainSDK.podspec
- ${RELEASE_DIR}/README.md
- ${RELEASE_DIR}/LICENSE
- ${RELEASE_DIR}/AdchainSDK-${VERSION}.xcframework.zip

Next steps:
1. Push these files to public repo (소스코드 없음)
2. Users can install without seeing source code
"