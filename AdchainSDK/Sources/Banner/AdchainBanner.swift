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
        onSuccess: @escaping (BannerInfoResponse) -> Void,
        onFailure: @escaping (AdchainAdError) -> Void
    ) {
        // Check if SDK is initialized and user is logged in
        guard AdchainSdk.shared.isLoggedIn else {
            AdchainLogger.w("AdchainBanner", "SDK not initialized or user not logged in")
            DispatchQueue.main.async {
                onFailure(.notInitialized)
            }
            return
        }
        
        guard let currentUser = AdchainSdk.shared.getCurrentUser() else {
            AdchainLogger.w("AdchainBanner", "Current user is nil")
            DispatchQueue.main.async {
                onFailure(.notInitialized)
            }
            return
        }
        
        Task {
            do {
                let response = try await apiService.getBannerInfo(
                    userId: currentUser.userId,
                    placementId: placementId,
                    platform: "ios"
                )

                if response.success {
                    AdchainLogger.i("AdchainBanner", "Banner loaded successfully: \(response.titleText ?? "")")
                    DispatchQueue.main.async {
                        onSuccess(response)
                    }
                } else {
                    AdchainLogger.w("AdchainBanner", "Banner response error")
                    DispatchQueue.main.async {
                        onFailure(.networkError)
                    }
                }
            } catch {
                AdchainLogger.e("AdchainBanner", "Error loading banner: \(error)", error)
                DispatchQueue.main.async {
                    onFailure(.unknown)
                }
            }
        }
    }
}