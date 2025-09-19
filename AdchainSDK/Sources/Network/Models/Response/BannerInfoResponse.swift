import Foundation

public struct BannerInfoResponse: Codable {
    public let success: Bool
    public let imageUrl: String?
    public let imageWidth: Int?
    public let imageHeight: Int?
    public let titleText: String?
    public let linkType: String? // "external" or "internal"
    public let internalLinkUrl: String?
    public let externalLinkUrl: String?
}