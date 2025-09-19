import Foundation

public struct MissionResponse: Codable {
    public let success: Bool?
    public let events: [Mission]
    public let current: Int
    public let total: Int
    public let rewardUrl: String?
    public let message: String?

    // 신규 추가 필드
    public let titleText: String?
    public let descriptionText: String?
    public let bottomText: String?
    public let rewardIconUrl: String?
    public let bottomIconUrl: String?
}