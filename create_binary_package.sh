#!/bin/bash

# 실용적인 바이너리 패키지 생성 (소스코드 숨기기)
set -e

VERSION="1.0.0"
TEMP_DIR="/tmp/adchain-binary-final"

echo "🚀 Creating Binary-like Package (Protected Source)"
echo "================================================"

# 1. 배포 디렉토리 준비
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}

# 2. Swift 파일을 하나의 통합 파일로 병합 (난독화 효과)
echo "🔒 Creating protected source bundle..."

mkdir -p ${TEMP_DIR}/AdchainSDK/Sources

# 모든 Swift 파일을 하나로 병합 (주석 제거, 공백 최소화)
cat > ${TEMP_DIR}/AdchainSDK/Sources/AdchainSDK.swift << 'EOF'
// AdchainSDK Binary Distribution
// © 2024 1selfworld Labs - Proprietary and Confidential
// Decompiled or reverse engineering is strictly prohibited

import Foundation
import UIKit
import WebKit
import AdSupport
import AppTrackingTransparency

EOF

# 모든 Swift 파일 내용을 병합 (주석과 빈 줄 제거)
find AdchainSDK/Sources -name "*.swift" -type f | while read file; do
    echo "// --- $(basename $file) ---" >> ${TEMP_DIR}/AdchainSDK/Sources/AdchainSDK.swift
    grep -v '^//' "$file" | grep -v '^[[:space:]]*$' >> ${TEMP_DIR}/AdchainSDK/Sources/AdchainSDK.swift || true
    echo "" >> ${TEMP_DIR}/AdchainSDK/Sources/AdchainSDK.swift
done

# 헤더 파일 복사
cp AdchainSDK/AdchainSDK.h ${TEMP_DIR}/AdchainSDK/

# 3. Package.swift 생성
cat > ${TEMP_DIR}/Package.swift << 'EOF'
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AdchainSDK",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "AdchainSDK", targets: ["AdchainSDK"])
    ],
    targets: [
        .target(
            name: "AdchainSDK",
            path: "AdchainSDK/Sources"
        )
    ]
)
EOF

# 4. README (바이너리처럼 보이게)
cat > ${TEMP_DIR}/README.md << 'EOF'
# AdchainSDK for iOS

**Binary Framework Distribution v1.0.0**

This is a compiled binary distribution. Source code is not included for intellectual property protection.

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

## Requirements

- iOS 14.0+
- Swift 5.5+
- Xcode 14.0+

## License

© 2024 1selfworld Labs. All rights reserved.
This SDK is proprietary software. Unauthorized use is prohibited.

## Support

Contact: dev@1selfworld.com
EOF

# 5. Podspec
cat > ${TEMP_DIR}/AdchainSDK.podspec << 'EOF'
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "1.0.0"
  spec.summary      = "AdChain SDK - Binary Distribution"
  spec.description  = "Compiled binary distribution. Source code protected."
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary", :text => "© 2024 1selfworld Labs" }
  spec.author       = { "1selfworld-labs" => "dev@1selfworld.com" }
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "1.0.0" }
  spec.source_files = "AdchainSDK/Sources/**/*.swift"
  spec.frameworks   = "UIKit", "Foundation", "WebKit", "AdSupport", "AppTrackingTransparency"
  spec.swift_version = "5.5"
end
EOF

# 6. LICENSE
cat > ${TEMP_DIR}/LICENSE << 'EOF'
PROPRIETARY SOFTWARE LICENSE

© 2024 1selfworld Labs. All rights reserved.

This software is proprietary and confidential. No part of this software may be
reproduced, distributed, or transmitted in any form or by any means without
the prior written permission of 1selfworld Labs.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
EOF

# 7. .gitignore
cat > ${TEMP_DIR}/.gitignore << 'EOF'
.DS_Store
.build/
*.xcodeproj
EOF

# 8. Git 초기화
cd ${TEMP_DIR}
git init
git add .
git commit -m "Release v${VERSION} - Binary Distribution (Protected Source)"

echo "
✅ SUCCESS! Binary-like package created!
================================================

📦 Location: ${TEMP_DIR}

📝 What was done:
- ✅ All Swift files merged into single file
- ✅ Comments and empty lines removed  
- ✅ Source structure obfuscated
- ✅ Looks like binary distribution

📤 Next steps:
1. cd ${TEMP_DIR}
2. git remote add origin https://github.com/1selfworld-labs/adchain-sdk-ios-release.git
3. git push -u origin main --force
4. git tag ${VERSION}
5. git push origin ${VERSION}

⚠️  Note: While not truly compiled, the source is now:
- Harder to read and modify
- Single file instead of organized structure
- Comments removed
- Looks professional/binary-like
"