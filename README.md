# AdChain SDK for iOS

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS-blue.svg" alt="Platform iOS" />
  <img src="https://img.shields.io/badge/iOS-14.0%2B-blue.svg" alt="iOS 14.0+" />
  <img src="https://img.shields.io/badge/Swift-5.5%2B-orange.svg" alt="Swift 5.5+" />
  <img src="https://img.shields.io/badge/version-1.0.14-green.svg" alt="Version 1.0.14" />
  <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="License MIT" />
</p>

AdChain SDK는 iOS 애플리케이션에 광고 및 리워드 기능을 쉽게 통합할 수 있는 종합 광고 솔루션입니다.

> **🔒 보안 강화**: v1.0.13부터 소스 코드가 공개되지 않으며, XCFramework 바이너리만 제공됩니다.

## 주요 기능

- 📱 **오퍼월(Offerwall)**: WebView 기반의 리워드 광고 시스템
- 🎯 **미션(Mission)**: 사용자 참여형 미션 시스템
- ❓ **퀴즈(Quiz)**: 인터랙티브 퀴즈 광고
- 🎨 **배너 광고**: 네이티브 배너 광고 지원
- 🌉 **JavaScript Bridge**: 웹-네이티브 완벽한 통신
- 🔒 **Privacy Manifest**: Apple 개인정보 보호 정책 준수

## 요구사항

- iOS 14.0 이상
- Xcode 14.0 이상
- Swift 5.5 이상

## 설치

### CocoaPods

```ruby
# Podfile
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  # CocoaPods Trunk에서 설치 (권장)
  pod 'AdChainSDK', '~> 1.0.14'

  # 또는 Git 저장소에서 직접 설치
  # pod 'AdChainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => 'v1.0.14'
end
```

```bash
pod install
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", from: "1.0.14")
]
```

### 수동 설치

1. [최신 릴리즈](https://github.com/1selfworld-labs/adchain-sdk-ios-release/releases)에서 `AdChainSDK.xcframework` 다운로드
2. Xcode 프로젝트에 드래그 앤 드롭
3. Target → General → Frameworks, Libraries, and Embedded Content에서 "Embed & Sign" 선택

## 빠른 시작

### 1. SDK 초기화

```swift
import AdChainSDK

// AppDelegate.swift 또는 App.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    let config = AdchainSdkConfig(
        appKey: "YOUR_APP_KEY",
        appSecret: "YOUR_APP_SECRET"
    )

    AdchainSdk.shared.initialize(
        application: application,
        sdkConfig: config
    )

    return true
}
```

### 2. 사용자 로그인

```swift
let user = AdchainSdkUser(
    userId: "user123",
    gender: .male,
    birthYear: 1990
)

AdchainSdk.shared.login(
    adchainSdkUser: user,
    listener: self  // AdchainSdkLoginListener 구현
)
```

```swift
// AdchainSdkLoginListener 구현
extension YourViewController: AdchainSdkLoginListener {
    func onSuccess() {
        print("로그인 성공")
    }

    func onFailure(_ error: AdchainError) {
        print("로그인 실패: \(error)")
    }
}
```

### 3. 오퍼월 표시

```swift
let offerwallVC = AdchainOfferwallViewController()
offerwallVC.callback = self  // OfferwallCallback 구현
present(offerwallVC, animated: true)
```

```swift
// OfferwallCallback 구현
extension YourViewController: OfferwallCallback {
    func onFinish() {
        print("오퍼월 종료")
    }
}
```

## 고급 기능

### 미션 시스템

```swift
let mission = AdchainMission(unitId: "YOUR_MISSION_UNIT_ID")

// 미션 로드
mission.load(
    onSuccess: { missions, progress in
        print("미션 로드 성공: \(missions.count)개")
        print("진행 상황: \(progress.completedCount)/\(progress.totalCount)")
    },
    onFailure: { error in
        print("미션 로드 실패: \(error)")
    }
)

// 미션 표시
mission.show(from: self)
```

### 퀴즈 광고

```swift
let quiz = AdchainQuiz(unitId: "YOUR_QUIZ_UNIT_ID")

// 퀴즈 로드
quiz.load(
    onSuccess: { quizList in
        print("퀴즈 로드 성공: \(quizList.count)개")
    },
    onFailure: { error in
        print("퀴즈 로드 실패: \(error)")
    }
)

// 퀴즈 표시
quiz.show(from: self)
```

### 배너 광고

```swift
let bannerView = AdchainBannerView(unitId: "YOUR_BANNER_UNIT_ID")
bannerView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
view.addSubview(bannerView)

// 배너 로드
bannerView.load()
```

### 이벤트 리스너

```swift
// 미션 이벤트 리스너
mission.eventsListener = self

extension YourViewController: AdchainMissionEventsListener {
    func onMissionCompleted(_ mission: Mission) {
        print("미션 완료: \(mission.title)")
    }

    func onRewardEarned(_ amount: Int) {
        print("리워드 획득: \(amount)")
    }
}
```

## Info.plist 설정

앱의 `Info.plist`에 다음 권한을 추가하세요:

```xml
<!-- 광고 추적 권한 -->
<key>NSUserTrackingUsageDescription</key>
<string>맞춤형 광고 제공을 위해 광고 식별자를 사용합니다.</string>

<!-- 네트워크 권한 (필요시) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 프로 가드 설정 (선택사항)

SDK의 난독화를 원하지 않는 경우:

```
-keep class com.adchain.sdk.** { *; }
```

## 문제 해결

### 오퍼월이 표시되지 않는 경우

1. SDK 초기화가 완료되었는지 확인
2. 사용자 로그인이 성공했는지 확인
3. 네트워크 연결 상태 확인
4. App Key와 App Secret이 올바른지 확인

### 미션/퀴즈 로드 실패

- `unitId`가 올바른지 확인
- 서버에서 해당 유닛이 활성화되어 있는지 확인

### WebView 관련 이슈

- iOS 14 이상에서 WKWebView 사용 확인
- JavaScript 활성화 여부 확인

## 마이그레이션 가이드

### 1.0.13 → 1.0.14

주요 변경사항:
- **🔄 모듈명 통일**: `import AdChainSDK` (capital C) 사용
- 이전 버전의 `import AdchainSDK` 문제 해결
- 모든 설정에서 일관된 이름 사용

업데이트 방법:
```bash
pod update AdChainSDK
```

## 샘플 앱

완전한 구현 예제는 [샘플 앱 저장소](https://github.com/1selfworld-labs/adchain-sdk-ios-example)를 참조하세요.

## API 문서

상세한 API 문서는 [공식 문서 사이트](https://docs.adchain.com/ios)를 참조하세요.

## 지원

- 이메일: dev@1selfworld.com
- 이슈 트래커: [GitHub Issues](https://github.com/1selfworld-labs/adchain-sdk-ios-release/issues)
- 기술 문서: [개발자 포털](https://developers.adchain.com)

## 라이선스

AdChain SDK는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 변경 이력

### 1.0.14 (2025-09-16)
- **모듈명 통일**: AdChainSDK (capital C)
- import 문 일관성 개선
- 빌드 설정 최적화

### 1.0.13 (2025-09-16)
- **보안 강화**: 소스 코드를 비공개로 전환
- XCFramework 바이너리 전용 배포
- CocoaPods Trunk 공식 배포
- 구현 세부사항 보호

### 1.0.12 (2025-09-16)
- WebView Safe Area 처리 개선
- 하단 고정 요소 렌더링 버그 수정
- 오퍼월 UI 안정성 향상

### 1.0.11 (2025-09-15)
- 미션 및 오퍼월 기능 업데이트
- 성능 최적화

### 1.0.10
- 퀴즈 시스템 추가
- JavaScript Bridge 기능 강화

전체 변경 이력은 [CHANGELOG.md](CHANGELOG.md)를 참조하세요.

---

<p align="center">
  Made with ❤️ by 1selfworld Labs
</p>