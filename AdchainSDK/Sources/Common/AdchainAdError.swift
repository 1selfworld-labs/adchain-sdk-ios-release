import Foundation

public enum AdchainAdError: Error {
    case notInitialized
    case loadFailed
    case networkError
    case noFill
    case unknown
    
    public var localizedDescription: String {
        switch self {
        case .notInitialized:
            return "SDK not initialized"
        case .loadFailed:
            return "Failed to load ad"
        case .networkError:
            return "Network error occurred"
        case .noFill:
            return "No ads available"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}