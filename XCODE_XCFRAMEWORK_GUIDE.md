# 🎯 Xcode GUI로 진짜 바이너리 XCFramework 만들기

## 📋 전체 과정 Overview
1. Xcode에서 새 Framework 프로젝트 생성
2. 소스코드 복사
3. 빌드 설정
4. Archive & XCFramework 생성
5. GitHub에 업로드

---

## STEP 1: Framework 프로젝트 생성

### 1.1 Xcode 열기
```
1. Xcode 실행
2. "Create New Project" 선택 (또는 File → New → Project)
```

### 1.2 Framework 템플릿 선택
```
1. iOS 탭 선택
2. "Framework" 템플릿 선택 (Framework & Library 섹션)
3. "Next" 클릭
```

### 1.3 프로젝트 설정
```
Product Name: AdchainSDK
Team: (Your Team)
Organization Identifier: com.oneself
Bundle Identifier: com.oneself.AdchainSDK
Language: Swift
☐ Include Tests (체크 해제)
```

### 1.4 저장 위치
```
새 폴더 생성: AdchainSDKBinary
위치 선택 후 "Create"
```

---

## STEP 2: 소스코드 복사

### 2.1 Finder에서 소스 파일 준비
```bash
# 터미널에서 (소스 파일 목록 확인)
cd /Users/donghoon/Desktop/GIT/fly33499/ad-chain-sdk/adchain-sdk-ios
find AdchainSDK/Sources -name "*.swift" | wc -l
# 몇 개의 파일인지 확인
```

### 2.2 Xcode에 파일 추가
```
1. Xcode 왼쪽 Navigator에서 "AdchainSDK" 폴더 우클릭
2. "Add Files to AdchainSDK..." 선택
3. AdchainSDK/Sources 폴더 선택
4. Options:
   ✅ Copy items if needed
   ✅ Create groups
   ✅ AdchainSDK (target 체크)
5. "Add" 클릭
```

### 2.3 폴더 구조 정리
```
AdchainSDK/
├── AdchainSDK.h (자동 생성됨)
├── Sources/
│   ├── Core/
│   ├── Network/
│   ├── Offerwall/
│   └── ...
```

---

## STEP 3: 빌드 설정

### 3.1 프로젝트 설정 (클릭: 최상단 AdchainSDK)
```
1. TARGETS → AdchainSDK 선택
2. General 탭:
   - Deployment Info → iOS 14.0
   - Frameworks and Libraries → 추가:
     + UIKit.framework
     + WebKit.framework
     + AdSupport.framework
     + AppTrackingTransparency.framework
```

### 3.2 Build Settings 탭
```
검색창에 입력하여 설정:

1. "BUILD_LIBRARY_FOR_DISTRIBUTION" 검색
   → Build Libraries for Distribution = Yes

2. "SKIP_INSTALL" 검색
   → Skip Install = No

3. "DEFINES_MODULE" 검색
   → Defines Module = Yes

4. "SWIFT_VERSION" 검색
   → Swift Language Version = Swift 5

5. "VALID_ARCHS" 검색
   → Valid Architectures = arm64 x86_64
```

### 3.3 Public Headers 설정
```
1. Build Phases 탭
2. Headers 섹션 확인
3. Public에 AdchainSDK.h가 있는지 확인
```

---

## STEP 4: Archive & XCFramework 생성

### 4.1 Scheme 설정
```
1. 상단 툴바에서 AdchainSDK scheme 선택
2. Any iOS Device (arm64) 선택
```

### 4.2 Archive 생성
```
1. Product → Archive
2. 빌드 완료 대기 (1-2분)
3. Organizer 창이 자동으로 열림
```

### 4.3 XCFramework 생성
```
1. Organizer에서 방금 만든 Archive 선택
2. "Distribute App" 클릭
3. 선택 옵션:
   - "Custom" → Next
   - "Copy App" → Next
   - "XCFramework" 선택 → Next
   - Platforms: iOS + iOS Simulator 모두 체크
   - Next → Export
4. 저장 위치 선택: Desktop/AdchainXCFramework
```

---

## STEP 5: 결과 확인

### 5.1 생성된 파일 구조
```
AdchainXCFramework/
└── AdchainSDK.xcframework/
    ├── Info.plist
    ├── ios-arm64/
    │   └── AdchainSDK.framework/
    │       ├── AdchainSDK (바이너리 파일)
    │       ├── Headers/
    │       ├── Info.plist
    │       └── Modules/
    └── ios-arm64_x86_64-simulator/
        └── AdchainSDK.framework/
            └── (동일 구조)
```

### 5.2 바이너리 확인
```bash
# 터미널에서 확인
cd ~/Desktop/AdchainXCFramework
find . -name "*.swift"  # 결과 없어야 함 (소스코드 없음)
file AdchainSDK.xcframework/ios-arm64/AdchainSDK.framework/AdchainSDK
# 출력: Mach-O universal binary (바이너리 확인)
```

---

## STEP 6: GitHub에 업로드

### 6.1 배포 패키지 준비
```bash
# 1. ZIP 파일 생성
cd ~/Desktop/AdchainXCFramework
zip -r AdchainSDK.xcframework.zip AdchainSDK.xcframework

# 2. 배포 폴더 생성
mkdir AdchainSDKRelease
mv AdchainSDK.xcframework AdchainSDKRelease/
```

### 6.2 필수 파일 생성
```bash
cd AdchainSDKRelease

# README.md
cat > README.md << 'EOF'
# AdchainSDK for iOS (Binary Framework)

## Installation

### CocoaPods
```ruby
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
```

### Manual
1. Download AdchainSDK.xcframework
2. Drag into Xcode project
3. Embed & Sign

© 2024 1selfworld Labs - Binary Distribution
EOF

# Podspec
cat > AdchainSDK.podspec << 'EOF'
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "1.0.0"
  spec.summary      = "AdChain SDK Binary Framework"
  spec.homepage     = "https://github.com/1selfworld-labs/adchain-sdk-ios-release"
  spec.license      = { :type => "Proprietary" }
  spec.author       = "1selfworld Labs"
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", :tag => "1.0.0" }
  spec.vendored_frameworks = "AdchainSDK.xcframework"
end
EOF
```

### 6.3 Git Push
```bash
git init
git add .
git commit -m "Release v1.0.0 - Binary XCFramework"
git remote add origin https://github.com/1selfworld-labs/adchain-sdk-ios-release.git
git push -u origin main --force
git tag 1.0.0
git push origin 1.0.0
```

---

## ✅ 완료!

이제 진짜 바이너리 XCFramework가 만들어졌습니다:
- ❌ 소스코드 (.swift 파일) 없음
- ✅ 컴파일된 바이너리만 존재
- ✅ Headers와 Module 정보만 포함
- ✅ 리버스 엔지니어링 매우 어려움

---

## 🚨 주의사항

1. **빌드 에러 발생 시**
   - Import 구문 확인 (UIKit, WebKit 등)
   - Target Membership 확인
   - Swift Version 확인

2. **Archive 실패 시**
   - Scheme을 "Any iOS Device"로 설정했는지 확인
   - Build Settings에서 아키텍처 설정 확인

3. **XCFramework 생성 실패 시**
   - BUILD_LIBRARY_FOR_DISTRIBUTION = Yes 확인
   - 두 플랫폼 (Device, Simulator) 모두 체크했는지 확인

---

## 📱 테스트 방법

다른 프로젝트에서:
```ruby
# Podfile
pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
```

```swift
import AdchainSDK  // 작동하지만 소스코드는 볼 수 없음
```