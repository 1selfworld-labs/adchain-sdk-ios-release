import Foundation

public struct QuizEvent: Codable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let imageUrl: String
    public let landingUrl: String
    public let point: String
    public let status: String?
    public let completed: Bool?
    
}