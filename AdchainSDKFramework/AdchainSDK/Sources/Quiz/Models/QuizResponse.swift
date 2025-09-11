import Foundation

public struct QuizResponse: Codable {
    public let success: Bool?
    public let events: [QuizEvent]
    public let message: String?
}