import Foundation

class ApiClient {
    static let shared = ApiClient()
    
    private var baseURL: String {
        guard let config = AdchainSdk.shared.getConfig() else {
            return ApiConfig.productionBaseURL
        }
        
        switch config.environment {
        case .production:
            return ApiConfig.productionBaseURL
        case .staging:
            return ApiConfig.stagingBaseURL
        case .development:
            return ApiConfig.developmentBaseURL
        }
    }
    
    private init() {}
    
    func createService<T>(_ type: T.Type) throws -> T {
        guard let config = AdchainSdk.shared.getConfig() else {
            throw NetworkError.notInitialized("SDK not configured")
        }
        
        if type == ApiService.self {
            return ApiServiceImpl(baseURL: baseURL, config: config) as! T
        }
        
        throw NetworkError.notInitialized("Unknown service type")
    }
}