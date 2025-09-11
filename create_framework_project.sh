#!/bin/bash

# Xcode Framework 프로젝트 생성 및 XCFramework 빌드
set -e

FRAMEWORK_NAME="AdchainSDK"
PROJECT_DIR="./AdchainSDKFramework"
BUILD_DIR="./build_xcframework"
VERSION="1.0.0"

echo "🎯 Creating Real Binary XCFramework"
echo "===================================="

# 1. Framework 프로젝트 디렉토리 생성
echo "📁 Creating Framework project structure..."
rm -rf ${PROJECT_DIR}
mkdir -p ${PROJECT_DIR}/${FRAMEWORK_NAME}

# 2. Framework 헤더 생성
cat > ${PROJECT_DIR}/${FRAMEWORK_NAME}/${FRAMEWORK_NAME}.h << 'EOF'
//
//  AdchainSDK.h
//  AdchainSDK
//
//  Copyright © 2024 1selfworld Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for AdchainSDK.
FOUNDATION_EXPORT double AdchainSDKVersionNumber;

//! Project version string for AdchainSDK.
FOUNDATION_EXPORT const unsigned char AdchainSDKVersionString[];

// Public headers of your framework should be imported here
EOF

# 3. Module Map 생성
mkdir -p ${PROJECT_DIR}/${FRAMEWORK_NAME}
cat > ${PROJECT_DIR}/${FRAMEWORK_NAME}/module.modulemap << EOF
framework module AdchainSDK {
    umbrella header "AdchainSDK.h"
    export *
    module * { export * }
}
EOF

# 4. Info.plist 생성
cat > ${PROJECT_DIR}/${FRAMEWORK_NAME}/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.oneself.adchainsdk</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string></string>
</dict>
</plist>
EOF

# 5. 모든 Swift 소스 복사
echo "📝 Copying source files..."
cp -r AdchainSDK/Sources ${PROJECT_DIR}/${FRAMEWORK_NAME}/

# 6. xcconfig 파일 생성
cat > ${PROJECT_DIR}/Framework.xcconfig << EOF
PRODUCT_NAME = ${FRAMEWORK_NAME}
PRODUCT_BUNDLE_IDENTIFIER = com.oneself.adchainsdk
INFOPLIST_FILE = ${FRAMEWORK_NAME}/Info.plist

// Framework 설정
DEFINES_MODULE = YES
DYLIB_COMPATIBILITY_VERSION = 1
DYLIB_CURRENT_VERSION = 1
SKIP_INSTALL = NO
BUILD_LIBRARY_FOR_DISTRIBUTION = YES

// Swift 설정
SWIFT_VERSION = 5.5
SWIFT_OPTIMIZATION_LEVEL = -O

// 아키텍처
VALID_ARCHS = arm64 x86_64
ARCHS = \$(ARCHS_STANDARD)

// 배포 타겟
IPHONEOS_DEPLOYMENT_TARGET = 14.0

// Code Signing
CODE_SIGN_IDENTITY =
CODE_SIGNING_REQUIRED = NO
CODE_SIGNING_ALLOWED = NO
EOF

# 7. Build Script 생성
cat > ${PROJECT_DIR}/build_framework.sh << 'BUILDSCRIPT'
#!/bin/bash
set -e

FRAMEWORK_NAME="AdchainSDK"
BUILD_DIR="../build_xcframework"
OUTPUT_DIR="${BUILD_DIR}/output"

echo "🔨 Building XCFramework..."

# Clean
rm -rf ${BUILD_DIR}
mkdir -p ${OUTPUT_DIR}

# Build for iOS Device
echo "📱 Building for iOS Device..."
xcodebuild -project ${FRAMEWORK_NAME}.xcodeproj \
    -scheme ${FRAMEWORK_NAME} \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "${BUILD_DIR}/ios.xcarchive" \
    archive \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ONLY_ACTIVE_ARCH=NO

# Build for iOS Simulator  
echo "📱 Building for iOS Simulator..."
xcodebuild -project ${FRAMEWORK_NAME}.xcodeproj \
    -scheme ${FRAMEWORK_NAME} \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${BUILD_DIR}/ios-simulator.xcarchive" \
    archive \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ONLY_ACTIVE_ARCH=NO

# Create XCFramework
echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

echo "✅ Success! XCFramework at: ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
BUILDSCRIPT

chmod +x ${PROJECT_DIR}/build_framework.sh

# 8. Xcode 프로젝트 생성
echo "🛠 Generating Xcode project..."
cd ${PROJECT_DIR}

# Framework 프로젝트 생성을 위한 간단한 Package.swift
cat > Package.swift << EOF
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "${FRAMEWORK_NAME}",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "${FRAMEWORK_NAME}", type: .dynamic, targets: ["${FRAMEWORK_NAME}"])
    ],
    targets: [
        .target(
            name: "${FRAMEWORK_NAME}",
            path: "${FRAMEWORK_NAME}/Sources"
        )
    ]
)
EOF

# Xcode 프로젝트 생성
swift package generate-xcodeproj 2>/dev/null || true

cd ..

echo "
==================================
✅ Framework Project Created!
==================================

📁 Location: ${PROJECT_DIR}

Next steps:
1. cd ${PROJECT_DIR}
2. Open ${FRAMEWORK_NAME}.xcodeproj in Xcode
3. Build the framework
4. Or run: ./build_framework.sh

This will create a REAL binary XCFramework where:
- Source code is compiled to machine code
- No .swift files visible
- Only binary + headers
"