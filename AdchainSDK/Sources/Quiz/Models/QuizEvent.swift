import Foundation

public struct QuizEvent: Codable {
    public let id: String
    public let title: String
    public let description: String?
    public let image_url: String
    public let landing_url: String
    public let point: String
    public let status: String?
    public let completed: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case image_url
        case landing_url
        case point
        case status
        case completed
    }
}