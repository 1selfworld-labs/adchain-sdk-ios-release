# AdChain iOS SDK

Complete iOS SDK implementation for AdChain advertising platform, featuring offerwall, quiz, mission, and native ad systems.

## Features

- ✅ **Complete SDK Initialization** - Android-equivalent validation and session management
- ✅ **WebView with JavaScript Bridge** - Full webkit.messageHandlers implementation
- ✅ **Offerwall System** - Complete web-based offerwall with sub-webview stacking
- ✅ **Quiz Module** - Interactive quiz system with rewards
- ✅ **Mission Module** - Task-based engagement system
- ✅ **Native Ads** - High-performance native advertising
- ✅ **Hub System** - Centralized feature management
- ✅ **Device Utilities** - IDFA handling and device information

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/adchain/adchain-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'AdchainSDK', '~> 1.0.0'
```

## Quick Start

### 1. Initialize SDK

```swift
import AdchainSDK

// In AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    let config = AdchainSdkConfig.Builder(
        appId: "YOUR_APP_ID",
        appSecret: "YOUR_APP_SECRET"
    )
    .setEnvironment(.production)
    .setTimeout(30)
    .build()
    
    AdchainSdk.shared.initialize(
        application: application,
        sdkConfig: config
    )
    
    return true
}
```

### 2. User Login

```swift
let user = AdchainSdkUser(
    userId: "user_123",
    gender: .male,
    birthYear: 1990
)

AdchainSdk.shared.login(
    adchainSdkUser: user,
    listener: self
)
```

### 3. Open Offerwall

```swift
AdchainSdk.shared.openOfferwall(
    presentingViewController: self,
    callback: self
)
```

### 4. Load Quiz Events

```swift
let quiz = AdchainQuiz(unitId: "quiz_unit_1")
quiz.setQuizEventsListener(self)
quiz.load(
    onSuccess: { events in
        // Handle quiz events
    },
    onFailure: { error in
        // Handle error
    }
)
```

## Required Permissions

Add to your Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>

<key>NSUserTrackingUsageDescription</key>
<string>This app needs your permission to provide personalized ads.</string>
```

## Architecture

The SDK follows Android SDK architecture exactly:

- **Core Module**: SDK initialization, user management, configuration
- **Network Module**: API communication with retry and caching
- **Offerwall Module**: WebView-based offerwall with JavaScript bridge
- **Quiz Module**: Interactive quiz system
- **Mission Module**: Task completion system
- **Native Ad Module**: Native advertising integration
- **Hub Module**: Centralized feature management
- **Utils Module**: Device information and utilities

## JavaScript Bridge

The SDK implements complete webkit.messageHandlers for web communication:

```javascript
// Web to Native
webkit.messageHandlers.postMessage({
    type: "openWebView",
    data: { url: "https://..." }
});

// Supported message types:
// - openWebView
// - close
// - closeOpenWebView
// - externalOpenBrowser
// - quizCompleted
// - getUserInfo
```

## Testing

All modules include Android-equivalent validation logic:
- Duplicate initialization prevention
- Empty credential validation
- Async app validation
- User session management
- Event tracking

## Support

- iOS 14.0+
- Swift 5.5+
- Xcode 13+

## License

MIT