import UIKit
import AdSupport
import AppTrackingTransparency

enum DeviceUtils {
    // MARK: - Constants (Android와 동일)
    private static let prefsName = "adchain_sdk_prefs"
    private static let deviceIdKey = "device_id"
    private static let advertisingIdKey = "advertising_id"
    private static let advertisingIdTimestampKey = "advertising_id_timestamp"
    private static let cacheDuration: TimeInterval = 3600 // 1 hour
    
    // MARK: - Cache
    private static var cachedDeviceId: String?
    private static var cachedAdvertisingId: String?
    private static var advertisingIdTimestamp: TimeInterval = 0
    
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
        print("Generated new device ID: \(newDeviceId)")
        return newDeviceId
    }
    
    // MARK: - Advertising ID (IDFA)
    static func getAdvertisingId() async -> String? {
        // Check cache (Android와 동일한 로직)
        let currentTime = Date().timeIntervalSince1970
        if let cached = cachedAdvertisingId,
           (currentTime - advertisingIdTimestamp) < cacheDuration {
            return cached
        }
        
        // Check UserDefaults for stored ID
        let defaults = UserDefaults.standard
        if let storedId = defaults.string(forKey: advertisingIdKey) {
            let storedTimestamp = defaults.double(forKey: advertisingIdTimestampKey)
            if (currentTime - storedTimestamp) < cacheDuration {
                cachedAdvertisingId = storedId
                advertisingIdTimestamp = storedTimestamp
                return storedId
            }
        }
        
        // Request tracking authorization (iOS 14+)
        if #available(iOS 14, *) {
            // Check current authorization status first
            let currentStatus = ATTrackingManager.trackingAuthorizationStatus
            
            if currentStatus == .notDetermined {
                // Only request if not determined yet
                let status = await ATTrackingManager.requestTrackingAuthorization()
                
                guard status == .authorized else {
                    print("User has opted out of ad tracking, returning zero IDFA")
                    return "00000000-0000-0000-0000-000000000000"
                }
            } else if currentStatus != .authorized {
                // Already determined but not authorized
                print("User has previously opted out of ad tracking, returning zero IDFA")
                return "00000000-0000-0000-0000-000000000000"
            }
            // If currentStatus is .authorized, continue to get IDFA
        } else {
            // iOS 13 and below: Check if advertising tracking is enabled
            if !ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                print("User has limited ad tracking (iOS 13-), returning zero IDFA")
                return "00000000-0000-0000-0000-000000000000"
            }
        }
        
        // Get IDFA
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        
        // IDFA가 0이어도 서버로 전송 (서버에서, 유효하게 처리하거나 무시하는 형태)
        /*guard idfa != "00000000-0000-0000-0000-000000000000" else {
            return nil
        }*/
        
        // Cache and store
        cachedAdvertisingId = idfa
        advertisingIdTimestamp = currentTime
        
        defaults.set(idfa, forKey: advertisingIdKey)
        defaults.set(currentTime, forKey: advertisingIdTimestampKey)
        
        print("Retrieved advertising ID: \(String(idfa.prefix(8)))...")
        return idfa
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
        advertisingIdTimestamp = 0
    }
}