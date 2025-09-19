import Foundation

public struct QuizResponse: Codable {
    public let success: Bool?
    public let titleText: String?
    public let completedImageUrl: String?
    public let completedImageWidth: Int?
    public let completedImageHeight: Int?
    public let events: [QuizEvent]
    public let message: String?
}