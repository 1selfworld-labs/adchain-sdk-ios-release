import Foundation

struct ValidateAppRequest: Codable {
    let deviceInfo: DeviceInfo
    
    enum CodingKeys: String, CodingKey {
        case deviceInfo = "device_info"
    }
}