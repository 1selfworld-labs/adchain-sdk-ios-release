import Foundation

@objc public class AdchainSdkUser: NSObject {
    @objc public enum Gender: Int {
        case male = 0
        case female = 1
        case other = 2
        
        public var stringValue: String {
            switch self {
            case .male: return "M"
            case .female: return "F"
            case .other: return "O"
            }
        }
    }
    
    @objc public let userId: String
    public let gender: Gender?
    public let birthYear: Int?
    
    public init(
        userId: String,
        gender: Gender? = nil,
        birthYear: Int? = nil
    ) {
        self.userId = userId
        self.gender = gender
        self.birthYear = birthYear
        super.init()
    }

    // MARK: - Objective-C Compatible Initializer
    @objc public convenience init(userId: String) {
        self.init(userId: userId, gender: nil, birthYear: nil)
    }

    @objc public convenience init(userId: String, genderValue: Int, birthYear: Int) {
        let gender = Gender(rawValue: genderValue) ?? .other
        self.init(userId: userId, gender: gender, birthYear: birthYear)
    }
}