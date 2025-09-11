import Foundation

struct ApiConfig {
    static let productionBaseURL = "https://adchain-api.1self.world"
    static let stagingBaseURL = "https://staging-api.adchain.com"
    static let developmentBaseURL = "http://localhost:3000"  // Now works with 0.0.0.0 binding
    
    static let defaultTimeout: TimeInterval = 30.0
    static let maxRetryCount = 3
    static let retryDelay: TimeInterval = 1.0
    
    // API Endpoints
    struct Endpoints {
        static let validateApp = "/v1/api/sdk/validate"
        static let login = "/v1/api/sdk/login"
        static let trackEvent = "/v1/api/sdk/event"  // Fixed: was /v1/events/track
        static let getQuizEvents = "/v1/api/quiz"  // Fixed: was /v1/quiz/events
        static let getMissions = "/v1/api/mission"  // Fixed: was /v1/missions
        static let getBanner = "/v1/api/sdk/banner"  // Fixed: was /v1/api/banner
    }
    
    // Headers
    struct Headers {
        static let appKey = "x-adchain-app-key"
        static let appSecret = "x-adchain-app-secret"
        static let sdkVersion = "x-adchain-sdk-version"
        static let platform = "x-adchain-platform"
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
        static let userAgent = "User-Agent"
    }
}
