# AdchainSDK iOS 배포 가이드

## 현재 프로젝트 상태

### ✅ 준비된 항목
1. **소스 코드 구조**
   - Core, Network, Quiz, Mission, Offerwall, NativeAd, Hub 모듈 구현
   - JavaScript Bridge 지원
   - 완전한 API 클라이언트 구현

2. **CocoaPods 설정**
   - `AdchainSDK.podspec` 파일 준비됨
   - 버전: 1.0.0
   - iOS 14.0+ 지원

3. **Swift Package Manager 설정**
   - `Package.swift` 파일 준비됨
   - Swift 5.5+ 지원

### ⚠️ 배포 전 필요한 작업

1. **라이선스 파일 추가**
   ```bash
   touch LICENSE
   # MIT 라이선스 내용 추가 필요
   ```

2. **리소스 파일 확인**
   - `AdchainSDK/Resources/` 디렉토리가 없음
   - 필요한 이미지, 폰트, 번들 리소스 추가 필요

3. **테스트 추가**
   - 단위 테스트 작성
   - 통합 테스트 작성

4. **문서화**
   - API 문서 생성
   - 샘플 프로젝트 준비

## 배포 방법

### 1. CocoaPods 배포

#### 준비 단계

1. **CocoaPods 계정 등록** (최초 1회)
   ```bash
   pod trunk register support@adchain.com 'AdChain' --description='AdChain SDK'
   ```

2. **이메일 확인**
   - CocoaPods에서 보낸 확인 이메일의 링크 클릭

3. **podspec 유효성 검사**
   ```bash
   pod lib lint AdchainSDK.podspec --allow-warnings
   ```

#### 배포 단계

1. **Git 태그 생성**
   ```bash
   git tag '1.0.0'
   git push origin '1.0.0'
   ```

2. **CocoaPods에 배포**
   ```bash
   pod trunk push AdchainSDK.podspec --allow-warnings
   ```

3. **배포 확인**
   ```bash
   pod search AdchainSDK
   ```

### 2. Swift Package Manager 배포

SPM은 Git 저장소를 직접 사용하므로 별도 배포 과정이 없습니다.

1. **GitHub 저장소 생성**
   - https://github.com/adchain/adchain-ios-sdk 생성

2. **코드 푸시**
   ```bash
   git init
   git add .
   git commit -m "Initial release v1.0.0"
   git remote add origin https://github.com/adchain/adchain-ios-sdk.git
   git push -u origin main
   ```

3. **릴리즈 생성**
   ```bash
   git tag 1.0.0
   git push origin 1.0.0
   ```

   또는 GitHub UI에서:
   - Releases → Create a new release
   - Tag: 1.0.0
   - Release title: AdchainSDK 1.0.0
   - 설명 추가 후 Publish

### 3. 수동 배포 (Framework)

XCFramework로 빌드하여 배포:

1. **XCFramework 빌드 스크립트**
   ```bash
   #!/bin/bash
   
   # 빌드 디렉토리 정리
   rm -rf build
   mkdir build
   
   # iOS 시뮬레이터용 빌드
   xcodebuild archive \
     -scheme AdchainSDK \
     -archivePath build/AdchainSDK-iphonesimulator.xcarchive \
     -sdk iphonesimulator \
     -configuration Release \
     SKIP_INSTALL=NO \
     BUILD_LIBRARY_FOR_DISTRIBUTION=YES
   
   # iOS 디바이스용 빌드
   xcodebuild archive \
     -scheme AdchainSDK \
     -archivePath build/AdchainSDK-iphoneos.xcarchive \
     -sdk iphoneos \
     -configuration Release \
     SKIP_INSTALL=NO \
     BUILD_LIBRARY_FOR_DISTRIBUTION=YES
   
   # XCFramework 생성
   xcodebuild -create-xcframework \
     -framework build/AdchainSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/AdchainSDK.framework \
     -framework build/AdchainSDK-iphoneos.xcarchive/Products/Library/Frameworks/AdchainSDK.framework \
     -output build/AdchainSDK.xcframework
   ```

2. **배포**
   - `AdchainSDK.xcframework`를 압축
   - GitHub Releases에 업로드
   - 다운로드 링크 제공

## 사용자가 SDK를 사용하는 방법

### CocoaPods 사용자

```ruby
# Podfile
platform :ios, '14.0'
use_frameworks!

target 'MyApp' do
  pod 'AdchainSDK', '~> 1.0.0'
end
```

```bash
pod install
```

### SPM 사용자

Xcode:
1. File → Add Package Dependencies
2. URL: `https://github.com/adchain/adchain-ios-sdk.git`
3. Version: 1.0.0

### 수동 통합 사용자

1. XCFramework 다운로드
2. Xcode 프로젝트에 드래그 앤 드롭
3. Target → General → Frameworks, Libraries, and Embedded Content에 추가
4. Embed & Sign 선택

## 버전 관리

### 시맨틱 버저닝
- **Major (1.x.x)**: 호환되지 않는 API 변경
- **Minor (x.1.x)**: 하위 호환 기능 추가
- **Patch (x.x.1)**: 하위 호환 버그 수정

### 업데이트 절차

1. 코드 변경
2. 버전 번호 업데이트:
   - `AdchainSDK.podspec`의 `spec.version`
   - `Package.swift`의 주석 (선택사항)
3. CHANGELOG.md 업데이트
4. Git 커밋 및 태그
5. 배포

## 배포 체크리스트

배포 전 확인사항:

- [ ] 모든 테스트 통과
- [ ] 문서 업데이트
- [ ] 버전 번호 업데이트
- [ ] CHANGELOG 작성
- [ ] 라이선스 파일 확인
- [ ] podspec lint 통과
- [ ] Swift Package 빌드 확인
- [ ] 샘플 프로젝트 테스트
- [ ] Git 태그 생성
- [ ] GitHub Release 생성

## 문제 해결

### CocoaPods 배포 실패

1. **권한 오류**
   ```bash
   pod trunk me  # 현재 세션 확인
   pod trunk add-owner AdchainSDK email@example.com  # 소유자 추가
   ```

2. **스펙 검증 실패**
   ```bash
   pod lib lint --verbose --no-clean  # 상세 로그 확인
   ```

### SPM 인식 안됨

1. Package.swift 문법 확인
2. Git 태그가 올바르게 푸시되었는지 확인
3. Xcode 캐시 정리: `~/Library/Caches/org.swift.swiftpm`

## 모니터링

### 사용 통계
- CocoaPods: https://cocoapods.org/pods/AdchainSDK
- GitHub: Insights 탭 확인
- 다운로드 수, 이슈, PR 모니터링

### 피드백 채널
- GitHub Issues
- 이메일: support@adchain.com
- Slack/Discord 커뮤니티