#!/bin/bash

# 실제 작동하는 XCFramework 빌드 스크립트
set -e

FRAMEWORK_NAME="AdchainSDK"
BUILD_DIR="./DerivedData"
OUTPUT_DIR="./XCFrameworkOutput"
VERSION="1.0.0"

echo "🚀 Building Real Binary XCFramework"
echo "===================================="

# 1. Clean
echo "🧹 Cleaning..."
rm -rf ${BUILD_DIR}
rm -rf ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

# 2. Archive for iOS Device
echo "📱 Building for iOS Device..."
xcodebuild archive \
    -scheme ${FRAMEWORK_NAME} \
    -destination "generic/platform=iOS" \
    -archivePath "${BUILD_DIR}/ios.xcarchive" \
    -derivedDataPath "${BUILD_DIR}" \
    -configuration Release \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# 3. Archive for iOS Simulator
echo "📱 Building for iOS Simulator..."
xcodebuild archive \
    -scheme ${FRAMEWORK_NAME} \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${BUILD_DIR}/ios-simulator.xcarchive" \
    -derivedDataPath "${BUILD_DIR}" \
    -configuration Release \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# 4. Framework 경로 찾기
echo "🔍 Locating frameworks..."

# Framework 찾기 (다양한 경로 시도)
DEVICE_FW=""
SIM_FW=""

# 경로 1: Archive Products
if [ -d "${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" ]; then
    DEVICE_FW="${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
fi

if [ -d "${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" ]; then
    SIM_FW="${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
fi

# 경로 2: Build Products
if [ -z "$DEVICE_FW" ]; then
    DEVICE_FW=$(find ${BUILD_DIR} -name "${FRAMEWORK_NAME}.framework" -path "*/Release-iphoneos/*" | head -1)
fi

if [ -z "$SIM_FW" ]; then
    SIM_FW=$(find ${BUILD_DIR} -name "${FRAMEWORK_NAME}.framework" -path "*/Release-iphonesimulator/*" | head -1)
fi

# 5. XCFramework 생성
if [ -n "$DEVICE_FW" ] && [ -n "$SIM_FW" ]; then
    echo "📦 Creating XCFramework..."
    echo "Device: $DEVICE_FW"
    echo "Simulator: $SIM_FW"
    
    xcodebuild -create-xcframework \
        -framework "${DEVICE_FW}" \
        -framework "${SIM_FW}" \
        -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
    
    # Privacy Manifest 복사
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
    
    if [ -d "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework" ]; then
        echo "✅ SUCCESS! Binary XCFramework created!"
        echo "Location: ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
        
        # 확인: Swift 파일이 없는지 체크
        echo ""
        echo "🔍 Verifying binary (no source files):"
        find "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework" -name "*.swift" 2>/dev/null | wc -l | xargs echo "Swift files found:"
        
        # 바이너리 파일 확인
        find "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework" -name "${FRAMEWORK_NAME}" -type f | head -1 | xargs file
    fi
else
    echo "❌ Failed to locate frameworks"
    echo "Trying alternative approach..."
    
    # 대안: Static Library 생성
    echo "🔧 Building as static library..."
    
    # iOS Device
    xcodebuild build \
        -scheme ${FRAMEWORK_NAME} \
        -destination "generic/platform=iOS" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}" \
        MACH_O_TYPE=staticlib \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
    # iOS Simulator  
    xcodebuild build \
        -scheme ${FRAMEWORK_NAME} \
        -destination "generic/platform=iOS Simulator" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}" \
        MACH_O_TYPE=staticlib \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
    # Library 찾기
    DEVICE_LIB=$(find ${BUILD_DIR} -name "lib${FRAMEWORK_NAME}.a" -path "*/Release-iphoneos/*" | head -1)
    SIM_LIB=$(find ${BUILD_DIR} -name "lib${FRAMEWORK_NAME}.a" -path "*/Release-iphonesimulator/*" | head -1)
    
    if [ -n "$DEVICE_LIB" ] && [ -n "$SIM_LIB" ]; then
        echo "📚 Creating fat library..."
        lipo -create "${DEVICE_LIB}" "${SIM_LIB}" -output "${OUTPUT_DIR}/lib${FRAMEWORK_NAME}.a"
        
        echo "✅ Static library created: ${OUTPUT_DIR}/lib${FRAMEWORK_NAME}.a"
    fi
fi