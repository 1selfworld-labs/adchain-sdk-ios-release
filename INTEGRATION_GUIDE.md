# AdchainSDK iOS 통합 가이드

## 개요
AdchainSDK는 iOS 앱에 광고 및 오퍼월 기능을 쉽게 통합할 수 있는 SDK입니다.

### 주요 기능
- 오퍼월 (Offerwall)
- 퀴즈 시스템 (Quiz)
- 미션 시스템 (Mission)
- 네이티브 광고 (Native Ad)
- 허브 (Hub)
- JavaScript Bridge를 통한 웹 연동

## 요구사항
- iOS 14.0 이상
- Swift 5.5 이상
- Xcode 13.0 이상

## 설치 방법

### 1. CocoaPods

Podfile에 다음 라인을 추가하세요:

```ruby
pod 'AdchainSDK', '~> 1.0.0'
```

그런 다음 터미널에서 실행:
```bash
pod install
```

### 2. Swift Package Manager

Xcode에서:
1. File → Add Package Dependencies 선택
2. 저장소 URL 입력: `https://github.com/adchain/adchain-ios-sdk.git`
3. 버전 규칙 선택: Up to Next Major Version → 1.0.0
4. Add Package 클릭

또는 Package.swift에 직접 추가:

```swift
dependencies: [
    .package(url: "https://github.com/adchain/adchain-ios-sdk.git", from: "1.0.0")
]
```

## 초기화

### 1. Info.plist 설정

앱의 Info.plist에 다음 권한을 추가하세요:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>광고 최적화를 위해 사용자 활동을 추적합니다.</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 2. SDK 초기화

AppDelegate.swift 또는 앱 시작 지점에서:

```swift
import AdchainSDK

// AppDelegate.swift
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // SDK 설정
    let config = AdchainSdkConfig(
        appKey: "YOUR_APP_KEY",
        appSecretKey: "YOUR_SECRET_KEY",
        hostAppId: "YOUR_HOST_APP_ID"
    )
    
    // 사용자 정보 설정
    let user = AdchainSdkUser(
        userId: "USER_ID",
        userBirthYear: 1990,
        userGender: .male // .male, .female, .other
    )
    
    // SDK 초기화
    AdchainSdk.shared.initialize(
        config: config,
        user: user,
        loginListener: self
    )
    
    return true
}

// 로그인 리스너 구현
extension AppDelegate: AdchainSdkLoginListener {
    func onLogin() {
        // 로그인 필요 시 처리
        // 예: 로그인 화면으로 이동
    }
}
```

## 주요 기능 사용법

### 1. 오퍼월 (Offerwall)

```swift
import AdchainSDK

class OfferwallViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 오퍼월 표시
        let offerwall = AdchainOfferwall()
        
        // WebView 설정
        offerwall.setupWebView(
            parentView: self.view,
            delegate: self
        )
        
        // 오퍼월 로드
        offerwall.load()
    }
}

// 오퍼월 이벤트 처리
extension OfferwallViewController: AdchainOfferwallDelegate {
    func onOfferwallLoaded() {
        print("오퍼월 로드 완료")
    }
    
    func onOfferwallLoadFailed(error: Error) {
        print("오퍼월 로드 실패: \(error)")
    }
    
    func onOfferwallClosed() {
        print("오퍼월 닫힘")
        dismiss(animated: true)
    }
    
    func onRewardReceived(reward: Int) {
        print("리워드 획득: \(reward)")
    }
}
```

### 2. 퀴즈 시스템

```swift
import AdchainSDK

class QuizViewController: UIViewController {
    
    private let quiz = AdchainQuiz()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 퀴즈 이벤트 리스너 설정
        quiz.setEventsListener(self)
        
        // 퀴즈 뷰 바인딩
        let quizView = UIView() // 퀴즈를 표시할 뷰
        quiz.bindView(quizView)
        
        // 퀴즈 시작
        quiz.start()
    }
}

// 퀴즈 이벤트 처리
extension QuizViewController: AdchainQuizEventsListener {
    func onQuizStart(quiz: QuizResponse) {
        print("퀴즈 시작: \(quiz.title)")
    }
    
    func onQuizComplete(correct: Bool, reward: Int?) {
        print("퀴즈 완료 - 정답: \(correct), 리워드: \(reward ?? 0)")
    }
    
    func onQuizError(error: Error) {
        print("퀴즈 오류: \(error)")
    }
}
```

### 3. 미션 시스템

```swift
import AdchainSDK

class MissionViewController: UIViewController {
    
    private let mission = AdchainMission()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 미션 리스너 설정
        mission.setEventsListener(self)
        
        // 미션 목록 가져오기
        mission.fetchMissions()
    }
    
    // 미션 시작
    func startMission(missionId: String) {
        mission.start(missionId: missionId)
    }
    
    // 미션 완료 체크
    func checkMissionCompletion(missionId: String) {
        mission.checkCompletion(missionId: missionId)
    }
}

// 미션 이벤트 처리
extension MissionViewController: AdchainMissionEventsListener {
    func onMissionsLoaded(missions: [Mission]) {
        print("미션 목록 로드: \(missions.count)개")
    }
    
    func onMissionStarted(mission: Mission) {
        print("미션 시작: \(mission.title)")
    }
    
    func onMissionCompleted(mission: Mission, reward: Int) {
        print("미션 완료: \(mission.title), 리워드: \(reward)")
    }
    
    func onMissionProgress(mission: Mission, progress: MissionProgress) {
        print("미션 진행률: \(progress.percentage)%")
    }
}
```

### 4. 네이티브 광고

```swift
import AdchainSDK

class NativeAdViewController: UIViewController {
    
    @IBOutlet weak var adContainerView: UIView!
    private let nativeAd = AdchainNativeAd()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 네이티브 광고 로드
        nativeAd.load(placementId: "YOUR_PLACEMENT_ID") { [weak self] result in
            switch result {
            case .success(let adView):
                // 광고 뷰를 컨테이너에 추가
                self?.adContainerView.addSubview(adView)
                adView.frame = self?.adContainerView.bounds ?? .zero
                
            case .failure(let error):
                print("광고 로드 실패: \(error)")
            }
        }
    }
}
```

### 5. 허브 (Hub)

```swift
import AdchainSDK

class HubViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 허브 표시
        let hub = AdchainHub()
        
        // 허브 설정
        hub.configure(
            parentView: self.view,
            position: .bottomRight, // 위치 설정
            size: CGSize(width: 60, height: 60)
        )
        
        // 허브 표시
        hub.show()
        
        // 허브 클릭 이벤트
        hub.onHubClicked = {
            print("허브 클릭됨")
            // 오퍼월이나 다른 화면으로 이동
        }
    }
}
```

## 고급 설정

### 사용자 정보 업데이트

```swift
// 사용자 정보 변경 시
let updatedUser = AdchainSdkUser(
    userId: "NEW_USER_ID",
    userBirthYear: 1995,
    userGender: .female
)

AdchainSdk.shared.updateUser(updatedUser)
```

### 이벤트 추적

```swift
// 커스텀 이벤트 추적
AdchainSdk.shared.trackEvent(
    eventName: "purchase_completed",
    parameters: [
        "item_id": "12345",
        "price": 9.99,
        "currency": "USD"
    ]
)
```

### 디버그 모드

```swift
// 개발 중 디버그 로그 활성화
AdchainSdk.shared.setDebugMode(true)
```

## 주의사항

1. **앱 심사**: App Store 제출 시 광고 식별자 사용에 대한 설명을 제공해야 합니다.

2. **개인정보 보호**: 
   - iOS 14.5+ 에서는 ATT(App Tracking Transparency) 권한을 요청해야 합니다.
   - 사용자 동의를 받은 후에만 광고 식별자를 수집하세요.

3. **메모리 관리**: 
   - 오퍼월이나 광고 뷰를 사용하지 않을 때는 적절히 해제하세요.
   - 강한 참조 순환을 피하기 위해 delegate는 weak으로 선언하세요.

4. **네트워크**: 
   - SDK는 인터넷 연결이 필요합니다.
   - 오프라인 상태 처리를 구현하세요.

## 문제 해결

### 자주 발생하는 문제

#### 1. SDK 초기화 실패
- App Key와 Secret Key가 올바른지 확인
- 네트워크 연결 상태 확인
- Info.plist 권한 설정 확인

#### 2. 오퍼월이 표시되지 않음
- 사용자 정보가 올바르게 설정되었는지 확인
- WebView 권한 확인
- 콘솔 로그에서 에러 메시지 확인

#### 3. 리워드를 받지 못함
- 서버 콜백 URL 설정 확인
- 사용자 ID가 일관되게 사용되는지 확인

## 지원

- 이메일: support@adchain.com
- 문서: https://docs.adchain.com
- GitHub Issues: https://github.com/adchain/adchain-ios-sdk/issues

## 라이선스

AdchainSDK는 MIT 라이선스 하에 배포됩니다.