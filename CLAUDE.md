# AdChain SDK iOS - 프로젝트 가이드

## 프로젝트 개요
AdChain SDK는 iOS 앱에 광고 및 오퍼월 기능을 제공하는 SDK입니다.

### 주요 기능
- Offerwall WebView 통합
- Quiz 및 Mission 시스템
- Native 광고 지원
- JavaScript Bridge를 통한 웹 통합
- Hub 중앙화 기능

## 프로젝트 구조

### 레포지토리 구조
```
- Private 개발 레포: https://github.com/1selfworld-labs/adchain-sdk-ios.git (소스코드)
- Public 배포 레포: https://github.com/1selfworld-labs/adchain-sdk-ios-release.git (바이너리)
```

### 디렉토리 구조
```
adchain-sdk-ios/
├── AdchainSDK/
│   ├── Sources/          # Swift 소스코드
│   ├── Info.plist        # Framework 정보
│   └── PrivacyInfo.xcprivacy  # Privacy Manifest
├── AdchainSDK.podspec    # CocoaPods 스펙
├── AdchainSDK.xcodeproj  # Xcode 프로젝트
└── build 스크립트들/      # 빌드 자동화
```

## 빌드 및 배포 가이드

### 버전 관리 체크리스트
배포 전 다음 파일들의 버전을 업데이트해야 합니다:
1. `AdchainSDK.podspec` - spec.version
2. `AdchainSDK/Info.plist` - CFBundleShortVersionString

### 배포 프로세스

#### 1. 버전 업데이트
```bash
# 1. podspec 버전 수정
vim AdchainSDK.podspec
# spec.version = "1.0.X"

# 2. Info.plist 버전 수정
vim AdchainSDK/Info.plist
# CFBundleShortVersionString: 1.0.X
```

#### 2. Privacy Manifest 확인
iOS 17+ 요구사항을 위한 PrivacyInfo.xcprivacy 파일이 다음 위치에 있는지 확인:
- `AdchainSDK/PrivacyInfo.xcprivacy`

#### 3. XCFramework 빌드
```bash
# 빌드 스크립트 실행
chmod +x build_xcframework.sh
./build_xcframework.sh

# 빌드 결과 확인
ls -la ./build/
# AdchainSDK.xcframework
# AdchainSDK.xcframework.zip
```

#### 4. Private 레포 커밋 및 푸시
```bash
# 변경사항 커밋
git add .
git commit -m "Release v1.0.X: [변경사항 설명]"

# 태그 생성
git tag -a 1.0.X -m "Version 1.0.X: [릴리즈 노트]"

# 푸시
git push origin main
git push origin 1.0.X
```

#### 5. Public Release 레포 배포
```bash
# 임시 디렉토리에서 작업
rm -rf /tmp/adchain-release
mkdir -p /tmp/adchain-release
cd /tmp/adchain-release

# Release 레포 클론
git clone https://github.com/1selfworld-labs/adchain-sdk-ios-release.git .

# XCFramework 복사
cp -r [원본경로]/build/AdchainSDK.xcframework ./

# Podspec 업데이트 (중요: 이름은 AdChainSDK - 대문자 C)
vim AdChainSDK.podspec  # 주의: 파일명도 대문자 C
# s.name = "AdChainSDK"  # 대문자 C 필수!
# s.version = "1.0.X"
# s.vendored_frameworks = "AdchainSDK.xcframework"

# 커밋 및 푸시
git add -A
git commit -m "Release v1.0.X: [변경사항]"
git tag -a 1.0.X -m "Version 1.0.X"
git push origin main
git push origin 1.0.X
```

#### 6. CocoaPods 배포
```bash
# Release 레포에서 실행
cd /tmp/adchain-release

# Pod 검증
pod lib lint AdChainSDK.podspec --allow-warnings

# CocoaPods trunk 푸시 (주의: 파일명 대문자 C)
pod trunk push AdChainSDK.podspec --allow-warnings
```

### 주의사항

#### Pod 이름 대소문자 문제
- **등록된 Pod 이름**: `AdChainSDK` (대문자 C)
- **Framework 이름**: `AdchainSDK` (소문자 c)
- **podspec 파일명**: `AdChainSDK.podspec` (대문자 C 필수!)
- podspec 내부의 `s.name`도 반드시 `"AdChainSDK"`로 설정

#### Privacy Manifest
- iOS 17+에서 필수
- 모든 빌드 스크립트가 자동으로 복사하도록 설정됨
- 수집 데이터: 이메일, 사용자 ID, 디바이스 ID, 광고 데이터
- API 접근: UserDefaults

#### 배포 권한
- CocoaPods trunk 세션 확인: `pod trunk me`
- 소유자: AdChain SDK <fly33499@gmail.com>

### 테스트 명령어

```bash
# 로컬 빌드 테스트
xcodebuild -scheme AdchainSDK -sdk iphonesimulator

# Pod 설치 테스트
pod install --repo-update

# Framework 검증
file build/AdchainSDK.xcframework/ios-arm64/AdchainSDK.framework/AdchainSDK
```

### 롤백 절차

문제 발생 시:
```bash
# Git 롤백
git reset --hard [이전커밋해시]
git push --force origin main

# CocoaPods yank (비추천, 최후의 수단)
pod trunk deprecate AdChainSDK
```

## 트러블슈팅

### "name is already taken" 오류
- Pod 이름 대소문자 확인
- 이미 등록된 버전인지 확인: `pod trunk info AdChainSDK`

### Privacy Manifest 누락
- 빌드 스크립트가 자동 복사하는지 확인
- 수동 복사: `cp AdchainSDK/PrivacyInfo.xcprivacy [target]/`

### CocoaPods 인증 실패
```bash
# 재인증
pod trunk register fly33499@gmail.com 'AdChain SDK' --description='AdChain iOS SDK'
```

## 연락처
- 개발팀: dev@1selfworld.com
- Pod 소유자: fly33499@gmail.com

---
최종 업데이트: 2025-09-08
현재 버전: 1.0.1