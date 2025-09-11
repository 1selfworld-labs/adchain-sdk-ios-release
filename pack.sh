#!/usr/bin/env bash
set -euo pipefail

# ===== 설정값 =====
SCHEME="${SCHEME:-AdchainSDK}"
CONFIGURATION="${CONFIGURATION:-Release}"
VERSION="${VERSION:-1.0.0}"
OUTPUT_DIR="${OUTPUT_DIR:-./build_artifacts}"
PROJECT="${PROJECT:-AdchainSDK.xcodeproj}"
MIN_IOS="${MIN_IOS:-14.0}"

# ===== 공통 빌드 옵션 =====
COMMON_OPTS=(
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -project "$PROJECT"
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
  SKIP_INSTALL=NO
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGNING_REQUIRED=NO
  BUILD_ACTIVE_ARCH_ONLY=NO
  IPHONEOS_DEPLOYMENT_TARGET="$MIN_IOS"
)

# ===== 경로 =====
ARTIFACTS="$OUTPUT_DIR/$SCHEME-$VERSION"
IOS_ARCHIVE="$ARTIFACTS/ios.xcarchive"
SIM_ARCHIVE="$ARTIFACTS/sim.xcarchive"
XCFRAMEWORK_PATH="$ARTIFACTS/$SCHEME.xcframework"
ZIP_PATH="$ARTIFACTS/$SCHEME.xcframework.zip"
PODSPEC_PATH="$ARTIFACTS/$SCHEME.podspec"
README_PATH="$ARTIFACTS/README.md"

# ===== 시작 =====
echo "🚀 Automated XCFramework Build"
echo "================================"
echo "Version: $VERSION"
echo "Scheme: $SCHEME"
echo ""

# 1. XcodeGen으로 프로젝트 생성
echo "📝 Generating Xcode project with XcodeGen..."
xcodegen generate --spec project.yml --quiet

# 2. 출력 디렉토리 준비
rm -rf "$ARTIFACTS"
mkdir -p "$ARTIFACTS"

# 3. Clean
echo "🧹 Cleaning..."
xcodebuild clean "${COMMON_OPTS[@]}" >/dev/null 2>&1 || true

# 4. iOS Device용 Archive
echo "📦 Archiving for iOS Device (arm64)..."
xcodebuild archive \
  "${COMMON_OPTS[@]}" \
  -destination "generic/platform=iOS" \
  -archivePath "$IOS_ARCHIVE" \
  2>&1 | grep -E "^\*\*|error:" || true

# 5. iOS Simulator용 Archive
echo "📦 Archiving for iOS Simulator (x86_64, arm64)..."
xcodebuild archive \
  "${COMMON_OPTS[@]}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIM_ARCHIVE" \
  2>&1 | grep -E "^\*\*|error:" || true

# 6. Framework 경로 확인
IOS_FW="$IOS_ARCHIVE/Products/Library/Frameworks/$SCHEME.framework"
SIM_FW="$SIM_ARCHIVE/Products/Library/Frameworks/$SCHEME.framework"

# Archive가 framework를 생성하지 않았다면 다른 경로 시도
if [[ ! -d "$IOS_FW" ]]; then
  echo "🔍 Searching for iOS framework..."
  IOS_FW=$(find "$IOS_ARCHIVE" -name "$SCHEME.framework" -type d | head -1)
fi

if [[ ! -d "$SIM_FW" ]]; then
  echo "🔍 Searching for Simulator framework..."
  SIM_FW=$(find "$SIM_ARCHIVE" -name "$SCHEME.framework" -type d | head -1)
fi

if [[ ! -d "$IOS_FW" || ! -d "$SIM_FW" ]]; then
  echo "❌ Framework not found. Archive structure:"
  echo "iOS Archive:"
  find "$IOS_ARCHIVE" -type d -name "*.framework" 2>/dev/null || echo "  No frameworks found"
  echo "Simulator Archive:"
  find "$SIM_ARCHIVE" -type d -name "*.framework" 2>/dev/null || echo "  No frameworks found"
  exit 1
fi

# 7. XCFramework 생성
echo "🔗 Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$IOS_FW" \
  -framework "$SIM_FW" \
  -output "$XCFRAMEWORK_PATH"

# 8. ZIP 생성
echo "🗜️ Creating ZIP..."
(cd "$ARTIFACTS" && zip -qry "$(basename "$ZIP_PATH")" "$(basename "$XCFRAMEWORK_PATH")")

# 9. 체크섬 계산
echo "🔢 Computing checksum..."
CHECKSUM=$(swift package compute-checksum "$ZIP_PATH")

# 10. Podspec 생성
cat > "$PODSPEC_PATH" <<EOF
Pod::Spec.new do |s|
  s.name         = "$SCHEME"
  s.version      = "$VERSION"
  s.summary      = "$SCHEME Binary XCFramework"
  s.description  = "Compiled binary framework. No source code included."
  s.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  s.license      = { :type => "Proprietary", :text => "© 2024 1selfworld Labs" }
  s.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  s.platform     = :ios, "$MIN_IOS"
  s.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "$VERSION" }
  s.vendored_frameworks = "$SCHEME.xcframework"
  s.swift_version = "5.5"
end
EOF

# 11. README 생성
cat > "$README_PATH" <<EOF
# $SCHEME Binary XCFramework

Version: $VERSION
iOS Minimum: $MIN_IOS

## Installation

### CocoaPods
\`\`\`ruby
pod '$SCHEME', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '$VERSION'
\`\`\`

### Swift Package Manager (Binary)
\`\`\`swift
.binaryTarget(
  name: "$SCHEME",
  url: "https://github.com/1selfworld-labs/adchain-sdk-ios-release/releases/download/$VERSION/$SCHEME.xcframework.zip",
  checksum: "$CHECKSUM"
)
\`\`\`

## Verification

This is a compiled binary framework. No source code (.swift files) included.

© 2024 1selfworld Labs. All rights reserved.
EOF

# 12. 결과 확인
echo ""
echo "✅ SUCCESS! Binary XCFramework Created"
echo "========================================"
echo "📂 Location: $ARTIFACTS"
echo ""
echo "📦 Generated files:"
echo "   - $(basename "$XCFRAMEWORK_PATH")"
echo "   - $(basename "$ZIP_PATH")"
echo "   - $(basename "$PODSPEC_PATH")"
echo "   - $(basename "$README_PATH")"
echo ""
echo "🔑 Checksum: $CHECKSUM"
echo ""
echo "🔍 Verification (no source files):"
SWIFT_COUNT=$(find "$XCFRAMEWORK_PATH" -name "*.swift" 2>/dev/null | wc -l | xargs)
echo "   Swift files in XCFramework: $SWIFT_COUNT (should be 0)"
echo ""
echo "📤 Next steps:"
echo "1. cd $ARTIFACTS"
echo "2. Upload to GitHub Release or S3"
echo "3. Update podspec/Package.swift with actual URL"