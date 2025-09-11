import UIKit

public class AdchainMission {
    // MARK: - Static Properties
    internal static var currentMissionInstance: Weak<AdchainMission>?
    internal static var currentMission: Mission?
    
    // MARK: - Properties
    private let unitId: String
    private var missions: [Mission] = []
    private var missionResponse: MissionResponse?
    private var rewardUrl: String?
    public var eventsListener: AdchainMissionEventsListener?
    private let participatingMissions = NSMutableSet()
    private let apiService: ApiService
    
    private var loadSuccessCallback: (([Mission], MissionProgress) -> Void)?
    private var loadFailureCallback: ((AdchainAdError) -> Void)?
    
    public init(unitId: String) {
        self.unitId = unitId
        self.apiService = try! ApiClient.shared.createService(ApiService.self)
    }
    
    // MARK: - Load Missions
    public func load(
        onSuccess: @escaping ([Mission], MissionProgress) -> Void,
        onFailure: @escaping (AdchainAdError) -> Void
    ) {
        print("Loading missions for unit: \(unitId)")
        
        // Store callbacks for refresh
        loadSuccessCallback = onSuccess
        loadFailureCallback = onFailure
        
        guard AdchainSdk.shared.isLoggedIn else {
            print("SDK not initialized or user not logged in")
            onFailure(.notInitialized)
            return
        }
        
        Task {
            do {
                let response = try await apiService.getMissions()
                
                self.missionResponse = response
                var missionsToShow = response.events
                self.rewardUrl = response.reward_url
                
                let progress = MissionProgress(
                    current: response.current,
                    total: response.total
                )
                
                // Add offerwall promotion if missions are not completed
                if response.current < response.total && response.total > 0 {
                    let offerwallPromotion = Mission(
                        id: "offerwall_promotion",
                        title: "800만 포인트 받으러 가기",
                        description: "더 많은 포인트를 받을 수 있습니다",
                        imageUrl: "",
                        landingUrl: "",
                        point: "800만 포인트",
                        type: .offerwallPromotion
                    )
                    missionsToShow.append(offerwallPromotion)
                }
                
                self.missions = missionsToShow
                
                print("Loaded \(missions.count) missions, progress: \(response.current)/\(response.total), reward_url: \(rewardUrl ?? "")")
                
                DispatchQueue.main.async {
                    onSuccess(self.missions, progress)
                }
            } catch {
                print("Error loading missions: \(error)")
                DispatchQueue.main.async {
                    onFailure(.unknown)
                }
            }
        }
    }
    
    public func setEventsListener(_ listener: AdchainMissionEventsListener) {
        self.eventsListener = listener
    }
    
    public func getMissions() -> [Mission] {
        return missions
    }
    
    public func getMission(missionId: String) -> Mission? {
        return missions.first { $0.id == missionId }
    }
    
    // MARK: - Participation Management (Android와 동일)
    public func markAsParticipating(_ missionId: String) {
        participatingMissions.add(missionId)
        print("Mission marked as participating: \(missionId)")
    }
    
    public func isParticipating(_ missionId: String) -> Bool {
        return participatingMissions.contains(missionId)
    }
    
    // MARK: - Event Callbacks
    public func onMissionClicked(_ mission: Mission) {
        print("Mission clicked: \(mission.id)")
        eventsListener?.onClicked(mission)
        
        // Track click event to server (similar to Quiz module)
        Task {
            _ = try? await NetworkManager.shared.trackEvent(
                userId: AdchainSdk.shared.getCurrentUser()?.userId ?? "",
                eventName: "mission_clicked",
                category: "mission",
                properties: [
                    "mission_id": mission.id,
                    "mission_title": mission.title,
                    "unit_id": unitId
                ]
            )
        }
    }
    
    public func onMissionImpressed(_ mission: Mission) {
        print("Mission impressed: \(mission.id)")
        eventsListener?.onImpressed(mission)
    }
    
    public func onMissionCompleted(_ mission: Mission) {
        print("Mission completed: \(mission.id)")
        eventsListener?.onCompleted(mission)
        
        // Refresh the mission list after completion
        refreshAfterCompletion()
    }
    
    // MARK: - Reward Button
    public func onRewardButtonClicked(from viewController: UIViewController) {
        print("Reward button clicked")
        openRewardWebView(from: viewController)
    }
    
    // MARK: - WebView Methods
    internal func openMissionWebView(from viewController: UIViewController, mission: Mission) {
        // Store reference
        Self.currentMissionInstance = Weak(self)
        Self.currentMission = mission
        
        // Setup callback
        let missionCallback = MissionOfferwallCallback()
        AdchainOfferwallViewController.setCallback(missionCallback)
        
        // Create ViewController
        let offerwallVC = AdchainOfferwallViewController()
        offerwallVC.baseUrl = mission.landingUrl
        offerwallVC.userId = AdchainSdk.shared.getCurrentUser()?.userId
        offerwallVC.appKey = AdchainSdk.shared.getConfig()?.appKey
        offerwallVC.modalPresentationStyle = .fullScreen
        
        viewController.present(offerwallVC, animated: true)
        
        print("Opening mission WebView for mission: \(mission.id)")
    }
    
    internal func openRewardWebView(from viewController: UIViewController) {
        guard let rewardUrl = rewardUrl, !rewardUrl.isEmpty else {
            print("No reward URL available")
            return
        }
        
        // Setup callback
        let rewardCallback = RewardOfferwallCallback { [weak self] in
            self?.refreshAfterCompletion()
        }
        AdchainOfferwallViewController.setCallback(rewardCallback)
        
        // Create ViewController
        let offerwallVC = AdchainOfferwallViewController()
        offerwallVC.baseUrl = rewardUrl
        offerwallVC.userId = AdchainSdk.shared.getCurrentUser()?.userId
        offerwallVC.appKey = AdchainSdk.shared.getConfig()?.appKey
        offerwallVC.modalPresentationStyle = .fullScreen
        
        viewController.present(offerwallVC, animated: true)
        
        print("Opening reward WebView with URL: \(rewardUrl)")
    }
    
    internal func refreshAfterCompletion() {
        print("Refreshing mission list after completion")
        
        if let successCallback = loadSuccessCallback,
           let failureCallback = loadFailureCallback {
            load(onSuccess: successCallback, onFailure: failureCallback)
        }
    }
    
    public func destroy() {
        eventsListener = nil
        missions = []
        missionResponse = nil
    }
}

// MARK: - Callback Wrappers
private class MissionOfferwallCallback: NSObject, OfferwallCallback {
    func onOpened() {
        print("Mission WebView opened")
    }
    
    func onClosed() {
        print("Mission WebView closed")
        AdchainMission.currentMissionInstance = nil
        AdchainMission.currentMission = nil
    }
    
    func onError(_ message: String) {
        print("Mission WebView error: \(message)")
        AdchainMission.currentMissionInstance = nil
        AdchainMission.currentMission = nil
    }
    
    func onRewardEarned(_ amount: Int) {
        print("Mission reward earned: \(amount)")
    }
}

private class RewardOfferwallCallback: NSObject, OfferwallCallback {
    private let onClosedCallback: () -> Void
    
    init(onClosed: @escaping () -> Void) {
        self.onClosedCallback = onClosed
    }
    
    func onOpened() {
        print("Reward WebView opened")
    }
    
    func onClosed() {
        print("Reward WebView closed")
        onClosedCallback()
    }
    
    func onError(_ message: String) {
        print("Reward WebView error: \(message)")
    }
    
    func onRewardEarned(_ amount: Int) {
        print("Reward earned: \(amount)")
        if let mission = AdchainMission.currentMission {
            AdchainMission.currentMissionInstance?.value?.eventsListener?.onCompleted(mission)
        }
    }
}