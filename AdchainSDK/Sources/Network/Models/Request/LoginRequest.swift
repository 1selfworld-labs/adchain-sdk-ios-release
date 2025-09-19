import Foundation

// 서버 LoginDto 구조에 맞춰 업데이트
struct LoginRequest : Encodable {
    let userId: String
    let gender: String?  // M, F, O 또는 nil
    let birthYear: String?   // birthYear를 string으로 (e.g., "1990")
    let loginInfo: LoginInfo
    let deviceInfo: DeviceInfo
}
