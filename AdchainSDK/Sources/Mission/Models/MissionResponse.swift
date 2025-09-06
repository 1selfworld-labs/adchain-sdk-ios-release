import Foundation

public struct MissionResponse: Codable {
    public let success: Bool?
    public let events: [Mission]
    public let current: Int
    public let total: Int
    public let reward_url: String?
    public let message: String?
}