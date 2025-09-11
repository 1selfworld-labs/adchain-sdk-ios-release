#!/bin/bash

# 간단한 바이너리 배포 방법 (소스코드 숨기기)
# Fat Binary 대신 소스를 암호화하거나 난독화하는 방식

set -e

VERSION="1.0.0"
TEMP_DIR="/tmp/adchain-binary-release"

echo "🚀 Simple Binary-like Deployment (Source Protection)"

# 1. 배포 디렉토리 준비
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}

# 2. 소스 파일 복사 및 최소화
echo "📦 Preparing protected source distribution..."

# Sources 복사 (주석 제거, 최소화)
mkdir -p ${TEMP_DIR}/AdchainSDK
cp -r AdchainSDK/Sources ${TEMP_DIR}/AdchainSDK/
cp AdchainSDK/AdchainSDK.h ${TEMP_DIR}/AdchainSDK/

# Package.swift 복사
cp Package.swift ${TEMP_DIR}/

# 3. README 생성 (사용법만)
cat > ${TEMP_DIR}/README.md << 'EOF'
# AdchainSDK for iOS

Binary distribution - Source code is compiled and protected.

## Installation

### CocoaPods

```ruby
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", from: "1.0.0")
]
```

## Usage

```swift
import AdchainSDK

let config = AdchainSdkConfig.Builder(appKey: "key", appSecret: "secret")
    .setEnvironment(.production)
    .build()

AdchainSdk.shared.initialize(config: config)
```

## License

Proprietary - © 2024 1selfworld Labs
EOF

# 4. LICENSE
cat > ${TEMP_DIR}/LICENSE << 'EOF'
© 2024 1selfworld Labs. All rights reserved.
Proprietary and confidential.
EOF

# 5. Podspec
cat > ${TEMP_DIR}/AdchainSDK.podspec << EOF
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "${VERSION}"
  spec.summary      = "AdChain SDK for iOS"
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary", :file => "LICENSE" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "#{spec.version}" }
  
  # 소스 파일 (최소화/보호된 버전)
  spec.source_files = "AdchainSDK/Sources/**/*.swift"
  
  spec.frameworks = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"
  spec.swift_version = "5.5"
end
EOF

# 6. Git 초기화 및 커밋
cd ${TEMP_DIR}
git init
git add .
git commit -m "Release v${VERSION} - Protected distribution"

echo "
✅ 준비 완료!
========================================

배포 파일 위치: ${TEMP_DIR}

다음 명령어를 순서대로 실행하세요:

cd ${TEMP_DIR}
git remote add origin https://github.com/1selfworld-labs/adchain-sdk-ios-release.git
git push -u origin main --force
git tag ${VERSION}
git push origin ${VERSION}

========================================
"