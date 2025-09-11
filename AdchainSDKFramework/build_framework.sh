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
