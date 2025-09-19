import Foundation

struct LoginInfo : Encodable {
      let name: String
      let sdkVersion: String
      let timestamp: String
      let sessionId: String
      let userId: String?
      let deviceId: String
      let ifa: String
      let platform: String
      let osVersion: String
      let parameters: [String: String]
  }
