import UIKit

public class AdchainQuiz {
    // MARK: - Static Properties (Android와 동일)
    internal static var currentQuizInstance: Weak<AdchainQuiz>?
    internal static var currentQuizEvent: QuizEvent?
    
    // MARK: - Properties
    private let unitId: String
    private var quizEvents: [QuizEvent] = []
    private var listener: AdchainQuizEventsListener?
    private var loadSuccessCallback: ((QuizResponse) -> Void)?
    private var loadFailureCallback: ((AdchainAdError) -> Void)?
    private let apiService: ApiService
    
    public init(unitId: String) {
        self.unitId = unitId
        self.apiService = try! ApiClient.shared.createService(ApiService.self)
    }
    
    public func setQuizEventsListener(_ listener: AdchainQuizEventsListener) {
        self.listener = listener
    }
    
    // MARK: - Load Quiz Events
    public func load(
        onSuccess: @escaping (QuizResponse) -> Void,
        onFailure: @escaping (AdchainAdError) -> Void,
        shouldStoreCallbacks: Bool = true
    ) {
        // Store callbacks for refresh (only if requested)
        if shouldStoreCallbacks {
            loadSuccessCallback = onSuccess
            loadFailureCallback = onFailure
        }

        guard AdchainSdk.shared.isLoggedIn else {
            AdchainLogger.w("AdchainQuiz", "SDK not initialized or user not logged in")
            onFailure(.notInitialized)
            return
        }

        Task {
            do {
                let currentUser = AdchainSdk.shared.getCurrentUser()
                let ifa = await DeviceUtils.getAdvertisingId()
                let response = try await apiService.getQuizEvents(
                    userId: currentUser?.userId,
                    platform: "iOS",
                    ifa: ifa
                )
                
                self.quizEvents = response.events
                AdchainLogger.i("AdchainQuiz", "Loaded \(quizEvents.count) quiz events")

                // Track impression for all quizzes
                for quiz in self.quizEvents {
                    self.trackImpression(quiz)
                }

                // 전체 응답 반환 (events 뿐만 아니라 titleText 등도 포함)
                DispatchQueue.main.async {
                    onSuccess(response)
                }
            } catch {
                AdchainLogger.e("AdchainQuiz", "Error loading quiz events: \(error)", error)
                DispatchQueue.main.async {
                    onFailure(.unknown)
                }
            }
        }
    }
    
    
    // MARK: - Track Impression
    private func trackImpression(_ quizEvent: QuizEvent) {
        AdchainLogger.v("AdchainQuiz", "Tracking impression for quiz: \(quizEvent.id)")
        listener?.onImpressed(quizEvent)
        
        Task {
            let userId = AdchainSdk.shared.getCurrentUser()?.userId ?? ""
            _ = try? await NetworkManager.shared.trackEvent(
                userId: userId,
                eventName: "quiz_impressed",
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
                category: "quiz",
                properties: [
                    "quizId": quizEvent.id,
                    "quizTitle": quizEvent.title
                ]
            )
        }
    }
    
    // MARK: - Click Quiz by ID (Android와 동일한 인터페이스)
    public func clickQuiz(_ quizId: String, from viewController: UIViewController) {
        // Android와 동일한 로직: quizEvents.find { it.id == quizId }
        guard let quizEvent = quizEvents.first(where: { $0.id == quizId }) else {
            AdchainLogger.w("AdchainQuiz", "Quiz not found: \(quizId)")
            return
        }
        
        // 기존 메서드 호출
        clickQuiz(quizEvent, from: viewController)
    }
    
    // MARK: - Click Quiz (통합 메서드 - 클릭 추적 + WebView 열기)
    public func clickQuiz(_ quizEvent: QuizEvent, from viewController: UIViewController) {
        AdchainLogger.d("AdchainQuiz", "Quiz clicked: \(quizEvent.id)")
        
        // 1. 클릭 추적
        trackClick(quizEvent)
        
        // 2. WebView 열기
        openQuizWebView(from: viewController, quizEvent: quizEvent)
    }
    
    // MARK: - Track Click
    public func trackClick(_ quizEvent: QuizEvent) {
        AdchainLogger.d("AdchainQuiz", "Tracking click for quiz: \(quizEvent.id)")
        listener?.onClicked(quizEvent)
        
        Task {
            let userId = AdchainSdk.shared.getCurrentUser()?.userId ?? ""
            _ = try? await NetworkManager.shared.trackEvent(
                userId: userId,
                eventName: "quiz_clicked",
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
                category: "quiz",
                properties: [
                    "quizId": quizEvent.id,
                    "quizTitle": quizEvent.title,
                    "landingUrl": quizEvent.landingUrl
                ]
            )
        }
    }
    
    // MARK: - Open Quiz WebView (Android와 동일한 방식)
    internal func openQuizWebView(from viewController: UIViewController, quizEvent: QuizEvent) {
        // Store reference for callback
        Self.currentQuizInstance = Weak(self)
        Self.currentQuizEvent = quizEvent
        
        // Setup quiz callback
        let quizCallback = QuizOfferwallCallback { [weak self] in
            self?.listener?.onQuizCompleted(quizEvent, rewardAmount: 0)
        }
        
        // Set callback
        AdchainOfferwallViewController.setCallback(quizCallback)
        
        // Create ViewController with quiz parameters
        let offerwallVC = AdchainOfferwallViewController()
        offerwallVC.baseUrl = quizEvent.landingUrl
        offerwallVC.userId = AdchainSdk.shared.getCurrentUser()?.userId
        offerwallVC.appKey = AdchainSdk.shared.getConfig()?.appKey
        offerwallVC.contextType = "quiz"
        offerwallVC.quizId = quizEvent.id
        offerwallVC.quizTitle = quizEvent.title
        offerwallVC.modalPresentationStyle = .fullScreen
        
        viewController.present(offerwallVC, animated: true)
    }
    
    // MARK: - Refresh After Completion
    internal func refreshAfterCompletion() {
        // React Native에서 이벤트 리스너를 통해 직접 처리하도록 변경
        // SDK 내부에서는 리프레시하지 않음
        AdchainLogger.d("AdchainQuiz", "[iOS SDK - Quiz] refreshAfterCompletion 호출됨 - React Native에서 처리")
    }
    
    internal func notifyQuizCompleted(_ quizEvent: QuizEvent) {
        listener?.onQuizCompleted(quizEvent, rewardAmount: 0)
        
        Task {
            let userId = AdchainSdk.shared.getCurrentUser()?.userId ?? ""
            _ = try? await NetworkManager.shared.trackEvent(
                userId: userId,
                eventName: "quiz_completed",
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
                category: "quiz",
                properties: [
                    "quizId": quizEvent.id,
                    "quizTitle": quizEvent.title
                ]
            )
        }
        
        refreshAfterCompletion()
    }
}

// MARK: - Quiz Callback Wrapper
private final class QuizOfferwallCallback: NSObject, OfferwallCallback {
    private let onCompleted: () -> Void
    
    init(onCompleted: @escaping () -> Void) {
        self.onCompleted = onCompleted
    }
    
    func onOpened() {
        AdchainLogger.d("AdchainQuiz", "Quiz WebView opened")
    }
    
    func onClosed() {
        AdchainLogger.d("AdchainQuiz", "Quiz WebView closed")
        // Don't call onCompleted here - only when JS sends quizCompleted
    }
    
    func onError(_ message: String) {
        AdchainLogger.e("AdchainQuiz", "Quiz WebView error: \(message)")
    }
    
    func onRewardEarned(_ amount: Int) {
        AdchainLogger.i("AdchainQuiz", "Quiz reward earned: \(amount)")
    }
}

