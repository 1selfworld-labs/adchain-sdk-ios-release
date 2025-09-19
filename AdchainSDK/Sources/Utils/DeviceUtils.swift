import UIKit
import AdSupport
import AppTrackingTransparency

enum DeviceUtils {
    // MARK: - Constants (Android와 동일)
    private static let prefsName = "adchain_sdk_prefs"
    private static let deviceIdKey = "device_id"
    // advertisingIdKey와 timestamp 제거 - 더 이상 영구 저장 안함

    // MARK: - Cache
    private static var cachedDeviceId: String?
    private static var cachedAdvertisingId: String?  // 앱 생명주기 동안만 유지
    private static var isAdvertisingIdInitialized = false  // 초기화 여부 추적
    
    // MARK: - Device ID (Android의 SharedPreferences를 UserDefaults로 대체)
    static func getDeviceId() -> String {
        // Check cache
        if let cached = cachedDeviceId {
            return cached
        }
        
        // Get from UserDefaults
        let defaults = UserDefaults.standard
        if let deviceId = defaults.string(forKey: deviceIdKey) {
            cachedDeviceId = deviceId
            return deviceId
        }
        
        // Generate new and save
        let newDeviceId = UUID().uuidString
        defaults.set(newDeviceId, forKey: deviceIdKey)
        cachedDeviceId = newDeviceId
        AdchainLogger.d("DeviceUtils", "Generated new device ID: \(newDeviceId)")
        return newDeviceId
    }
    
    // MARK: - Synchronous Initialize Advertising ID on App Launch
    static func initializeAdvertisingIdSync() {
        AdchainLogger.d("DeviceUtils", "[SYNC] Initializing advertising ID synchronously on app launch...")

        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus

            // 이미 결정된 상태면 즉시 처리
            if status == .authorized {
                cachedAdvertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                AdchainLogger.i("DeviceUtils", "[SYNC] Advertising ID authorized: \(String(cachedAdvertisingId!.prefix(8)))...")
            } else if status == .denied || status == .restricted {
                cachedAdvertisingId = "00000000-0000-0000-0000-000000000000"
                AdchainLogger.i("DeviceUtils", "[SYNC] Advertising ID denied/restricted, using zero ID")
            } else if status == .notDetermined {
                // 첫 실행시 - 일단 0값 설정
                cachedAdvertisingId = "00000000-0000-0000-0000-000000000000"
                AdchainLogger.i("DeviceUtils", "[SYNC] First launch - setting zero ID initially")

                // UI가 준비된 후 메인 스레드에서 권한 요청
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 앱이 활성 상태인지 확인
                    guard UIApplication.shared.applicationState == .active else {
                        AdchainLogger.w("DeviceUtils", "[ATT] App not active, will retry when app becomes active")

                        // 앱이 활성화될 때 다시 시도
                        NotificationCenter.default.addObserver(
                            forName: UIApplication.didBecomeActiveNotification,
                            object: nil,
                            queue: .main
                        ) { _ in
                            AdchainLogger.i("DeviceUtils", "[ATT] App became active, requesting tracking authorization")
                            requestTrackingAuthorizationOnce()
                        }
                        return
                    }

                    AdchainLogger.d("DeviceUtils", "[ATT] App is active, requesting tracking authorization after delay")
                    requestTrackingAuthorizationOnce()
                }
            }
        } else {
            // iOS 13 이하
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                cachedAdvertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                AdchainLogger.i("DeviceUtils", "[SYNC] iOS 13- Advertising ID enabled: \(String(cachedAdvertisingId!.prefix(8)))...")
            } else {
                cachedAdvertisingId = "00000000-0000-0000-0000-000000000000"
                AdchainLogger.i("DeviceUtils", "[SYNC] iOS 13- Advertising ID disabled, using zero ID")
            }
        }

        isAdvertisingIdInitialized = true
        AdchainLogger.i("DeviceUtils", "[SYNC] Advertising ID initialization complete")
    }

    // MARK: - Private helper for ATT request
    private static var hasRequestedTracking = false

    private static func requestTrackingAuthorizationOnce() {
        guard !hasRequestedTracking else {
            AdchainLogger.d("DeviceUtils", "[ATT] Already requested tracking authorization, skipping")
            return
        }
        hasRequestedTracking = true

        Task { @MainActor in
            AdchainLogger.d("DeviceUtils", "[ATT] Requesting tracking authorization on main thread...")

            if #available(iOS 14, *) {
                let newStatus = await ATTrackingManager.requestTrackingAuthorization()

                if newStatus == .authorized {
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    cachedAdvertisingId = idfa
                    AdchainLogger.i("DeviceUtils", "[ATT] Authorization granted, updated to real IDFA: \(String(idfa.prefix(8)))...")
                } else {
                    AdchainLogger.i("DeviceUtils", "[ATT] Authorization denied/restricted, keeping zero ID (status: \(newStatus.rawValue))")
                }

                // Remove observer if it was added
                NotificationCenter.default.removeObserver(
                    self,
                    name: UIApplication.didBecomeActiveNotification,
                    object: nil
                )
            }
        }
    }

    // MARK: - Advertising ID (IDFA)
    static func getAdvertisingId() async -> String {
        // 이미 초기화됨, 바로 반환
        // SDK initialize에서 동기적으로 초기화하므로 nil이 될 수 없음
        return cachedAdvertisingId ?? "00000000-0000-0000-0000-000000000000"
    }
    
    // MARK: - Device Information
    static func getOsVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    static func getDeviceModel() -> String {
        #if targetEnvironment(simulator)
            // For simulator, try to get the simulated device model
            if let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return simulatorModelIdentifier
            }
            // Fallback for older Xcode versions
            return "Simulator"
        #else
            // For real device
            var systemInfo = utsname()
            uname(&systemInfo)
            let modelCode = withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    String(validatingUTF8: $0)
                }
            }
            return modelCode ?? UIDevice.current.model
        #endif
    }
    
    static func getDeviceManufacturer() -> String {
        return "Apple"
    }
    
    // MARK: - Locale Information
    static func getCountryCode() -> String? {
        return Locale.current.regionCode  // e.g., "KR", "US"
    }
    
    static func getLanguageCode() -> String? {
        return Locale.current.languageCode  // e.g., "ko", "en"
    }
    
    // MARK: - App Installation Source
    static func getInstaller() -> String? {
        // iOS doesn't provide direct access to installer information
        // Can only detect if running in TestFlight or App Store
        
        #if DEBUG
            return "xcode"  // Debug build from Xcode
        #else
            // Check for TestFlight
            if let receiptURL = Bundle.main.appStoreReceiptURL {
                let receiptPath = receiptURL.path
                if receiptPath.contains("sandboxReceipt") {
                    return "testflight"
                }
            }
            
            // Check if running in simulator
            #if targetEnvironment(simulator)
                return "simulator"
            #else
                // Assume App Store for release builds
                return "appstore"
            #endif
        #endif
    }
    
    // MARK: - Ad Tracking Status
    static func isLimitAdTrackingEnabled() -> Bool {
        if #available(iOS 14, *) {
            // iOS 14+: Check ATT status
            let status = ATTrackingManager.trackingAuthorizationStatus
            return status != .authorized
        } else {
            // iOS 13 and below: Use deprecated property
            return !ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
    }
    
    // MARK: - Device Model Name Mapping
    static func getDeviceModelName() -> String {
        let modelCode = getDeviceModel()
        
        // Handle simulator
        if modelCode == "Simulator" || modelCode.contains("arm64") || modelCode.contains("x86_64") {
            #if targetEnvironment(simulator)
                // Try to get the simulated device name
                if ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] != nil {
                    // Continue to mapping below
                } else {
                    return "Simulator (\(UIDevice.current.model))"
                }
            #else
                // If somehow we get architecture name on real device
                return UIDevice.current.model
            #endif
        }
        
        // iPhone models mapping
        let modelMap: [String: String] = [
            // iPhone 16 series (2024)
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            
            // iPhone 15 series (2023)
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone15,4": "iPhone 15",
            
            // iPhone 14 series
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone14,7": "iPhone 14",
            
            // iPhone 13 series
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,5": "iPhone 13",
            "iPhone14,4": "iPhone 13 mini",
            
            // iPhone 12 series
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,2": "iPhone 12",
            "iPhone13,1": "iPhone 12 mini",
            
            // iPhone 11 series
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,1": "iPhone 11",
            
            // iPhone SE
            "iPhone14,6": "iPhone SE (3rd generation)",
            "iPhone12,8": "iPhone SE (2nd generation)",
            
            // iPad models (common ones)
            "iPad14,1": "iPad mini (6th generation)",
            "iPad13,18": "iPad (10th generation)",
            "iPad13,16": "iPad Air (5th generation)",
            "iPad14,5": "iPad Pro 12.9-inch (6th generation)",
            "iPad14,3": "iPad Pro 11-inch (4th generation)"
        ]
        
        // Return mapped name or original model code if not found
        return modelMap[modelCode] ?? modelCode
    }
    
    // MARK: - Clear Cache (테스트용)
    static func clearCache() {
        cachedDeviceId = nil
        cachedAdvertisingId = nil
        isAdvertisingIdInitialized = false
    }
}