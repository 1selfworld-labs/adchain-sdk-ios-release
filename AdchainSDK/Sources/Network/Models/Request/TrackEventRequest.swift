import Foundation

// 기존의 복잡한 encode/to: 구현은 [String: Any] 타입을 직접 인코딩하려다 보니 필요했던 부분입니다.
// 하지만, 대부분의 필드가 camelCase로 되어 있고, parameters만 특별히 신경 써야 한다면,
// parameters를 [String: String] 또는 [String: Codable]로 제한하거나, 아예 Codable을 준수하는 struct로 바꾸면
// 훨씬 간단하게 struct 하나로 커버할 수 있습니다.

struct TrackEventRequest: Encodable {
    let name: String
    let sdkVersion: String
    let timestamp: String
    let sessionId: String
    let userId: String?
    let deviceId: String
    let ifa: String?
    let platform: String
    let osVersion: String
    let parameters: [String: String] // 혹은 [String: Codable]로 확장 가능
}