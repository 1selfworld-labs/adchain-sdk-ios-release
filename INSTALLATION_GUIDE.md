# AdchainSDK iOS 설치 가이드

## 📱 SDK 정보
- **Version**: 1.0.0
- **Repository**: https://github.com/1selfworld-labs/adchain-sdk-ios-release
- **최소 iOS 버전**: iOS 14.0+
- **Swift 버전**: 5.5+

## 🚀 설치 방법

### 방법 1: CocoaPods (추천)

#### 1. Podfile 생성 또는 수정

프로젝트 루트 디렉토리에 `Podfile`이 없다면 생성:
```bash
pod init
```

#### 2. Podfile에 SDK 추가

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourAppName' do
  # AdchainSDK 추가
  pod 'AdchainSDK', :git => 'https://github.com/1selfworld-labs/adchain-sdk-ios-release.git', :tag => '1.0.0'
  
  # 다른 의존성들...
end
```

#### 3. 설치

```bash
pod install
```

#### 4. Xcode 프로젝트 열기

⚠️ **중요**: `.xcworkspace` 파일을 열어야 합니다 (`.xcodeproj` 파일이 아님)
```bash
open YourAppName.xcworkspace
```

### 방법 2: Swift Package Manager

#### Xcode에서:
1. File → Add Package Dependencies
2. URL 입력: `https://github.com/1selfworld-labs/adchain-sdk-ios-release.git`
3. Version: 1.0.0
4. Add Package 클릭

## 💻 SDK 사용법

### 1. SDK Import

```swift
import AdchainSDK
```

### 2. 초기화

#### AppDelegate.swift (또는 SceneDelegate.swift)

```swift
import UIKit
import AdchainSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // AdchainSDK 초기화
        let config = AdchainSdkConfig.Builder(
            appKey: "YOUR_APP_KEY",        // 발급받은 App Key
            appSecret: "YOUR_APP_SECRET"    // 발급받은 App Secret
        )
        .setEnvironment(.production)       // .production, .staging, .development
        .setTimeout(30.0)                   // 선택사항: 타임아웃 (기본 30초)
        .build()
        
        AdchainSdk.shared.initialize(config: config)
        
        return true
    }
}
```

### 3. 로그인 처리

```swift
// 사용자 로그인
let user = AdchainSdkUser(
    userId: "user123",
    userName: "홍길동",
    userEmail: "user@example.com",
    userPhone: "010-1234-5678"
)

AdchainSdk.shared.login(user: user) { success, error in
    if success {
        print("로그인 성공")
    } else {
        print("로그인 실패: \(error?.localizedDescription ?? "")")
    }
}
```

### 4. Offerwall 표시

```swift
// ViewController에서
import AdchainSDK

class ViewController: UIViewController {
    
    @IBAction func showOfferwall(_ sender: UIButton) {
        // Offerwall ViewController 생성
        let offerwallVC = AdchainOfferwallViewController()
        
        // Callback 설정 (선택사항)
        offerwallVC.callback = OfferwallCallback(
            onRewardClaimed: { reward in
                print("리워드 획득: \(reward)")
            },
            onClose: {
                print("Offerwall 닫힘")
            }
        )
        
        // 전체화면으로 표시
        present(offerwallVC, animated: true)
    }
}
```

### 5. 이벤트 트래킹

```swift
// 커스텀 이벤트 전송
AdchainSdk.shared.trackEvent(
    eventName: "purchase_completed",
    category: "shopping",
    properties: [
        "item_id": "12345",
        "price": 29900,
        "currency": "KRW"
    ]
)
```

## 🔧 환경별 설정

### Development (개발)
```swift
.setEnvironment(.development)  // localhost:3000
```

### Staging (테스트)
```swift
.setEnvironment(.staging)      // staging-api.adchain.com
```

### Production (운영)
```swift
.setEnvironment(.production)   // adchain-api.1self.world
```

## 📋 필수 권한 설정

### Info.plist에 추가

```xml
<!-- 광고 추적 권한 (iOS 14+) -->
<key>NSUserTrackingUsageDescription</key>
<string>개인 맞춤 광고 제공을 위해 사용자의 활동을 추적합니다.</string>

<!-- 인터넷 사용 (이미 기본 허용) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

## 🚨 문제 해결

### Pod 설치 실패 시

```bash
# 캐시 정리
pod cache clean --all
pod deintegrate
pod install
```

### 빌드 오류 시

1. Clean Build Folder: Cmd + Shift + K
2. Derived Data 삭제: ~/Library/Developer/Xcode/DerivedData
3. Xcode 재시작

### Module not found 오류

```bash
# Pods 재설치
rm -rf Pods
rm Podfile.lock
pod install
```

## 📞 지원

- 이메일: dev@1selfworld.com
- GitHub Issues: https://github.com/1selfworld-labs/adchain-sdk-ios-release/issues

## 📄 라이센스

Copyright © 2024 1selfworld Labs. All rights reserved.