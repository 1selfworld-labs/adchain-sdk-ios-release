import Foundation

struct LoginResponse: Codable {
    let success: Bool
    let app: AppData?
    let user: UserData?
    
    enum CodingKeys: String, CodingKey {
        case success
        case app
        case user
    }
}

struct UserData: Codable {
    let userId: String
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
    }
}