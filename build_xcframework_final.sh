#!/bin/bash

# XCFramework 바이너리 빌드 스크립트
set -e

VERSION="1.0.0"
FRAMEWORK_NAME="AdchainSDK"
BUILD_DIR="./build_framework"
OUTPUT_DIR="${BUILD_DIR}/output"

echo "🚀 Building XCFramework (Binary - No Source Code)"
echo "================================================"

# 1. 기존 빌드 정리
echo "🧹 Cleaning previous builds..."
rm -rf ${BUILD_DIR}
rm -rf ~/Library/Developer/Xcode/DerivedData/*AdchainSDK*
mkdir -p ${OUTPUT_DIR}

# 2. iOS Device용 Framework 빌드
echo "📱 Building for iOS Device (arm64)..."
xcodebuild archive \
    -scheme ${FRAMEWORK_NAME} \
    -archivePath "${BUILD_DIR}/ios-device.xcarchive" \
    -sdk iphoneos \
    -configuration Release \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO 2>&1 | grep -E "^\*\*|error:|warning:|Building|Succeeded" || true

# 3. iOS Simulator용 Framework 빌드  
echo "📱 Building for iOS Simulator (x86_64, arm64)..."
xcodebuild archive \
    -scheme ${FRAMEWORK_NAME} \
    -archivePath "${BUILD_DIR}/ios-simulator.xcarchive" \
    -sdk iphonesimulator \
    -configuration Release \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO 2>&1 | grep -E "^\*\*|error:|warning:|Building|Succeeded" || true

# 4. XCFramework 생성
echo "🔨 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/ios-device.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

# 4-1. Privacy Manifest 복사
echo "📋 Copying Privacy Manifest..."
if [ -f "AdchainSDK/PrivacyInfo.xcprivacy" ]; then
    for arch_dir in "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"/*; do
        if [ -d "$arch_dir/${FRAMEWORK_NAME}.framework" ]; then
            cp "AdchainSDK/PrivacyInfo.xcprivacy" "$arch_dir/${FRAMEWORK_NAME}.framework/"
            echo "✅ Copied to $(basename $arch_dir)"
        fi
    done
else
    echo "⚠️ PrivacyInfo.xcprivacy not found"
fi

# 5. 배포 파일 준비
echo "📦 Preparing distribution files..."
RELEASE_DIR="${BUILD_DIR}/release"
rm -rf ${RELEASE_DIR}
mkdir -p ${RELEASE_DIR}

# XCFramework 복사
cp -r "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework" ${RELEASE_DIR}/

# README 생성
cat > ${RELEASE_DIR}/README.md << 'EOF'
# AdchainSDK for iOS

Binary Framework Distribution - Source code is not included.

## Installation

### CocoaPods

```ruby
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
```

### Manual Installation

1. Download `AdchainSDK.xcframework`
2. Drag into your Xcode project
3. Select "Embed & Sign" in Frameworks settings

## Usage

```swift
import AdchainSDK

let config = AdchainSdkConfig.Builder(
    appKey: "YOUR_APP_KEY",
    appSecret: "YOUR_APP_SECRET"
)
.setEnvironment(.production)
.build()

AdchainSdk.shared.initialize(config: config)
```

## Requirements

- iOS 14.0+
- Swift 5.5+

## License

© 2024 1selfworld Labs. All rights reserved.
EOF

# Podspec for Binary Distribution
cat > ${RELEASE_DIR}/AdchainSDK.podspec << EOF
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "${VERSION}"
  spec.summary      = "AdChain SDK for iOS - Binary Framework"
  spec.description  = <<-DESC
                       AdChain SDK provides advertising and offerwall solutions.
                       This is a binary distribution - no source code included.
                       DESC
  
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary", :text => "© 2024 1selfworld Labs" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  
  spec.platform     = :ios, "14.0"
  spec.ios.deployment_target = "14.0"
  
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "#{spec.version}" }
  
  # Binary Framework - NO SOURCE CODE
  spec.vendored_frameworks = "AdchainSDK.xcframework"
  
  spec.frameworks = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"
  spec.swift_version = "5.5"
  spec.requires_arc = true
end
EOF

# LICENSE
cat > ${RELEASE_DIR}/LICENSE << 'EOF'
© 2024 1selfworld Labs. All rights reserved.

This is proprietary software. Unauthorized copying, modification, 
distribution, or use of this software is strictly prohibited.
EOF

# .gitignore
cat > ${RELEASE_DIR}/.gitignore << 'EOF'
.DS_Store
*.swp
EOF

# 6. 결과 확인
if [ -d "${RELEASE_DIR}/${FRAMEWORK_NAME}.xcframework" ]; then
    echo ""
    echo "✅ SUCCESS! XCFramework built successfully!"
    echo "================================================"
    echo "📦 Binary Framework Location:"
    echo "   ${RELEASE_DIR}/${FRAMEWORK_NAME}.xcframework"
    echo ""
    echo "📋 Files ready for deployment:"
    ls -la ${RELEASE_DIR}/
    echo ""
    echo "⚠️  NO SOURCE CODE in the framework!"
    echo ""
else
    echo "❌ Failed to create XCFramework"
    exit 1
fi