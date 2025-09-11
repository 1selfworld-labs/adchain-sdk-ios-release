#!/bin/bash

# Swift Package Manager용 XCFramework 빌드
set -e

VERSION="1.0.0"
FRAMEWORK_NAME="AdchainSDK"
BUILD_DIR="./build_framework"
OUTPUT_DIR="${BUILD_DIR}/output"

echo "🚀 Building XCFramework from Swift Package"
echo "================================================"

# 1. 정리
echo "🧹 Cleaning..."
rm -rf ${BUILD_DIR}
mkdir -p ${OUTPUT_DIR}

# 2. iOS Device용 빌드
echo "📱 Building for iOS Device..."
xcodebuild build \
    -scheme ${FRAMEWORK_NAME} \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -derivedDataPath ${BUILD_DIR}/DerivedData \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

# 3. iOS Simulator용 빌드
echo "📱 Building for iOS Simulator..."
xcodebuild build \
    -scheme ${FRAMEWORK_NAME} \
    -destination "generic/platform=iOS Simulator" \
    -configuration Release \
    -derivedDataPath ${BUILD_DIR}/DerivedData-Sim \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

# 4. Framework 경로 찾기
echo "🔍 Locating built frameworks..."

# Device Framework 찾기
DEVICE_FRAMEWORK=$(find ${BUILD_DIR}/DerivedData -name "${FRAMEWORK_NAME}.framework" -type d | grep -v "iphonesimulator" | head -1)
SIM_FRAMEWORK=$(find ${BUILD_DIR}/DerivedData-Sim -name "${FRAMEWORK_NAME}.framework" -type d | grep "iphonesimulator" | head -1)

if [ -z "$DEVICE_FRAMEWORK" ] || [ -z "$SIM_FRAMEWORK" ]; then
    echo "❌ Could not find built frameworks"
    echo "Device: $DEVICE_FRAMEWORK"
    echo "Simulator: $SIM_FRAMEWORK"
    
    # 대안: Static Library로 빌드 시도
    echo "🔧 Trying alternative: Building as static library..."
    
    # Archive 방식으로 재시도
    xcodebuild archive \
        -scheme ${FRAMEWORK_NAME} \
        -destination "generic/platform=iOS" \
        -archivePath "${BUILD_DIR}/ios.xcarchive" \
        -configuration Release \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
    xcodebuild archive \
        -scheme ${FRAMEWORK_NAME} \
        -destination "generic/platform=iOS Simulator" \
        -archivePath "${BUILD_DIR}/ios-sim.xcarchive" \
        -configuration Release \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
    DEVICE_FRAMEWORK="${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
    SIM_FRAMEWORK="${BUILD_DIR}/ios-sim.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
fi

# 5. XCFramework 생성
if [ -d "$DEVICE_FRAMEWORK" ] && [ -d "$SIM_FRAMEWORK" ]; then
    echo "🔨 Creating XCFramework..."
    xcodebuild -create-xcframework \
        -framework "${DEVICE_FRAMEWORK}" \
        -framework "${SIM_FRAMEWORK}" \
        -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
else
    echo "❌ Frameworks not found. Paths checked:"
    echo "Device: $DEVICE_FRAMEWORK"
    echo "Simulator: $SIM_FRAMEWORK"
    exit 1
fi

# 6. 배포 준비
if [ -d "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework" ]; then
    echo "✅ XCFramework created successfully!"
    
    RELEASE_DIR="${BUILD_DIR}/release"
    rm -rf ${RELEASE_DIR}
    mkdir -p ${RELEASE_DIR}
    
    cp -r "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework" ${RELEASE_DIR}/
    
    # 필수 파일들 생성
    cat > ${RELEASE_DIR}/README.md << 'EOF'
# AdchainSDK for iOS (Binary Framework)

## Installation

### CocoaPods
```ruby
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
```

## Usage
```swift
import AdchainSDK
```

© 2024 1selfworld Labs
EOF

    cat > ${RELEASE_DIR}/AdchainSDK.podspec << EOF
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "${VERSION}"
  spec.summary      = "AdChain SDK Binary Framework"
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "#{spec.version}" }
  spec.vendored_frameworks = "AdchainSDK.xcframework"
  spec.swift_version = "5.5"
end
EOF

    echo "📦 Ready at: ${RELEASE_DIR}"
    ls -la ${RELEASE_DIR}/
else
    echo "❌ Failed to create XCFramework"
    exit 1
fi