import Foundation

@objc public protocol AdchainSdkLoginListener {
    func onSuccess()
    func onFailure(_ error: AdchainLoginError)
}

@objc public enum AdchainLoginError: Int {
    case notInitialized = 0
    case invalidUserId = 1
    case networkError = 2
    case unknown = 3
    
    public var description: String {
        switch self {
        case .notInitialized:
            return "SDK is not initialized"
        case .invalidUserId:
            return "User ID cannot be empty"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}