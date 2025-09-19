import UIKit
import Foundation

@objc public final class AdchainSdk: NSObject {
    // MARK: - SDK Version
    private static let SDK_VERSION = "1.0.19"
    
    // MARK: - Singleton (Android의 object와 동일)
    @objc public static let shared = AdchainSdk()
    
    // MARK: - Properties
    private let _isInitialized = AtomicBoolean(false)
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
        guard !_isInitialized.get() else {
            AdchainLogger.w("AdchainSdk", "SDK is already initialized. Ignoring duplicate initialization.")
            return
        }
        guard !sdkConfig.appKey.isEmpty else {
            AdchainLogger.e("AdchainSdk", "App Key cannot be empty. Initialization failed.")
            return
        }
        guard !sdkConfig.appSecret.isEmpty else {
            AdchainLogger.e("AdchainSdk", "App Secret cannot be empty. Initialization failed.")
            return
        }
        
        self.application = application
        self.config = sdkConfig
        
        // IDFA를 동기적으로 초기화 (앱 시작시 한 번만)
        DeviceUtils.initializeAdvertisingIdSync()
        AdchainLogger.i("AdchainSdk", "Advertising ID initialized synchronously")

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
                    self._isInitialized.set(true)

                    // 로컬 스토리지에 있는지 확인하고, 있으면 그 값을 사용, 없으면 빈문자열
                    _ = UserDefaults.standard.string(forKey: "currentUserId")
                                        
                    AdchainLogger.i("AdchainSdk", "SDK validated successfully with server")
                    AdchainLogger.i("AdchainSdk", "Offerwall URL: \(result.app?.adchainHubUrl ?? "")")
                } catch {
                    AdchainLogger.e("AdchainSdk", "SDK validation failed: \(error)", error)
                }
            }
        }
    }
    
    // MARK: - Login (Android와 동일한 중복 로그인 체크)
    public func login(
        adchainSdkUser: AdchainSdkUser,
        listener: AdchainSdkLoginListener? = nil
    ) {
        guard _isInitialized.get() else {
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
                    AdchainLogger.i("AdchainSdk", "Login successful: \(loginResponse.success)")
                } catch {
                    AdchainLogger.w("AdchainSdk", "Login failed but continuing: \(error)")
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
        guard _isInitialized.get() else {
            AdchainLogger.w("AdchainSdk", "SDK not initialized")
            callback?.onError("SDK not initialized. Please initialize the SDK first.")
            return
        }
        
        // Check if user is logged in
        guard let currentUser = currentUser else {
            AdchainLogger.w("AdchainSdk", "User not logged in")
            callback?.onError("User not logged in. Please login first.")
            return
        }
        
        // Check if offerwall URL is available
        guard let offerwallUrl = validatedAppData?.adchainHubUrl, !offerwallUrl.isEmpty else {
            AdchainLogger.w("AdchainSdk", "Offerwall URL not available")
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
    
    // MARK: - Offerwall with Custom URL
    /// Opens the offerwall with a custom URL
    /// - Parameters:
    ///   - url: The custom URL to open in the offerwall WebView
    ///   - presentingViewController: The view controller to present the offerwall from
    ///   - callback: Optional callback for offerwall events
    public func openOfferwallWithUrl(
        _ url: String,
        presentingViewController: UIViewController,
        callback: OfferwallCallback? = nil
    ) {
        // Check if SDK is initialized
        guard _isInitialized.get() else {
            AdchainLogger.w("AdchainSdk", "SDK not initialized")
            callback?.onError("SDK not initialized. Please initialize the SDK first.")
            return
        }

        // Check if user is logged in
        guard let currentUser = currentUser else {
            AdchainLogger.w("AdchainSdk", "User not logged in")
            callback?.onError("User not logged in. Please login first.")
            return
        }

        // Validate URL
        guard !url.isEmpty else {
            AdchainLogger.w("AdchainSdk", "URL is empty")
            callback?.onError("URL cannot be empty")
            return
        }

        // Store callback in ViewController
        AdchainOfferwallViewController.setCallback(callback)

        // Create and present offerwall with custom URL
        let offerwallVC = AdchainOfferwallViewController()
        offerwallVC.baseUrl = url
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
                    eventName: "custom_offerwall_opened",
                    sdkVersion: self.getSDKVersion(),
                    category: "offerwall",
                    properties: [
                        "source": "sdk_api",
                        "url": url
                    ]
                )
            }
        }
    }

    // MARK: - External Browser
    /// Opens a URL in the system's default external browser
    /// - Parameter url: The URL to open in the external browser
    /// - Returns: true if browser was opened successfully, false otherwise
    @discardableResult
    public func openExternalBrowser(_ url: String) -> Bool {
        // Validate URL
        guard !url.isEmpty else {
            AdchainLogger.w("AdchainSdk", "URL is empty")
            return false
        }

        guard let browserUrl = URL(string: url) else {
            AdchainLogger.w("AdchainSdk", "Invalid URL format: \(url)")
            return false
        }

        guard UIApplication.shared.canOpenURL(browserUrl) else {
            AdchainLogger.w("AdchainSdk", "Cannot open URL: \(url)")
            return false
        }

        // Open URL in external browser
        UIApplication.shared.open(browserUrl, options: [:]) { success in
            if success {
                // Track event if user is logged in
                if let user = self.currentUser {
                    Task {
                        _ = try? await NetworkManager.shared.trackEvent(
                            userId: user.userId,
                            eventName: "external_browser_opened",
                            sdkVersion: self.getSDKVersion(),
                            category: "browser",
                            properties: [
                                "source": "sdk_api",
                                "url": url
                            ]
                        )
                    }
                }
            } else {
                AdchainLogger.w("AdchainSdk", "Failed to open external browser for URL: \(url)")
            }
        }

        return true
    }

    // MARK: - Getters
    @objc public func isInitialized() -> Bool {
        return _isInitialized.get()
    }

    @objc public var isLoggedIn: Bool {
        return currentUser != nil
    }

    public func getCurrentUser() -> AdchainSdkUser? {
        return currentUser
    }

    // MARK: - Logging Configuration
    /// Set the log level for SDK logs
    /// - Parameter level: The desired log level (NONE, ERROR, WARNING, INFO, DEBUG, VERBOSE)
    /// Default is WARNING for production safety
    @objc public static func setLogLevel(_ level: LogLevel) {
        AdchainLogger.logLevel = level
    }
    
    public func getConfig() -> AdchainSdkConfig? {
        return config
    }
    
    internal func getApplication() -> UIApplication? {
        return application
    }
    
    internal func requireInitialized() {
        guard _isInitialized.get() else {
            fatalError("AdchainSdk must be initialized before use")
        }
    }
    
    // MARK: - Testing
    internal func resetForTesting() {
        _isInitialized.set(false)
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

    // MARK: - Banner Info
    public func getBannerInfo(placementId: String, completion: @escaping (Result<BannerInfoResponse, Error>) -> Void) {
        guard _isInitialized.get() else {
            completion(.failure(NSError(
                domain: "AdchainSDK",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"]
            )))
            return
        }

        guard let user = currentUser else {
            completion(.failure(NSError(
                domain: "AdchainSDK",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
            )))
            return
        }

        Task {
            do {
                let response = try await NetworkManager.shared.getBannerInfo(
                    userId: user.userId,
                    placementId: placementId
                )
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
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
