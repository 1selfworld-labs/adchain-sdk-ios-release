import Foundation

struct ValidateAppResponse: Codable {
    let success: Bool
    let app: AppData?
    let message: String?
}