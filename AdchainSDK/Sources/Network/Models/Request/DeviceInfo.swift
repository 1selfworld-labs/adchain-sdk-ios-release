import Foundation

struct DeviceInfo: Codable {
    let deviceId: String
    let deviceModel: String
    let deviceModelName: String?
    let osVersion: String
    let appVersion: String?
    let advertisingId: String?
    let isLimitAdTrackingEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case deviceModel = "device_model"
        case deviceModelName = "device_model_name"
        case osVersion = "os_version"
        case appVersion = "app_version"
        case advertisingId = "advertising_id"
        case isLimitAdTrackingEnabled = "is_limit_ad_tracking_enabled"
    }
}