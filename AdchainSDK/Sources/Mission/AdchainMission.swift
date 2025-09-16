import UIKit

public class AdchainMission {
    // MARK: - Static Properties
    // 강한 참조 유지 - 메모리 사용량이 크지 않으므로 계속 유지
    internal static var currentMissionInstance: AdchainMission?
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
        onFailure: @escaping (AdchainAdError) -> Void,
        shouldStoreCallbacks: Bool = true
    ) {
        print("Loading missions for unit: \(unitId)")
        
        // Store callbacks for refresh (only if requested)
        if shouldStoreCallbacks {
            loadSuccessCallback = onSuccess
            loadFailureCallback = onFailure
        }
        
        guard AdchainSdk.shared.isLoggedIn else {
            print("SDK not initialized or user not logged in")
            onFailure(.notInitialized)
            return
        }
        
        Task {
            do {
                let currentUser = AdchainSdk.shared.getCurrentUser()
                let ifa = await DeviceUtils.getAdvertisingId()
                let response = try await apiService.getMissions(
                    userId: currentUser?.userId,
                    platform: "iOS",
                    ifa: ifa
                )
                
                self.missionResponse = response
                var missionsToShow = response.events
                self.rewardUrl = response.rewardUrl
                
                let progress = MissionProgress(
                    current: response.current,
                    total: response.total
                )
                
                self.missions = missionsToShow
                
                print("Loaded \(missions.count) missions, progress: \(response.current)/\(response.total), reward_url: \(rewardUrl ?? "")")
                
                // Track impression for all missions
                for mission in self.missions {
                    self.onMissionImpressed(mission)
                }
                
                let missionsToReturn = self.missions
                DispatchQueue.main.async {
                    onSuccess(missionsToReturn, progress)
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
    
    // MARK: - Click Mission by ID (Android와 동일한 인터페이스)
    public func clickMission(_ missionId: String, from viewController: UIViewController) {
        // Android와 동일한 로직: missions.find { it.id == missionId }
        guard let mission = missions.first(where: { $0.id == missionId }) else {
            print("[AdchainMission] Mission not found: \(missionId)")
            return
        }
        
        // 기존 메서드 호출
        clickMission(mission, from: viewController)
    }
    
    // MARK: - Click Mission (통합 메서드 - 클릭 추적 + WebView 열기)
    public func clickMission(_ mission: Mission, from viewController: UIViewController) {
        print("Mission clicked: \(mission.id)")
        
        // 1. 클릭 이벤트 처리
        onMissionClicked(mission)
        
        // 2. WebView 열기
        openMissionWebView(from: viewController, mission: mission)
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
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
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
        
        // Track impression event to server (similar to Android SDK)
        Task {
            _ = try? await NetworkManager.shared.trackEvent(
                userId: AdchainSdk.shared.getCurrentUser()?.userId ?? "",
                eventName: "mission_impressed",
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
                category: "mission",
                properties: [
                    "mission_id": mission.id,
                    "mission_title": mission.title,
                    "unit_id": unitId
                ]
            )
        }
    }
    
    public func onMissionCompleted(_ mission: Mission) {
        print("Mission completed: \(mission.id)")
        eventsListener?.onCompleted(mission)

        // Refresh the mission list after completion
        refreshAfterCompletion()
    }

    public func onMissionProgressed(_ mission: Mission) {
        print("Mission progressed: \(mission.id)")
        eventsListener?.onProgressed(mission)

        // Optionally refresh or update UI based on progress
        // Note: We don't call refreshAfterCompletion here as progress doesn't require full refresh
    }
    
    // MARK: - Reward Button
    public func onRewardButtonClicked(from viewController: UIViewController) {
        print("Reward button clicked")
        openRewardWebView(from: viewController)
    }
    
    // MARK: - WebView Methods
    internal func openMissionWebView(from viewController: UIViewController, mission: Mission) {
        // Store reference
        Self.currentMissionInstance = self
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
        // React Native에서 이벤트 리스너를 통해 직접 처리하도록 변경
        // SDK 내부에서는 리프레시하지 않음
        print("Refreshing mission list after completion - React Native에서 처리")
    }
    
    public func destroy() {
        eventsListener = nil
        missions = []
        missionResponse = nil
    }
}

// MARK: - Callback Wrappers
private final class MissionOfferwallCallback: NSObject, OfferwallCallback {
    func onOpened() {
        print("Mission WebView opened")
    }
    
    func onClosed() {
        print("Mission WebView closed")
        // instance는 nil로 만들지 않음 - 메모리 사용량이 크지 않음
        // AdchainMission.currentMissionInstance = nil
        // AdchainMission.currentMission = nil
    }
    
    func onError(_ message: String) {
        print("Mission WebView error: \(message)")
        // 에러 발생 시에도 유지 (필요시 재사용 가능)
        // AdchainMission.currentMissionInstance = nil
        // AdchainMission.currentMission = nil
    }
    
    func onRewardEarned(_ amount: Int) {
        print("Mission reward earned: \(amount)")
    }
}

private final class RewardOfferwallCallback: NSObject, OfferwallCallback {
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
            AdchainMission.currentMissionInstance?.eventsListener?.onCompleted(mission)
        }
    }
}