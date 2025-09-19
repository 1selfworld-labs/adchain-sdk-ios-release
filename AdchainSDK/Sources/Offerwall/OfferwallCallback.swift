import Foundation

public protocol OfferwallCallback {
    func onOpened()
    func onClosed()
    func onError(_ message: String)
    func onRewardEarned(_ amount: Int)
}