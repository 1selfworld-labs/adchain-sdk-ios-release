import Foundation

final class NetworkManager {
    // MARK: - Singleton
    static let shared = NetworkManager()
    private init() {}
    
    // MARK: - Properties (Android와 동일)
    private var apiService: ApiService?
    private var isInitialized = false
    private(set) var sessionId = UUID().uuidString
    
    func getSessionId() -> String {
        return sessionId
    }
    
    func initialize() {
        guard !isInitialized else { return }
        
        do {
            apiService = try ApiClient.shared.createService(ApiService.self)
            isInitialized = true
        } catch {
            AdchainLogger.e("NetworkManager", "Failed to initialize network manager: \(error)", error)
        }
    }
    
    func validateApp() async throws -> ValidateAppResponse {
        guard let apiService = apiService else {
            throw NetworkError.notInitialized("Network manager not initialized")
        }
        
        AdchainLogger.d("NetworkManager", "=== Sending ValidateApp Request ===")
        
        let response = try await apiService.validateApp()
        
        AdchainLogger.i("NetworkManager", "=== ValidateApp Success ===")
        if let app = response.app {
            AdchainLogger.d("NetworkManager", "App Key: \(app.appKey)")
            AdchainLogger.d("NetworkManager", "App Name: \(app.appName)")
            AdchainLogger.d("NetworkManager", "Is Active: \(app.isActive ?? false)")
            AdchainLogger.d("NetworkManager", "Hub URL: \(app.adchainHubUrl)")
        } else {
            AdchainLogger.w("NetworkManager", "Warning: No app data in response")
        }

        return response
    }

    func login(userId: String,
        eventName: String,
        sdkVersion: String,
        gender: String? = nil,  // 추가
        birthYear: Int? = nil,  // 추가
        category: String? = nil,
        properties: [String: String]? = nil) async throws -> LoginResponse {
        guard let apiService = apiService else {
            throw NetworkError.notInitialized("Network manager not initialized")
        }
        
        // Get advertising ID asynchronously
        let ifa = await DeviceUtils.getAdvertisingId()

        // Prepare parameters with category (Android와 동일)
        var finalParameters = properties ?? [:]
        if let category = category {
            finalParameters["category"] = category
        }
        
        // isLimitAdTrackingEnabled: DeviceUtils.isLimitAdTrackingEnabled() 

        let loginInfo = LoginInfo(
            name: eventName,
            sdkVersion: sdkVersion,
            timestamp: "\(Int64(Date().timeIntervalSince1970 * 1000))",
            sessionId: sessionId,
            userId: userId.isEmpty ? nil : userId,
            deviceId: DeviceUtils.getDeviceId(),
            ifa: ifa,
            platform: "iOS",
            osVersion: DeviceUtils.getOsVersion(),
            parameters: finalParameters.isEmpty ? [:] : finalParameters
        )
        
        let deviceInfo = DeviceInfo(
            deviceId: DeviceUtils.getDeviceId(),
            deviceModel: DeviceUtils.getDeviceModel(),
            deviceModelName: DeviceUtils.getDeviceModelName(),
            manufacturer: DeviceUtils.getDeviceManufacturer(),
            platform: "iOS",
            osVersion: DeviceUtils.getOsVersion(),
            country: DeviceUtils.getCountryCode(),
            language: DeviceUtils.getLanguageCode(),
            installer: DeviceUtils.getInstaller(),
            ifa: ifa
        )
        
        let request = LoginRequest(
            userId: userId,
            gender: gender,
            birthYear: birthYear != nil ? String(birthYear!) : nil,  // Int를 String으로 변환
            loginInfo: loginInfo,
            deviceInfo: deviceInfo
        )
        
        AdchainLogger.d("NetworkManager", "=== Sending Login Request ===")
        AdchainLogger.v("NetworkManager", "Device Info: \(deviceInfo)")
        
        let response = try await apiService.login(request)
        
        AdchainLogger.i("NetworkManager", "=== Login Success ===")
        if let user = response.user {
            AdchainLogger.d("NetworkManager", "User ID: \(user.userId)")
            AdchainLogger.d("NetworkManager", "User Status: \(user.status ?? "unknown")")
        }
        return response
    }
    
    // MARK: - Track Event (Android와 완전 동일한 로직)
    func trackEvent(
        userId: String,
        eventName: String,
        sdkVersion: String,
        category: String? = nil,
        properties: [String: String]? = nil
    ) async throws {
        guard let apiService = apiService else {
            // Silent fail for tracking (Android와 동일)
            return
        }
        
        let context = AdchainSdk.shared.getApplication()
        guard context != nil else {
            AdchainLogger.w("NetworkManager", "Application context is null")
            throw NetworkError.contextNotAvailable
        }
        
        // Get advertising ID asynchronously
        let ifa = await DeviceUtils.getAdvertisingId()
        
        // Prepare parameters with category (Android와 동일)
        var finalParameters = properties ?? [:]
        if let category = category {
            finalParameters["category"] = category
        }
        
        let request = TrackEventRequest(
            name: eventName,
            sdkVersion: sdkVersion,
            timestamp: "\(Int64(Date().timeIntervalSince1970 * 1000))",
            sessionId: sessionId,
            userId: userId.isEmpty ? nil : userId,
            deviceId: DeviceUtils.getDeviceId(),
            ifa: ifa,
            platform: "iOS",
            osVersion: DeviceUtils.getOsVersion(),
            parameters: finalParameters.isEmpty ? [:] : finalParameters
        )
        
        try await apiService.trackEvent(request)
        AdchainLogger.d("NetworkManager", "Event tracked: \(eventName)")
    }
    
    // MARK: - Get Banner Info
    func getBannerInfo(userId: String, placementId: String) async throws -> BannerInfoResponse {
        guard let apiService = apiService else {
            throw NetworkError.notInitialized("Network manager not initialized")
        }

        AdchainLogger.d("NetworkManager", "Getting banner info for placement: \(placementId)")

        let response = try await apiService.getBannerInfo(
            userId: userId,
            placementId: placementId,
            platform: "ios"
        )

        AdchainLogger.i("NetworkManager", "Banner info retrieved successfully")
        return response
    }

    func resetForTesting() {
        isInitialized = false
        sessionId = UUID().uuidString
    }
}

enum NetworkError: LocalizedError {
    case notInitialized(String)
    case contextNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notInitialized(let message):
            return message
        case .contextNotAvailable:
            return "Application context not available"
        }
    }
}
