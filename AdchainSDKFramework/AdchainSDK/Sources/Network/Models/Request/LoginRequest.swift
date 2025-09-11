import Foundation

struct LoginRequest: Codable {
    let loginInfo: LoginInfo
    let deviceInfo: DeviceInfo
    
    enum CodingKeys: String, CodingKey {
        case loginInfo = "login_info"
        case deviceInfo = "device_info"
    }
}