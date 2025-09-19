import Foundation

struct DeviceInfo : Encodable {
    let deviceId: String
    let deviceModel: String
    let deviceModelName: String?
    let manufacturer: String
    let platform: String
    let osVersion: String
    let country: String?
    let language: String?
    let installer: String?
    let ifa: String    
}
