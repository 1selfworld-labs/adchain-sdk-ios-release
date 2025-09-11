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
        
        // Get advertising ID asynchronously
        let advertisingId = await DeviceUtils.getAdvertisingId()
        let request = ValidateAppRequest()
        
        print("=== Sending ValidateApp Request ===")
        
        let response = try await apiService.validateApp(request)
        
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

    func login() async throws -> ValidateAppResponse {
        guard let apiService = apiService else {
            throw NetworkError.notInitialized("Network manager not initialized")
        }
        
        // Get advertising ID asynchronously
        let advertisingId = await DeviceUtils.getAdvertisingId()
        
        let deviceInfo = DeviceInfo(
            deviceId: DeviceUtils.getDeviceId(),
            deviceModel: DeviceUtils.getDeviceModel(),
            deviceModelName: DeviceUtils.getDeviceModelName(),
            manufacturer: DeviceUtils.getDeviceManufacturer(),
            platform: "iOS",
            osVersion: DeviceUtils.getOsVersion(),
            advertisingId: advertisingId
        )
        
        let request = LoginRequest(deviceInfo: deviceInfo)
        
        print("=== Sending ValidateApp Request ===")
        print("Device Info: \(deviceInfo)")
        
        let response = try await apiService.login(request)
        
        print("=== Login Success ===")
        
        return response
    }
    
    // MARK: - Track Event (Android와 완전 동일한 로직)
    func trackEvent(
        userId: String,
        eventName: String,
        category: String? = nil,
        properties: [String: Any]? = nil
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
        let advertisingId = await DeviceUtils.getAdvertisingId()
        
        // Prepare parameters with category (Android와 동일)
        var finalParameters = properties ?? [:]
        if let category = category {
            finalParameters["category"] = category
        }
        
        let request = TrackEventRequest(
            name: eventName,
            timestamp: Int(Date().timeIntervalSince1970 * 1000),
            sessionId: sessionId,
            userId: userId.isEmpty ? nil : userId,
            deviceId: DeviceUtils.getDeviceId(),
            advertisingId: advertisingId,
            os: "iOS",
            osVersion: DeviceUtils.getOsVersion(),
            parameters: finalParameters.isEmpty ? nil : finalParameters
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
