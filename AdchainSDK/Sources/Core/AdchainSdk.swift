import UIKit
import Foundation

@objc public final class AdchainSdk: NSObject {
    // MARK: - SDK Version
    private static let SDK_VERSION = "1.0.1"
    
    // MARK: - Singleton (Android의 object와 동일)
    @objc public static let shared = AdchainSdk()
    
    // MARK: - Properties
    private let isInitialized = AtomicBoolean(false)
    private weak var application: UIApplication?
    private var config: AdchainSdkConfig?
    private var currentUser: AdchainSdkUser?
    private var validatedAppData: AppData?
    private let handler = DispatchQueue.main
    private let coroutineScope = DispatchQueue(label: "com.adchain.sdk.main", qos: .userInitiated)
    
    private override init() {
        super.init()
    }
    
    @objc public func initialize(
        application: UIApplication,
        sdkConfig: AdchainSdkConfig
    ) {
        guard !isInitialized.get() else {
            fatalError("AdchainSdk is already initialized")
        }
        guard !sdkConfig.appKey.isEmpty else {
            fatalError("App Key cannot be empty")
        }
        guard !sdkConfig.appSecret.isEmpty else {
            fatalError("App Secret cannot be empty")
        }
        
        self.application = application
        self.config = sdkConfig
        
        // Initialize network manager
        NetworkManager.shared.initialize()
        
        // Validate app asynchronously (Android와 동일)
        coroutineScope.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                do {
                    let result = try await NetworkManager.shared.validateApp()

                    // Store validated app data
                    self.validatedAppData = result.app
                    
                    // Mark as initialized immediately
                    self.isInitialized.set(true)

                    // 로컬 스토리지에 있는지 확인하고, 있으면 그 값을 사용, 없으면 빈문자열
                    _ = UserDefaults.standard.string(forKey: "currentUserId")
                                        
                    print("SDK validated successfully with server")
                    print("Offerwall URL: \(result.app?.adchainHubUrl ?? "")")
                } catch {
                    print("SDK validation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Login (Android와 동일한 중복 로그인 체크)
    public func login(
        adchainSdkUser: AdchainSdkUser,
        listener: AdchainSdkLoginListener? = nil
    ) {
        guard isInitialized.get() else {
            handler.async {
                listener?.onFailure(.notInitialized)
            }
            return
        }
        
        guard !adchainSdkUser.userId.isEmpty else {
            handler.async {
                listener?.onFailure(.invalidUserId)
            }
            return
        }
        
        // Android와 동일: 다른 유저로 로그인 시 기존 유저 로그아웃
        if let currentUser = currentUser, currentUser.userId != adchainSdkUser.userId {
            logout()
        }
        
        coroutineScope.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                // Set current user first (Android 주석: 통신 실패해도 유저 바인딩은 진행)
                self.currentUser = adchainSdkUser
                
                // 로컬 스토리지에 저장
                UserDefaults.standard.set(adchainSdkUser.userId, forKey: "currentUserId")

// Login to server (gender와 birthYear 포함)
                do {
                    let loginResponse = try await NetworkManager.shared.login(
                    userId: adchainSdkUser.userId,
                    eventName: "user_login",
                    sdkVersion: self.getSDKVersion(),
                    gender: adchainSdkUser.gender?.stringValue,  // Gender enum의 stringValue (M/F/O)
                    birthYear: adchainSdkUser.birthYear,  // birthYear 전달
                    category: "authentication",
                    properties: ["user_id": adchainSdkUser.userId])
                    print("Login successful: \(loginResponse.success)")
                } catch {
                    print("Login failed but continuing: \(error)")
                }
                
                
                // Track session start for DAU
                _ = try? await NetworkManager.shared.trackEvent(
                    userId: adchainSdkUser.userId,
                    eventName: "session_start",
                    sdkVersion: self.getSDKVersion(),
                    category: "session",
                    properties: [
                        "user_id": adchainSdkUser.userId,
                        "session_id": UUID().uuidString
                    ]
                )
                // Login successful
                await MainActor.run {
                    listener?.onSuccess()
                }
            }
        }
    }
    
    // MARK: - Logout
    @objc public func logout() {
        let userToLogout = currentUser
        if let user = userToLogout {
            // Track logout event before clearing user
            coroutineScope.async {
                Task {
                    _ = try? await NetworkManager.shared.trackEvent(
                        userId: user.userId,
                        eventName: "user_logout",
                        sdkVersion: self.getSDKVersion(),
                        category: "authentication",
                        properties: ["user_id": user.userId]
                    )
                }
            }
        }
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }
    
    // MARK: - Offerwall (Android와 완전 동일)
    public func openOfferwall(
        presentingViewController: UIViewController,
        callback: OfferwallCallback? = nil
    ) {
        // Check if SDK is initialized
        guard isInitialized.get() else {
            print("SDK not initialized")
            callback?.onError("SDK not initialized. Please initialize the SDK first.")
            return
        }
        
        // Check if user is logged in
        guard let currentUser = currentUser else {
            print("User not logged in")
            callback?.onError("User not logged in. Please login first.")
            return
        }
        
        // Check if offerwall URL is available
        guard let offerwallUrl = validatedAppData?.adchainHubUrl, !offerwallUrl.isEmpty else {
            print("Offerwall URL not available")
            callback?.onError("Offerwall URL not available. Please check your app configuration.")
            return
        }
        
        // Store callback in ViewController
        AdchainOfferwallViewController.setCallback(callback)
        
        // Create and present offerwall
        let offerwallVC = AdchainOfferwallViewController()
        offerwallVC.baseUrl = offerwallUrl
        offerwallVC.userId = currentUser.userId
        offerwallVC.appKey = config?.appKey
        offerwallVC.modalPresentationStyle = .fullScreen
        
        presentingViewController.present(offerwallVC, animated: true)
        
        // Notify callback
        callback?.onOpened()
        
        // Track event
        coroutineScope.async {
            Task {
                _ = try? await NetworkManager.shared.trackEvent(
                    userId: currentUser.userId,
                    eventName: "offerwall_opened",
                    sdkVersion: self.getSDKVersion(),
                    category: "offerwall",
                    properties: ["source": "sdk_api"]
                )
            }
        }
    }
    
    // MARK: - Getters
    @objc public var isLoggedIn: Bool {
        return currentUser != nil
    }
    
    public func getCurrentUser() -> AdchainSdkUser? {
        return currentUser
    }
    
    public func getConfig() -> AdchainSdkConfig? {
        return config
    }
    
    internal func getApplication() -> UIApplication? {
        return application
    }
    
    internal func requireInitialized() {
        guard isInitialized.get() else {
            fatalError("AdchainSdk must be initialized before use")
        }
    }
    
    // MARK: - Testing
    internal func resetForTesting() {
        isInitialized.set(false)
        application = nil
        config = nil
        currentUser = nil
        validatedAppData = nil
    }
    
    public func getSDKVersion() -> String {
        // 상수로 정의된 SDK 버전을 직접 반환
        // Bundle 정보를 읽을 수 없는 환경에서도 확실하게 동작
        return Self.SDK_VERSION
    }
}

// MARK: - Atomic Boolean (Android AtomicBoolean 구현)
private class AtomicBoolean {
    private var _value: Bool
    private let queue = DispatchQueue(label: "com.adchain.atomic", attributes: .concurrent)
    
    init(_ value: Bool) {
        self._value = value
    }
    
    func get() -> Bool {
        queue.sync { _value }
    }
    
    func set(_ value: Bool) {
        queue.async(flags: .barrier) {
            self._value = value
        }
    }
    
    var value: Bool {
        return get()
    }
}
