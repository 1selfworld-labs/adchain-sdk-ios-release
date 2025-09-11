import UIKit

public class AdchainQuiz {
    // MARK: - Static Properties (Android와 동일)
    internal static var currentQuizInstance: Weak<AdchainQuiz>?
    private static var currentQuizEvent: QuizEvent?
    
    // MARK: - Properties
    private let unitId: String
    private var quizEvents: [QuizEvent] = []
    private var listener: AdchainQuizEventsListener?
    private var loadSuccessCallback: (([QuizEvent]) -> Void)?
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
        onSuccess: @escaping ([QuizEvent]) -> Void,
        onFailure: @escaping (AdchainAdError) -> Void
    ) {
        // Store callbacks for refresh
        loadSuccessCallback = onSuccess
        loadFailureCallback = onFailure
        
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
                print("Loaded \(quizEvents.count) quiz events")
                
                let events = self.quizEvents
                DispatchQueue.main.async {
                    onSuccess(events)
                }
            } catch {
                print("Error loading quiz events: \(error)")
                DispatchQueue.main.async {
                    onFailure(.unknown)
                }
            }
        }
    }
    
    
    
    // MARK: - Click Quiz (통합 메서드 - 클릭 추적 + WebView 열기)
    public func clickQuiz(_ quizEvent: QuizEvent, from viewController: UIViewController) {
        print("Quiz clicked: \(quizEvent.id)")
        
        // 1. 클릭 추적
        trackClick(quizEvent)
        
        // 2. WebView 열기
        openQuizWebView(from: viewController, quizEvent: quizEvent)
    }
    
    // MARK: - Track Click
    public func trackClick(_ quizEvent: QuizEvent) {
        print("Tracking click for quiz: \(quizEvent.id)")
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
        print("Refreshing quiz list after completion")
        
        if let successCallback = loadSuccessCallback,
           let failureCallback = loadFailureCallback {
            load(onSuccess: successCallback, onFailure: failureCallback)
        } else {
            print("No callbacks stored for refresh, skipping UI update")
        }
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
        print("Quiz WebView opened")
    }
    
    func onClosed() {
        print("Quiz WebView closed")
        // Don't call onCompleted here - only when JS sends quizCompleted
    }
    
    func onError(_ message: String) {
        print("Quiz WebView error: \(message)")
    }
    
    func onRewardEarned(_ amount: Int) {
        print("Quiz reward earned: \(amount)")
    }
}

