#!/bin/bash

# 완전 자동화된 바이너리 빌드 및 배포 스크립트
# 사용법: ./build_and_deploy_binary.sh

set -e

VERSION="1.0.0"
FRAMEWORK_NAME="AdchainSDK"
BUILD_DIR="./build"
TEMP_DIR="/tmp/adchain-binary-release"

echo "🚀 Starting Binary Build and Deploy Process"
echo "Version: $VERSION"

# Step 1: Xcode 프로젝트 생성 (SPM에서)
echo "📱 Creating Xcode project from Package.swift..."
swift package generate-xcodeproj

# Step 2: Framework 빌드
echo "🔨 Building Framework..."
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

# iOS Device용 빌드
xcodebuild -project ${FRAMEWORK_NAME}.xcodeproj \
    -scheme ${FRAMEWORK_NAME} \
    -sdk iphoneos \
    -configuration Release \
    -derivedDataPath ${BUILD_DIR}/DerivedData \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO \
    archive -archivePath ${BUILD_DIR}/ios-device.xcarchive

# iOS Simulator용 빌드
xcodebuild -project ${FRAMEWORK_NAME}.xcodeproj \
    -scheme ${FRAMEWORK_NAME} \
    -sdk iphonesimulator \
    -configuration Release \
    -derivedDataPath ${BUILD_DIR}/DerivedData \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO \
    archive -archivePath ${BUILD_DIR}/ios-simulator.xcarchive

# XCFramework 생성
echo "📦 Creating XCFramework..."
rm -rf ${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework

xcodebuild -create-xcframework \
    -framework ${BUILD_DIR}/ios-device.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework \
    -framework ${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework \
    -output ${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework

# Step 3: 배포 준비
echo "📤 Preparing for deployment..."
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}

# XCFramework 복사
cp -r ${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework ${TEMP_DIR}/

# README 생성
cat > ${TEMP_DIR}/README.md << 'EOF'
# AdchainSDK for iOS

## 설치 방법

### CocoaPods 사용

```ruby
# Podfile
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
```

```bash
pod install
```

### 수동 설치

1. `AdchainSDK.xcframework`를 다운로드
2. Xcode 프로젝트에 드래그 앤 드롭
3. "Embed & Sign" 선택

## 사용 방법

```swift
import AdchainSDK

// SDK 초기화
let config = AdchainSdkConfig.Builder(
    appKey: "your-app-key",
    appSecret: "your-app-secret"
)
.setEnvironment(.production)
.build()

AdchainSdk.shared.initialize(config: config)
```

## 요구사항

- iOS 14.0+
- Swift 5.5+

## 라이센스

Copyright © 2024 1selfworld Labs. All rights reserved.
EOF

# LICENSE 생성
cat > ${TEMP_DIR}/LICENSE << 'EOF'
Copyright (c) 2024 1selfworld Labs

All rights reserved.

This SDK is proprietary software.
Usage is subject to license terms.
EOF

# Podspec 생성 (바이너리용)
cat > ${TEMP_DIR}/AdchainSDK.podspec << EOF
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "${VERSION}"
  spec.summary      = "AdChain SDK for iOS - Advertising and Offerwall Solution"
  spec.description  = <<-DESC
                       AdChain SDK provides comprehensive advertising solutions including:
                       - Offerwall integration
                       - Quiz and Mission systems  
                       - Native ad support
                       - Complete JavaScript bridge
                       DESC
  
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary", :file => "LICENSE" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  
  spec.platform     = :ios, "14.0"
  spec.ios.deployment_target = "14.0"
  
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "#{spec.version}" }
  
  # 바이너리 Framework 배포 (소스코드 없음)
  spec.vendored_frameworks = "AdchainSDK.xcframework"
  
  spec.frameworks = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"
  spec.swift_version = "5.5"
  spec.requires_arc = true
  
  spec.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
end
EOF

# .gitignore 생성
cat > ${TEMP_DIR}/.gitignore << 'EOF'
.DS_Store
*.swp
*~
EOF

echo "✅ Build complete! Files ready at: ${TEMP_DIR}"
echo ""
echo "📋 Next Steps:"
echo "1. cd ${TEMP_DIR}"
echo "2. git init"
echo "3. git add ."
echo "4. git commit -m 'Release v${VERSION} - Binary distribution'"
echo "5. git remote add origin https://github.com/1selfworld-labs/adchain-sdk-ios-release.git"
echo "6. git push -u origin main"
echo "7. git tag ${VERSION}"
echo "8. git push origin ${VERSION}"