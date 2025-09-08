#!/bin/bash

# XCFramework 빌드 스크립트
# 사용법: ./build_xcframework.sh

set -e

echo "🚀 Starting XCFramework build..."

# 변수 설정
FRAMEWORK_NAME="AdchainSDK"
OUTPUT_DIR="./build"
XCFRAMEWORK_PATH="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

# 기존 빌드 삭제
rm -rf ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

# iOS Simulator용 빌드
echo "📱 Building for iOS Simulator..."
xcodebuild archive \
    -scheme ${FRAMEWORK_NAME} \
    -archivePath "${OUTPUT_DIR}/ios-simulator.xcarchive" \
    -sdk iphonesimulator \
    -configuration Release \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# iOS Device용 빌드
echo "📱 Building for iOS Device..."
xcodebuild archive \
    -scheme ${FRAMEWORK_NAME} \
    -archivePath "${OUTPUT_DIR}/ios-device.xcarchive" \
    -sdk iphoneos \
    -configuration Release \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# XCFramework 생성
echo "🔨 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "${OUTPUT_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${OUTPUT_DIR}/ios-device.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${XCFRAMEWORK_PATH}"

# Privacy Manifest 복사
echo "📋 Copying Privacy Manifest..."
if [ -f "AdchainSDK/PrivacyInfo.xcprivacy" ]; then
    # iOS arm64 아키텍처
    if [ -d "${XCFRAMEWORK_PATH}/ios-arm64" ]; then
        cp "AdchainSDK/PrivacyInfo.xcprivacy" "${XCFRAMEWORK_PATH}/ios-arm64/${FRAMEWORK_NAME}.framework/"
        echo "✅ Copied to ios-arm64"
    fi
    
    # iOS Simulator 아키텍처들
    if [ -d "${XCFRAMEWORK_PATH}/ios-arm64_x86_64-simulator" ]; then
        cp "AdchainSDK/PrivacyInfo.xcprivacy" "${XCFRAMEWORK_PATH}/ios-arm64_x86_64-simulator/${FRAMEWORK_NAME}.framework/"
        echo "✅ Copied to ios-arm64_x86_64-simulator"
    fi
    
    if [ -d "${XCFRAMEWORK_PATH}/ios-x86_64-simulator" ]; then
        cp "AdchainSDK/PrivacyInfo.xcprivacy" "${XCFRAMEWORK_PATH}/ios-x86_64-simulator/${FRAMEWORK_NAME}.framework/"
        echo "✅ Copied to ios-x86_64-simulator"
    fi
else
    echo "⚠️ PrivacyInfo.xcprivacy not found in AdchainSDK folder"
fi

# 결과 확인
if [ -d "${XCFRAMEWORK_PATH}" ]; then
    echo "✅ XCFramework created successfully!"
    echo "📦 Location: ${XCFRAMEWORK_PATH}"
    
    # ZIP 파일 생성 (전달용)
    echo "📦 Creating ZIP file..."
    cd ${OUTPUT_DIR}
    zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
    cd ..
    
    echo "✅ ZIP file created: ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
    echo ""
    echo "📤 You can now share the ZIP file with other developers!"
else
    echo "❌ Failed to create XCFramework"
    exit 1
fi