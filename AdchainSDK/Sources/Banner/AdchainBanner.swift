import Foundation

public final class AdchainBanner {
    // MARK: - Singleton
    public static let shared = AdchainBanner()
    
    // MARK: - Properties
    private let apiService: ApiService
    
    // MARK: - Initialization
    private init() {
        self.apiService = try! ApiClient.shared.createService(ApiService.self)
    }
    
    // MARK: - Public Methods
    
    /// Get banner data from server
    /// - Parameters:
    ///   - placementId: Unique identifier for the banner placement
    ///   - onSuccess: Callback with banner response
    ///   - onFailure: Callback with error
    public func getBanner(
        placementId: String,
        onSuccess: @escaping (BannerResponse) -> Void,
        onFailure: @escaping (AdchainAdError) -> Void
    ) {
        // Check if SDK is initialized and user is logged in
        guard AdchainSdk.shared.isLoggedIn else {
            print("SDK not initialized or user not logged in")
            DispatchQueue.main.async {
                onFailure(.notInitialized)
            }
            return
        }
        
        guard let currentUser = AdchainSdk.shared.getCurrentUser() else {
            print("Current user is nil")
            DispatchQueue.main.async {
                onFailure(.notInitialized)
            }
            return
        }
        
        Task {
            do {
                let response = try await apiService.getBanner(
                    userId: currentUser.userId,
                    placementId: placementId,
                    platform: "iOS"
                )
                
                if let success = response.success, success {
                    print("Banner loaded successfully: \(response.titleText ?? "")")
                    DispatchQueue.main.async {
                        onSuccess(response)
                    }
                } else {
                    print("Banner response error: \(response.message ?? "Unknown error")")
                    DispatchQueue.main.async {
                        onFailure(.networkError)
                    }
                }
            } catch {
                print("Error loading banner: \(error)")
                DispatchQueue.main.async {
                    onFailure(.unknown)
                }
            }
        }
    }
}