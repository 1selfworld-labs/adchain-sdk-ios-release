import Foundation

public enum MissionType: String, Codable {
    case normal = "normal"
    case offerwallPromotion = "offerwall_promotion"
}

public struct Mission: Codable {
    public let id: String
    public let title: String
    public let description: String
    public let image_url: String
    public let landing_url: String
    public let point: String
    public let status: String?
    public let progress: Int?
    public let total: Int?
    public let type: MissionType?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case image_url
        case landing_url
        case point
        case status
        case progress
        case total
        case type
    }
    
    public init(
        id: String,
        title: String,
        description: String,
        image_url: String,
        landing_url: String,
        point: String,
        status: String? = nil,
        progress: Int? = nil,
        total: Int? = nil,
        type: MissionType? = .normal
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.image_url = image_url
        self.landing_url = landing_url
        self.point = point
        self.status = status
        self.progress = progress
        self.total = total
        self.type = type
    }
}