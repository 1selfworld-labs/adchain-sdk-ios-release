# iOS Framework 배포 가이드

## 🎯 Android AAR과 같은 방식으로 iOS SDK 배포하기

### 방법 1: XCFramework 직접 전달 (AAR과 가장 유사)

#### 빌드 방법
```bash
# 1. 빌드 스크립트 실행
./build_xcframework.sh

# 2. 생성된 파일
build/AdchainSDK.xcframework.zip  # 이 파일을 전달
```

#### 사용자가 설치하는 방법

**방법 A: 직접 Drag & Drop**
1. `AdchainSDK.xcframework.zip` 압축 해제
2. Xcode 프로젝트 열기
3. `AdchainSDK.xcframework`를 프로젝트에 드래그 앤 드롭
4. "Copy items if needed" 체크
5. Target의 "Frameworks, Libraries, and Embedded Content"에 추가
6. Embed 설정: "Embed & Sign"

**방법 B: 수동 설정**
1. 프로젝트 설정 > General > Frameworks
2. "+" 버튼 > Add Other > Add Files
3. `AdchainSDK.xcframework` 선택

### 방법 2: CocoaPods Local Path (팀 내부 공유)

#### podspec 수정
```ruby
# AdchainSDK.podspec
spec.source = { :path => '.' }  # Local path용으로 변경
```

#### 사용자 Podfile
```ruby
# Podfile
pod 'AdchainSDK', :path => '../path/to/AdchainSDK'
```

### 방법 3: Binary Distribution (가장 전문적)

#### 1. XCFramework를 서버/GitHub Release에 업로드
```bash
# GitHub Release에 업로드하거나
# S3, 회사 서버 등에 업로드
```

#### 2. Binary podspec 생성
```ruby
Pod::Spec.new do |spec|
  spec.name         = "AdchainSDK"
  spec.version      = "1.0.0"
  # ... 기타 설정 ...
  
  # Binary 배포용
  spec.vendored_frameworks = 'AdchainSDK.xcframework'
  spec.source = { 
    :http => 'https://your-server.com/AdchainSDK-1.0.0.xcframework.zip' 
  }
end
```

## 📦 Framework vs XCFramework

| 구분 | Framework | XCFramework |
|------|-----------|-------------|
| **지원** | 단일 아키텍처 | 여러 아키텍처 (Universal) |
| **시뮬레이터** | 별도 빌드 필요 | 포함 |
| **M1 Mac** | 추가 작업 필요 | 자동 지원 |
| **추천** | ❌ | ✅ |

## 🚀 가장 간단한 방법 (개발용)

```bash
# 1. XCFramework 빌드
./build_xcframework.sh

# 2. 생성된 ZIP 파일 전달
# build/AdchainSDK.xcframework.zip

# 3. 사용자는 압축 해제 후 Xcode에 드래그 앤 드롭
```

## 💡 Android AAR과 비교

| Android | iOS |
|---------|-----|
| AAR 파일 | XCFramework |
| `libs/` 폴더에 복사 | Xcode 프로젝트에 추가 |
| Gradle 의존성 | CocoaPods/SPM 또는 수동 |
| 단일 파일 | 폴더 구조 (zip 가능) |

## ⚡ 빠른 테스트용 명령

```bash
# XCFramework 빌드 및 ZIP 생성 (한 줄)
./build_xcframework.sh && echo "✅ Ready to share: build/AdchainSDK.xcframework.zip"
```

이제 `build/AdchainSDK.xcframework.zip` 파일을 
카카오톡, 이메일, USB 등으로 전달하면 됩니다!