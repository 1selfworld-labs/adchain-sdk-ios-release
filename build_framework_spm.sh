#!/bin/bash

# Swift Package Manager를 사용한 XCFramework 빌드
# 더 간단한 방법

set -e

echo "🚀 Building XCFramework using Swift Package Manager..."

FRAMEWORK_NAME="AdchainSDK"
OUTPUT_DIR="./build"

# 기존 빌드 삭제
rm -rf ${OUTPUT_DIR}

# iOS용 XCFramework 빌드
swift build -c release \
    --arch arm64 \
    --arch x86_64 \
    --sdk $(xcrun --sdk iphonesimulator --show-sdk-path)

# Archive 생성
xcodebuild -create-xcframework \
    -library .build/release/lib${FRAMEWORK_NAME}.a \
    -headers AdchainSDK/ \
    -output ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework

echo "✅ Build complete!"