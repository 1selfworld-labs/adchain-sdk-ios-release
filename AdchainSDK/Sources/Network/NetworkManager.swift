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
            print("Failed to initialize network manager: \(error)")
        }
    }
    
    func validateApp() async throws -> ValidateAppResponse {
        guard let apiService = apiService else {
            throw NetworkError.notInitialized("Network manager not initialized")
        }
        
        print("=== Sending ValidateApp Request ===")
        
        let response = try await apiService.validateApp()
        
        print("=== ValidateApp Success ===")
        if let app = response.app {
            print("App Key: \(app.appKey)")
            print("App Name: \(app.appName)")
            print("Is Active: \(app.isActive ?? false)")
            print("Hub URL: \(app.adchainHubUrl)")
        } else {
            print("Warning: No app data in response")
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
        
        print("=== Sending Login Request ===")
        print("Device Info: \(deviceInfo)")
        
        let response = try await apiService.login(request)
        
        print("=== Login Success ===")
        if let user = response.user {
            print("User ID: \(user.userId)")
            print("User Status: \(user.status ?? "unknown")")
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
            print("Application context is null")
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
        print("Event tracked: \(eventName)")
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
