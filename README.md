# AdChain SDK for iOS

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS-blue.svg" alt="Platform iOS" />
  <img src="https://img.shields.io/badge/iOS-14.0%2B-blue.svg" alt="iOS 14.0+" />
  <img src="https://img.shields.io/badge/Swift-5.5%2B-orange.svg" alt="Swift 5.5+" />
  <img src="https://img.shields.io/badge/version-1.0.38-green.svg" alt="Version 1.0.38" />
  <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="License MIT" />
</p>

AdChain SDK는 iOS 애플리케이션에 광고 및 리워드 기능을 쉽게 통합할 수 있는 종합 광고 솔루션입니다.

> **🔒 보안 강화**: v1.0.13부터 소스 코드가 공개되지 않으며, XCFramework 바이너리만 제공됩니다.
> **📝 현재 버전**: v1.0.38 (2025-10-16)

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
  pod 'AdChainSDK', '~> 1.0.38'

  # 또는 Git 저장소에서 직접 설치
  # pod 'AdChainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.38'
end
```

```bash
pod install
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/1selfworld-labs/adchain-sdk-ios-release.git", from: "1.0.38")
]
```

### 수동 설치

1. [최신 릴리즈](https://github.com/1selfworld-labs/adchain-sdk-ios-release/releases)에서 `AdChainSDK.xcframework` 다운로드
2. Xcode 프로젝트에 드래그 앤 드롭
3. Target → General → Frameworks, Libraries, and Embedded Content에서 "Embed & Sign" 선택

## 빠른 시작

### 1. SDK 초기화

```swift
import AdchainSDK

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

### Adjoe 통합 (PlaytimeWeb)

AdChain SDK는 [adjoe PlaytimeWeb](https://docs.adjoe.io/)을 통합할 수 있습니다. adjoe는 사용자가 모바일 게임을 플레이하면서 리워드를 받을 수 있는 플랫폼입니다.

> **✅ iOS는 Web-based PlaytimeWeb 사용**
> - Native adjoe SDK 설치가 **필요 없습니다**
> - AdChain SDK만 설치하면 됩니다
> - 서버에서 PlaytimeWeb URL을 자동으로 제공합니다
> - 기존 WebView 인프라를 재사용합니다

#### 사용 방법

adjoe 오퍼월은 **별도의 SDK 설치 없이** AdChain SDK만으로 사용할 수 있습니다:

```swift
import AdchainSDK

// adjoe 오퍼월 표시 (추가 SDK 설치 불필요!)
AdchainSdk.shared.openAdjoeOfferwall(
    presentingViewController: self,
    placementId: "adjoe_main",
    callback: self  // OfferwallCallback 구현
)
```

#### 콜백 처리

```swift
extension YourViewController: OfferwallCallback {
    func onOpened() {
        print("Adjoe offerwall opened")
    }

    func onClosed() {
        print("Adjoe offerwall closed")
    }

    func onError(_ message: String) {
        print("Adjoe error: \(message)")
    }

    func onRewardEarned(_ amount: Int) {
        print("Adjoe reward earned: \(amount)")
    }
}
```

#### WebView에서 Adjoe 사용

AdChain WebView에서 JavaScript를 통해 adjoe 오퍼월을 열 수 있습니다:

```javascript
// JavaScript에서 호출
window.AdchainBridge.openAdjoeOfferwall('adjoe_main');
```

#### 서버 설정

adjoe 기능을 활성화하려면 서버 측에서 다음 정보를 설정해야 합니다:

- `adjoeEnabled`: adjoe 활성화 여부
- `adjoeUrl`: PlaytimeWeb URL (예: `https://your-app.playtimeweb.com/play`)

> **참고**:
> - 클라이언트 코드 변경은 필요 없습니다
> - 서버에서 adjoe 설정이 제공되면 자동으로 활성화됩니다
> - Native SDK 의존성이 없어 앱 크기 증가가 없습니다

### 미션 시스템

```swift
let mission = AdchainMission()

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
let quiz = AdchainQuiz()

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

## 테스트

> **⚠️ 현재 상태**: 단위 테스트가 아직 구현되지 않았습니다.
> 수동 테스트 및 예제 앱을 통한 통합 테스트를 권장합니다.

### 테스트 방법
1. 예제 앱 사용: [adchain-sdk-ios-example](https://github.com/1selfworld-labs/adchain-sdk-ios-example)
2. 수동 테스트: WebView 상호작용 및 JavaScript Bridge 기능
3. 통합 테스트: 실제 앱에 SDK 통합 후 테스트

## 보안 가이드라인

### API 키/시크릿 관리

1. **절대 하드코딩 금지**
   ```swift
   // ❌ 잘못된 예
   let config = AdchainSdkConfig(
       appKey: "abc123def456",  // 하드코딩된 키
       appSecret: "secret789"
   )

   // ✅ 올바른 예
   let config = AdchainSdkConfig(
       appKey: ConfigManager.shared.appKey,
       appSecret: ConfigManager.shared.appSecret
   )
   ```

2. **환경 변수 사용**
   - 개발/스테이징/프로덕션 환경별로 분리
   - `.xcconfig` 파일 또는 환경 변수 사용

3. **Git 저장소 보안**
   - `.gitignore`에 민감한 설정 파일 추가
   - 실수로 커밋된 경우 즉시 키 재발급

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

### 이전 버전 → 1.0.38

주요 변경사항:
- **🔄 모듈명 통일**: `import AdchainSDK` 사용
- adjoe 통합 개선 (gender/age 파라미터 지원)
- 앱 설치 감지 기능 추가
- Quiz/Mission API 개선
- 성능 최적화 및 버그 수정

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

### 1.0.38 (2025-10-16) - 현재 버전
- **XCFramework 최신 빌드**: 소스 저장소 v1.0.38 변경사항 반영
- **Package.swift 개선**: binaryTarget 사용으로 SPM 지원 강화
- **배포 프로세스 안정화**: CocoaPods 및 SPM 동시 지원

### 1.0.36 (2025-10-16)
- **adjoe 통합 개선**: gender/age 파라미터 지원 추가
- **앱 설치 감지**: URL scheme을 통한 앱 설치 여부 확인 기능
- **딥링크 지원**: App Store 링크 및 커스텀 URL scheme 지원
- **JavaScript Bridge 개선**: 웹-네이티브 통신 안정성 향상

### 1.0.35 (2025-10-12)
- **Quiz/Mission API 개선**: @objc 및 NSObject 상속 추가
- **Initializer 수정**: Non-optional initializer로 변경
- **CocoaPods 호환성**: API 가시성 문제 해결

### 1.0.34 (2025-10-12)
- XCFramework 바이너리 업데이트
- 안정성 개선

### 1.0.33 (2025-09-25)
- **버전 통합**: 모든 구성 요소의 버전을 1.0.33으로 통일
- **unitId 파라미터 복원**: React Native 호환성을 위해 unitId 파라미터 재추가
- **placementId 기능 추가**: 광고 위치 식별자 지원
- **이벤트 트래킹 개선**: 더 상세한 사용자 행동 추적

### 1.0.31 (2025-09-24)
- 성능 최적화
- 버그 수정

### 1.0.30 (2025-09-23)
- 네트워크 모듈 개선
- 오퍼월 UI 업데이트
- 디바이스 화면 해상도 정보 지원

### 이전 버전들
- v1.0.0 ~ v1.0.29: 초기 개발 및 안정화

상세한 변경 이력은 [CHANGELOG.md](CHANGELOG.md)를 참조하세요.

---

<p align="center">
  Made with ❤️ by 1selfworld Labs
</p>