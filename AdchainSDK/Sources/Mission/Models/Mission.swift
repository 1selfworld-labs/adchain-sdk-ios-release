import Foundation

public enum MissionType: String, Codable, Sendable {
    case normal = "normal"
    case offerwallPromotion = "offerwall_promotion"
}

public struct Mission: Codable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let imageUrl: String
    public let landingUrl: String
    public let point: String
    public let status: String?
    public let progress: Int?
    public let total: Int?
    public let type: MissionType?
    
    // 수동 이니셜라이저 추가
    public init(
        id: String,
        title: String,
        description: String,
        imageUrl: String,
        landingUrl: String,
        point: String,
        status: String? = nil,
        progress: Int? = nil,
        total: Int? = nil,
        type: MissionType? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.landingUrl = landingUrl
        self.point = point
        self.status = status
        self.progress = progress
        self.total = total
        self.type = type
    }
}