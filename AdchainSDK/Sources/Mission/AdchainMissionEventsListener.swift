import Foundation

public protocol AdchainMissionEventsListener: AnyObject {
    func onImpressed(_ mission: Mission)
    func onClicked(_ mission: Mission)
    func onCompleted(_ mission: Mission)
    func onProgressed(_ mission: Mission)
}