#!/bin/bash

# 배포 스크립트 - Private 개발 레포에서 Public 배포 레포로 복사
# 사용법: ./deploy.sh 1.0.0

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "❌ Usage: ./deploy.sh <version>"
    echo "Example: ./deploy.sh 1.0.0"
    exit 1
fi

# 설정
RELEASE_REPO_URL="https://github.com/1selfworld-labs/adchain-sdk-ios-release.git"
TEMP_DIR="/tmp/adchain-sdk-release"

echo "🚀 Starting deployment for version $VERSION"

# 1. 임시 디렉토리 정리 및 생성
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# 2. Public 레포 클론 (없으면 새로 생성)
if ! git clone $RELEASE_REPO_URL $TEMP_DIR 2>/dev/null; then
    echo "📦 Creating new release repository..."
    mkdir -p $TEMP_DIR
    cd $TEMP_DIR
    git init
    git remote add origin $RELEASE_REPO_URL
    cd -
fi

# 3. 필요한 파일만 복사
echo "📄 Copying release files..."

# 소스코드 복사 (민감한 파일 제외)
cp -r AdchainSDK/Sources $TEMP_DIR/AdchainSDK/
cp AdchainSDK/AdchainSDK.h $TEMP_DIR/AdchainSDK/

# 필수 파일 복사
cp README.md $TEMP_DIR/
cp LICENSE $TEMP_DIR/
cp AdchainSDK.podspec $TEMP_DIR/
cp Package.swift $TEMP_DIR/

# .gitignore 생성
cat > $TEMP_DIR/.gitignore << EOF
.DS_Store
.build/
*.xcodeproj
xcuserdata/
DerivedData/
.swiftpm/
EOF

# 4. podspec 버전 업데이트
cd $TEMP_DIR
sed -i '' "s/spec.version.*=.*/spec.version      = \"$VERSION\"/" AdchainSDK.podspec

# 5. 커밋 및 푸시
git add .
git commit -m "Release version $VERSION" || echo "No changes to commit"
git tag -a $VERSION -m "Version $VERSION"

echo "📤 Pushing to public repository..."
git push origin main --force
git push origin $VERSION

# 6. CocoaPods 검증
echo "✅ Validating podspec..."
pod lib lint AdchainSDK.podspec --allow-warnings

echo "
========================================
✅ Deployment Complete!
========================================
Version: $VERSION
Repository: $RELEASE_REPO_URL

Users can now install using:
----------------------------------------
pod 'AdchainSDK', :git => '$RELEASE_REPO_URL', :tag => '$VERSION'
----------------------------------------

Or if you've published to CocoaPods trunk:
pod trunk push AdchainSDK.podspec
"

# 정리
cd -
rm -rf $TEMP_DIR